//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract TestERC1155 is ERC1155 {
    constructor() ERC1155(".json") {
        mint(1,5);
        mint(2,5);
        mint(3,5);
        mint(4,5);
    }

    function mint(uint256 id, uint256 amount) internal {
        _mint(msg.sender, id, amount, "");
    }
}
