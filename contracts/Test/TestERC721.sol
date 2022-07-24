// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestERC721 is ERC721 {
    uint256 tokenId;

    constructor() ERC721("GameItem", "ITM") {
        mint(5);
    }

    function mint(uint256 amount) internal {
        uint256 id = tokenId;
        uint256 i;
        for (; i < amount; ) {
            _mint(msg.sender, id+i);
            unchecked {
                ++i;
            }
        }
        id += amount;
        tokenId = id;
    }
}
