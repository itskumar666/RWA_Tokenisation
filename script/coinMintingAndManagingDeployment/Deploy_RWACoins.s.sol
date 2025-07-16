//SPDX License-Identifier: MIT
pragma solidity ^0.8.20;
import {Script} from 'forge-std/Script.sol';
import {RWA_Coins} from '../../src/CoinMintingAndManaging/RWA_Coins.sol';

contract DeployRWACoins is Script {
    RWA_Coins public rwaCoins;

    function run() external returns (RWA_Coins) {
        vm.startBroadcast();
        rwaCoins = new RWA_Coins();
        vm.stopBroadcast();
        return rwaCoins;
    }

}