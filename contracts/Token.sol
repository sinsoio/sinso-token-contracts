// contracts/Token.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title Token
 */
contract Token is ERC20, ERC20Burnable {
    constructor(address account, uint256 amount) ERC20("Sinso Token", "SINSO") {
        _mint(account, amount);
    }
}
