// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {
    uint256 private constant AMOUNT_IN_WEI = 10**18;

    constructor() ERC20("My Token", "MTK") {
        _mint(msg.sender, 1000000 * AMOUNT_IN_WEI);
    }
}
