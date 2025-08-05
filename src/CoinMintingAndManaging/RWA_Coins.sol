//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import {ERC20Burnable, ERC20} from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';

/* 
   Imp:  add Staking Contract as a  minter role
*/

contract RWA_Coins is Ownable, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    error RWT_Coins__NotZeroAmount();
    error RWT_Coins__NotZeroAddress();
    error RWT_Coins__BalanceMustBeGreaterThanBurnAmount();

    constructor() ERC20("RWACoin", "RWAC") Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _;
    }
    function addMinter(address minter) external onlyOwner {
       require(hasRole(MINTER_ROLE, msg.sender), "Already a minter");
        require(minter != address(0), "Invalid minter address");
        _grantRole(MINTER_ROLE, minter);
    }
    function removeMinter(address minter) external onlyOwner {
        require(minter != address(0), "Invalid minter address");
        require(!hasRole(MINTER_ROLE, minter), "Not a minter");
        _revokeRole(MINTER_ROLE, minter);
    }

    function mint(address _to, uint256 _amount) external onlyMinter returns (bool) {
        // Optimized: Single condition check combining multiple validations
        if (_amount == 0 || _to == address(0)) {
            if (_amount == 0) revert RWT_Coins__NotZeroAmount();
            revert RWT_Coins__NotZeroAddress();
        }
        
        _mint(_to, _amount);
        return true;
    }

    function burn(uint256 _amount) public override onlyOwner {
        if (_amount == 0) {
            revert RWT_Coins__NotZeroAmount();
        }
        
        // Optimized: Use balanceOf(address(this)) instead of msg.sender for contract burns
        uint256 balance = balanceOf(address(this));
        if (balance < _amount) {
            revert RWT_Coins__BalanceMustBeGreaterThanBurnAmount();
        }
        
        super.burn(_amount);
    }
}