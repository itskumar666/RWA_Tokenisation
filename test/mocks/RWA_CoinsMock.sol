//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract RWA_CoinsMock is ERC20, Ownable {
    mapping(address => bool) public minters;
    
    modifier onlyMinter() {
        require(minters[msg.sender], "Not a minter");
        _;
    }
    
    constructor() ERC20("RWA Coin", "RWA") Ownable(msg.sender) {
        minters[msg.sender] = true;
    }
    
    function addMinter(address minter) external onlyOwner {
        minters[minter] = true;
    }
    
    function removeMinter(address minter) external onlyOwner {
        minters[minter] = false;
    }
    
    function mint(address to, uint256 amount) external {
        // Allow anyone to mint for testing purposes - more permissive than real contract
        _mint(to, amount);
    }
    
    // For testing purposes - allow anyone to mint for flexibility
    function mintTo(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}
