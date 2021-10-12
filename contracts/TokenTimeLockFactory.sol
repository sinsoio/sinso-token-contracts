// contracts/TokenTimeLockFactory.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TokenTimeLock.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Factory contract for TokenTimelock
 * @notice This contract deploys TokenTimelock contracts
 */
contract TokenTimeLockFactory is Ownable {
    using SafeERC20 for IERC20;
    // event fired on every new tokenTimeLock deployment
    event TokenTimeLockDeployed(address _contractAddress);
    // event check contract
    event CheckContract(address _contractAddress);
    // mapping to keep track of which contracts were deployed by this factory
    mapping(address => address) private _deployedContracts;
    // list to keep track of which contracts were deployed by this factory
    address[] private _deployedContractList;
    // checked contract
    mapping(address => bool) private _checkedContracts;
    // ERC20 basic token contract
    IERC20 private immutable _token;
    // contract checker
    address private _checker;

    constructor(IERC20 token_, address checker_) {
        require(checker_ != address(0), "checker not empty");
        _token = token_;
        _checker = checker_;
    }

    /**
     * @return the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }

    /**
     * @return the beneficiary
     */
    function beneficiary(address contractAddress_)
        public
        view
        virtual
        returns (address)
    {
        return _deployedContracts[contractAddress_];
    }

    /**
     * @return the deployed contract list
     */
    function deployedContractList()
        public
        view
        virtual
        returns (address[] memory)
    {
        return _deployedContractList;
    }

    /**
     * @return the contract
     */
    function checked(address contractAddress_)
        public
        view
        virtual
        returns (bool)
    {
        return _checkedContracts[contractAddress_];
    }

    /**
     * @return the checker
     */
    function checker() public view virtual returns (address) {
        return _checker;
    }

    /**
     * @notice set a new checker
     */
    function changeChecker(address newChecker_) public virtual onlyOwner {
        require(newChecker_ != address(0), "newChecker not empty");
        _checker = newChecker_;
    }

    /**
     * @notice create a tokenTimeLock contract
     */
    function deployTokenTimeLock(
        address beneficiary_,
        address signer_,
        uint256 amount_,
        uint256 downpayment_,
        uint256 stages_,
        uint256 interval_,
        bool immediately_,
        bool revocable_
    ) public virtual onlyOwner returns (address) {
        TokenTimeLock _tokenTimeLock = new TokenTimeLock(
            token(),
            beneficiary_,
            signer_,
            amount_,
            downpayment_,
            stages_,
            interval_,
            immediately_,
            revocable_
        );
        address _contractAddress = address(_tokenTimeLock);
        _deployedContracts[_contractAddress] = beneficiary_;
        _deployedContractList.push(_contractAddress);
        emit TokenTimeLockDeployed(_contractAddress);
        return _contractAddress;
    }

    /**
     * @notice check contract
     */
    function checkContract(
        address contract_,
        address beneficiary_,
        address signer_,
        uint256 amount_,
        uint256 downpayment_,
        uint256 stages_,
        uint256 interval_,
        bool immediately_,
        bool revocable_
    ) public virtual onlyOwner {
        require(beneficiary(contract_) != address(0), "contract is not exist");
        require(!checked(contract_), "contract already checked");
        TokenTimeLock tokenTimeLock = TokenTimeLock(contract_);
        require(tokenTimeLock.token() == token(), "token verify failure");
        require(tokenTimeLock.confirm(), "contract is not confirm");
        require(
            tokenTimeLock.beneficiary() == beneficiary_,
            "beneficiary verify failure"
        );
        require(
            tokenTimeLock.downpayment() == downpayment_,
            "downpayment verify failure"
        );
        require(tokenTimeLock.stages() == stages_, "stages verify failure");
        require(tokenTimeLock.amount() == amount_, "amount verify failure");
        require(
            tokenTimeLock.interval() == interval_,
            "interval verify failure"
        );
        require(
            tokenTimeLock.immediately() == immediately_,
            "immediately verify failure"
        );
        require(
            tokenTimeLock.revocable() == revocable_,
            "revocable verify failure"
        );
        require(tokenTimeLock.signer() == signer_, "signer verify failure");
        uint256 currentBalance = token().balanceOf(address(this));
        require(currentBalance >= amount_, "current balance insufficient");
        _checkedContracts[contract_] = true;
        token().safeTransfer(contract_, amount_);
        emit CheckContract(contract_);
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     */
    function revoke(address contract_) public virtual onlyOwner {
        require(beneficiary(contract_) != address(0), "contract is not exist");
        TokenTimeLock(contract_).revoke();
    }

    /**
     * @notice set start
     */
    function setStart(address contract_, uint256 start_)
        public
        virtual
        onlyOwner
    {
        require(beneficiary(contract_) != address(0), "contract is not exist");
        require(!checked(contract_), "contract already checked");
        TokenTimeLock(contract_).setStart(start_);
    }

    /**
     * @notice withdraw
     */
    function withdraw(IERC20 token_, uint256 amount_) public virtual onlyOwner {
        uint256 currentBalance = token_.balanceOf(address(this));
        require(currentBalance >= amount_, "current balance insufficient");
        token_.safeTransfer(owner(), amount_);
    }
}
