//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract RWA_CoinsMock is ERC20, Ownable {
    error RWA_Coins__NotZeroAddress();
    error RWA_Coins__InsufficientBalance();
    
    constructor() ERC20("RWA_Coins", "RWAC") Ownable(msg.sender) {}
    
    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert RWA_Coins__NotZeroAddress();
        }
        _mint(_to, _amount);
        return true;
    }
    
    function burn(uint256 _amount) external onlyOwner {
        if (balanceOf(address(this)) < _amount) {
            revert RWA_Coins__InsufficientBalance();
        }
        _burn(address(this), _amount);
    }
    
    // For testing purposes
    function mintTo(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}
