//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;
import {ERC20Burnable,ERC20}from '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract RWA_Coins is Ownable,ERC20Burnable{
    
    error RWT_Coins__NotZeroAmount();
    error RWT_Coins__NotZeroAddress();
    error RWT_Coins__BalanceMustBeGreaterThanBurnAmount();

constructor()ERC20("RWACoin","RWAC")Ownable(msg.sender){
}
function mint(address _to,uint256 _amount)external onlyOwner returns (bool){
    if(_amount<=0){
      revert RWT_Coins__NotZeroAmount();
    }
    if(_to<=address(0)){
      revert RWT_Coins__NotZeroAddress();
    }
    _mint(_to, _amount);
    return true;
}
function burn(uint256 _amount) public override  onlyOwner{
  uint256 balance=balanceOf(msg.sender);
  if(balance<_amount){
    revert RWT_Coins__BalanceMustBeGreaterThanBurnAmount();
     
  }
   if(_amount<=0){
      revert RWT_Coins__NotZeroAmount();
    }
    super.burn(_amount);

}
}