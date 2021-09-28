// contracts/SinsoTokenTimelock.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SinsoTokenTimelock is Ownable  {
    using SafeMath for  uint256;
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 private immutable _token;
    // beneficiary of tokens after they are released
    address private immutable _beneficiary;
    //The unit is second (s), cliff time
    uint256 private immutable _cliff;
    //Start time (Unix time), prompt from what time to start timing
    uint256 private immutable _start;
    //Unit: second (s), duration of warehouse lock
    uint256 private immutable _duration;
    //interval
    uint256 private immutable _interval;
    //Recyclable or not
    bool private immutable _revocable;
    // released
    uint256 private _released;
    //revoked
    bool private _revoked;

    event Released(uint256 amount);
    event Revoked();

    constructor(
        IERC20 token_,
        address beneficiary_,
        uint256 start_,
        uint256 cliff_,
        uint256 duration_,
        uint256 interval_,
        bool revocable_
    ) {
        require(beneficiary_ != address(0),"beneficiary must not this");
        require(cliff_ <= duration_,"duration time must >= cliff time");
        require(start_ > block.timestamp, "start time must > current time");
        require(interval_ <= duration_, "interval must <= duration");
        _token = token_;
        _beneficiary = beneficiary_;
        _cliff = cliff_;
        _start = start_;
        _duration = duration_;
        _interval = interval_;
        _revocable = revocable_;
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
     * @return The unit is second (s), cliff time.
     */
    function cliff() public view virtual returns (uint256) {
        return _cliff;
    }

     /**
     * @return Start time (Unix time), prompt from what time to start timing.
     */
    function start() public view virtual returns (uint256) {
        return _start;
    }

     /**
     * @return Unit: second (s), duration of warehouse lock.
     */
    function duration() public view virtual returns (uint256) {
        return _duration;
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
    * @return  releasable
    */
    function releasableAmount() public view returns (uint256) {
        uint256 currentBalance = token().balanceOf(address(this));
        if( block.timestamp< start().add(cliff())){
            return 0;
        }else if(block.timestamp >= start().add(duration()) || revoked()){
            return currentBalance;
        }else{
            uint256 totalBalance = currentBalance.add(released());
            return totalBalance.mul(block.timestamp.sub(start()).div(interval()).mul(interval())).div(duration()).sub(released());  
        }
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     */
     function revoke() public onlyOwner{
        require(revocable(),"not support revoke");
        require(!revoked(),"already revoked");
        uint256 currentBalance = token().balanceOf(address(this));
        uint256 unreleased = releasableAmount();
        uint256 refund = currentBalance.sub(unreleased);
        require(refund > 0, "Lock Token: no tokens to revoked");
        token().safeTransfer(owner(), refund);
        _revoked = true;
        emit Revoked();
     }
    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        uint256 unreleased = releasableAmount();
        require(unreleased > 0, "Lock Token: no tokens to release");
        _released = released().add(unreleased);
        token().safeTransfer(beneficiary(), unreleased);
        emit Released(unreleased);
    }
}