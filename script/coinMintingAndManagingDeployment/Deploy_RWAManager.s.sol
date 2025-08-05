// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {RWA_Manager} from "../../src/CoinMintingAndManaging/RWA_Manager.sol";

contract Deploy_RWAManager is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY"); // from .env
        address rwaVA = vm.envAddress("RWA_VERIFIED_ASSETS_ADDRESS");
        address rwaNFT = vm.envAddress("RWA_NFT_ADDRESS");
        address rwaCoins = vm.envAddress("RWA_COINS_ADDRESS");

        vm.startBroadcast(deployerKey);

        RWA_Manager rwaManager = new RWA_Manager(
            rwaVA,
            rwaNFT,
            rwaCoins
        );

        vm.stopBroadcast();

        console.log("RWA_Manager deployed at:", address(rwaManager));
    }
}
