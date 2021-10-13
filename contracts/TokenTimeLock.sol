// contracts/TokenTimeLock.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title TokenTimeLock
 */
contract TokenTimeLock is Context {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 private _token;
    // beneficiary of tokens after they are released
    address private _beneficiary;
    // Start time (Unix time), prompt from what time to start timing
    uint256 private _start;
    // Release down payment at start time
    uint256 private _downpayment;
    // Total statges
    uint256 private _stages;
    // Recyclable or not
    bool private _revocable;
    // release downpayment immediately
    bool private _immediately;
    // released downpayment immediately
    bool private _immediatelyed;
    // contract amount
    uint256 private _amount;
    // beneficiary confirm contract
    bool private _confirm;
    // signer
    address private _signer;
    // interval
    uint256 private _interval;
    // released
    uint256 private _released;
    // revoked
    bool private _revoked;
    // revoked
    bool private _checked;
    // owner
    address private _owner;

    event Released(uint256 amount);
    event Revoked(uint256 amount);

    /**
     * init
     */
    function init(
        IERC20 token_,
        address beneficiary_,
        address signer_,
        uint256 amount_,
        uint256 downpayment_,
        uint256 stages_,
        uint256 interval_,
        bool immediately_,
        bool revocable_
    ) public virtual {
        require(owner() == address(0), "contract is init");
        require(beneficiary_ != address(0), "beneficiary must not empty");
        require(signer_ != address(0), "signer must not empty");
        require(amount_ > 0, "amount must > 0");
        require(downpayment_ >= 0, "downpayment_ must >= 0");
        require(amount_ >= downpayment_, "amount must > downpayment");
        require(stages_ > 0, "stages must > 0");
        require(interval_ > 0, "interval must > 0");
        if (immediately_) {
            require(
                downpayment_ > 0,
                "immediately downpayment association error"
            );
        }
        _token = token_;
        _beneficiary = beneficiary_;
        _signer = signer_;
        _amount = amount_;
        _downpayment = downpayment_;
        _stages = stages_;
        _interval = interval_;
        _immediately = immediately_;
        _revocable = revocable_;
        _owner = _msgSender();
    }

    /**
     * @return the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @return Release down payment at start time.
     */
    function downpayment() public view virtual returns (uint256) {
        return _downpayment;
    }

    /**
     * @return Start time (Unix time), prompt from what time to start timing.
     */
    function start() public view virtual returns (uint256) {
        return _start;
    }

    /**
     * @return _stages
     */
    function stages() public view virtual returns (uint256) {
        return _stages;
    }

    /**
     * @return Recyclable or not.
     */
    function revocable() public view virtual returns (bool) {
        return _revocable;
    }

    /**
     * @return _interval
     */
    function interval() public view virtual returns (uint256) {
        return _interval;
    }

    /**
     * @return released
     */
    function released() public view virtual returns (uint256) {
        return _released;
    }

    /**
     * @return revoked
     */
    function revoked() public view virtual returns (bool) {
        return _revoked;
    }

    /**
     * @return amount
     */
    function amount() public view virtual returns (uint256) {
        return _amount;
    }

    /**
     * @return confirm
     */
    function confirm() public view virtual returns (bool) {
        return _confirm;
    }

    /**
     * @return release downpayment immediately
     */
    function immediately() public view virtual returns (bool) {
        return _immediately;
    }

    /**
     * @return release downpayment immediatelyed
     */
    function immediatelyed() public view virtual returns (bool) {
        return _immediatelyed;
    }

    /**
     * @return checked
     */
    function checked() public view virtual returns (bool) {
        return _checked;
    }

    /**
     * @return signer
     */
    function signer() public view virtual returns (address) {
        return _signer;
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
     * @notice set start
     */
    function setStart(uint256 start_) public virtual onlyOwner {
        require(_start == 0, "start is already set");
        require(start_ > block.timestamp, "start must > current time");
        _start = start_;
    }

    /**
     * @notice check contract
     */
    function check() public virtual onlyOwner {
        require(!checked(), "contract is already checked");
        _checked = true;
    }

    /**
     * @return  releasable
     */
    function releasableAmount() public view returns (uint256) {
        if (!checked()) {
            return 0;
        }
        uint256 currentBalance = token().balanceOf(address(this));
        if (immediately() && !immediatelyed()) {
            return downpayment();
        }
        if (start() == 0) {
            return 0;
        }
        if (block.timestamp < start()) {
            return 0;
        } else if (
            block.timestamp >= start().add(stages().mul(interval())) ||
            revoked()
        ) {
            return currentBalance;
        } else {
            uint256 totalBalance = currentBalance.add(released());
            uint256 amountTmp = totalBalance
                .sub(downpayment())
                .mul(block.timestamp.sub(start()).div(interval()))
                .div(stages());
            return amountTmp.add(downpayment()).sub(released());
        }
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     */
    function revoke() public virtual onlyOwner {
        require(revocable(), "not support revoke");
        require(!revoked(), "already revoked");
        uint256 unreleased = releasableAmount();
        require(unreleased == 0, "please release amount before");
        uint256 currentBalance = token().balanceOf(address(this));
        require(currentBalance > 0, "Lock Token: no tokens to revoked");
        token().safeTransfer(owner(), currentBalance);
        _revoked = true;
        emit Revoked(currentBalance);
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        uint256 unreleased = releasableAmount();
        require(unreleased > 0, "Lock Token: no tokens to release");
        _released = released().add(unreleased);
        if (immediately() && !immediatelyed()) {
            _immediatelyed = true;
        }
        token().safeTransfer(beneficiary(), unreleased);
        emit Released(unreleased);
    }

    /**
     * @dev Throws if called by any account other than the signer.
     */
    modifier onlySigner() {
        require(signer() == _msgSender(), "only signer auth handle");
        _;
    }

    /**
     * @notice beneficiary confirm
     */
    function confirmContract(address beneficiary_, uint256 amount_)
        public
        virtual
        onlySigner
    {
        require(beneficiary() == beneficiary_, "beneficiary verify failure");
        require(amount() == amount_, "amount verify failure");
        require(!confirm(), "already confirm");
        _confirm = true;
    }
}
