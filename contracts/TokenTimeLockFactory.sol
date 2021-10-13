// contracts/TokenTimeLockFactory.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TokenTimeLock.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Factory contract for TokenTimelock
 * @notice This contract deploys TokenTimelock contracts
 */
contract TokenTimeLockFactory is Context {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
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
    // invalid contracts
    mapping(address => bool) private _invalidContracts;
    // ERC20 basic token contract
    IERC20 private immutable _token;
    // contract checker
    address private _checker;
    // owner
    address private immutable _owner;
    // master
    address private immutable _master;

    constructor(IERC20 token_, address checker_) {
        require(checker_ != address(0), "checker not empty");
        _token = token_;
        _checker = checker_;
        _owner = _msgSender();
        TokenTimeLock _tokenTimeLock = new TokenTimeLock();
        _tokenTimeLock.init(
            token_,
            _msgSender(),
            _msgSender(),
            10000,
            100,
            10,
            60,
            false,
            false
        );
        _master = address(_tokenTimeLock);
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
     * @return the contract invalid status
     */
    function invalid(address contractAddress_)
        public
        view
        virtual
        returns (bool)
    {
        return _invalidContracts[contractAddress_];
    }

    /**
     * @return the contract check status
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
     * @dev Returns the address of the current master.
     */
    function master() public view virtual returns (address) {
        return _master;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
        address _contractAddress = Clones.clone(master());
        TokenTimeLock(_contractAddress).init(
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
        _deployedContracts[_contractAddress] = beneficiary_;
        _deployedContractList.push(_contractAddress);
        emit TokenTimeLockDeployed(_contractAddress);
        return _contractAddress;
    }

    /**
     * @dev Throws if called by any account other than the checker.
     */
    modifier onlyChecker() {
        require(checker() == _msgSender(), "only checker auth handle");
        _;
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
    ) public virtual onlyChecker {
        require(beneficiary(contract_) != address(0), "contract is not exist");
        require(!checked(contract_), "contract already checked");
        require(!invalid(contract_), "contract already invalid");
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
        tokenTimeLock.check();
        token().safeTransfer(contract_, amount_);
        emit CheckContract(contract_);
    }

    /**
     * @notice check contract
     */
    function invalidContract(address contract_) public virtual onlyChecker {
        require(beneficiary(contract_) != address(0), "contract is not exist");
        require(!checked(contract_), "contract already checked");
        require(!invalid(contract_), "contract already invalid");
        _invalidContracts[contract_] = true;
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
        require(checked(contract_), "contract is not check");
        TokenTimeLock(contract_).setStart(start_);
    }

    /**
     * @notice batch set start
     */
    function batchSetStart(address[] memory contracts_, uint256 start_)
        public
        virtual
        onlyOwner
    {
        require(contracts_.length > 0, "contracts is not empty");
        require(start_ > block.timestamp, "start must > current time");
        require(
            start_ < block.timestamp + 7776000,
            "contracts must < current time add 7776000s"
        );
        for (uint256 i = 0; i < contracts_.length; i++) {
            setStart(contracts_[i], start_);
        }
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
