// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {RWA_Manager} from "../src/CoinMintingAndManaging/RWA_Manager.sol";

contract DeployRWAManager is Script {
    function run() external returns (RWA_Manager) {
        vm.startBroadcast();
        
        // Constructor arguments
        address rwaVerifiedAssets = 0x21763032B2170d995c866E249fc85Da49E02aF4c;
        address rwaNFT = 0x8a6C86c56EE1F2a71E7cE4371F380BfF0ac496ed;
        address rwaCoins = 0xD3834ee45eE0D76B828Ff02B11eFc19f259B67Eb;
        
        RWA_Manager rwaManager = new RWA_Manager(
            rwaVerifiedAssets,
            rwaNFT,
            rwaCoins
        );
        
        vm.stopBroadcast();
        return rwaManager;
    }
}
