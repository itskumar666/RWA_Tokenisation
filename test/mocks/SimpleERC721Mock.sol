// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SimpleERC721Mock is ERC721 {
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}
    
    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
    
    function exists(uint256 tokenId) external view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
}
