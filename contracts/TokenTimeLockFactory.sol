// contracts/TokenTimeLockFactory.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./TokenTimeLock.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Factory contract for TokenTimelock
 * @notice This contract deploys TokenTimelock contracts
 */
contract TokenTimeLockFactory is Ownable {
    using SafeERC20 for IERC20;
    // event fired on every new tokenTimeLock deployment
    event TokenTimeLockDeployed(address contractAddress);

    // mapping to keep track of which contracts were deployed by this factory
    mapping(address => address) private deployedContracts;

    // ERC20 basic token contract
    IERC20 private _token;

    // address of the code contract from which all tokenTimeLock are cloned
    address private _master;

    constructor(IERC20 token_) {
        _token = token_;
        TokenTimeLock tokenTimeLock = new TokenTimeLock();
        _master = address(tokenTimeLock);
    }

    /**
     * @return the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }

    /**
     * @return the token being held.
     */
    function master() public view virtual returns (address) {
        return _master;
    }

    /**
     * @notice creates a clone of the master tokenTimeLock contract
     */
    function deployTokenTimeLock(
        address beneficiary_,
        uint256 start_,
        uint256 cliff_,
        uint256 duration_,
        uint256 interval_,
        bool revocable_
    ) public returns (address) {
        address contractAddress = Clones.cloneDeterministic(
            master(),
            keccak256(abi.encode(msg.sender))
        );
        TokenTimeLock(contractAddress).init(
            token(),
            beneficiary_,
            start_,
            cliff_,
            duration_,
            interval_,
            revocable_
        );
        deployedContracts[contractAddress] = beneficiary_;
        emit TokenTimeLockDeployed(contractAddress);
        return contractAddress;
    }
}
