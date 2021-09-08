// contracts/SinsoToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract SinsoToken is ERC20, ERC20Burnable {
    constructor(address account, uint256 amount) ERC20("SinsoToken", "SINSO") {
        _mint(account, amount);
    }
}
