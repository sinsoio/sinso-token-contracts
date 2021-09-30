// contracts/TokenAirdroper.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/**
 * @title TokenAirdroper
 */
contract TokenAirdroper is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // ERC20 basic token contract
    IERC20 private _token;
    // One Airdrop handle Max Airdrop Num
    uint32 private _maxAirdropNum;
    // All Airdrop plan amount
    mapping(address => uint256) private _airdropPlanMap;
    // All Airdrop plan
    address[] private _allAirdropList;
    // effective address start index
    uint32 private _effectiveIndex;
    
    constructor(IERC20 token_,uint32 maxAirdropNum_) {
        require(maxAirdropNum_ > 0,"maxAirdropNum must > 0");
        _token = token_;
        _maxAirdropNum = maxAirdropNum_;
        _effectiveIndex = 0;
    }

    /**
     * @return the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }

    /**
     * @return the Max Airdrop Num
     */
    function maxAirdropNum() public view virtual returns (uint32) {
        return _maxAirdropNum;
    }

    /**
     * @return the sum Airdrop Amount
     */
    function sumAirdropAmount() public view virtual returns (uint256) {
         uint256 sumAmount = 0;
         for(uint256 i = _effectiveIndex; i < _allAirdropList.length; i++){
            sumAmount = sumAmount.add(_airdropPlanMap[_allAirdropList[i]]);
        }
        return sumAmount;
    }

    /**
     * @return the recipient Airdrop Amount
     */
    function recipientAirdropAmount(address recipient_) public view virtual returns (uint256) {
        return _airdropPlanMap[recipient_];
    }

    /**
     * @return check blance status
     */
    function checkBalanceStatus() public view virtual returns (bool) {
        uint256 currentBalance = token().balanceOf(address(this));
        return  currentBalance > 0 && currentBalance >= sumAirdropAmount();
    }

    
    /**
     * add one airdrops plan
     */
    function addPlan(address[] memory recipients_, uint256 amount_) public onlyOwner  {
        require(recipients_.length > 0,"recipients is empty");
        require(amount_ > 0,"amount must > 0");
        for(uint256 i = 0; i < recipients_.length; i++){
            require(_airdropPlanMap[recipients_[i]] == 0,"recipient has plan");
            _allAirdropList.push(recipients_[i]);
            _airdropPlanMap[recipients_[i]] = amount_;
        }
    }

    /**
     * update one planAirdrop amount
     */
    function updatePlan(address recipient_,uint256 amount_) public onlyOwner {
        require(_airdropPlanMap[recipient_] != 0,"recipient  is not in airdrops");
        require(amount_ > 0,"amount must > 0");
        _airdropPlanMap[recipient_] = amount_;
    }

    /**
     * update max airdrop num
     */
    function updateMaxAirdropNum(uint32 maxAirdropNum_) public onlyOwner{
        require(maxAirdropNum_ > 0,"maxAirdropNum must > 0");
        _maxAirdropNum = maxAirdropNum_;
    }

    /**
     * start airdrop
     */    
    function airdrop() public onlyOwner{
        require(_allAirdropList.length > 0,"airdrop plan is empty");
        require(checkBalanceStatus(),"owner balance is insufficient");
        uint32 j = 1;
        for(uint32 i = _effectiveIndex; i < _allAirdropList.length; i++){
            if (j > maxAirdropNum()){
                break;
            }
            // delete plans
            uint256 amount = _airdropPlanMap[_allAirdropList[i]];
            delete _airdropPlanMap[_allAirdropList[i]];
            _token.safeTransfer(_allAirdropList[i], amount);
            j++;
        }
        _effectiveIndex += j-1;
    }

    /**
     * revoke 
     */
    function revoke() public onlyOwner{
        uint256 currentBalance = token().balanceOf(address(this));
        require(currentBalance > 0,"balance is 0");
        token().safeTransfer(owner(), currentBalance);
    }
}