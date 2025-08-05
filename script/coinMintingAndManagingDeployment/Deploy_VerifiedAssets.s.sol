//SPDX License-Identifier: MIT
pragma solidity ^0.8.20;
import {Script, console} from "forge-std/Script.sol";
import {RWA_VerifiedAssets} from "../../src/CoinMintingAndManaging/RWA_VerifiedAssets.sol";
contract DeployVerifiedAssets is Script{
    RWA_VerifiedAssets public va;
    function run()external returns (RWA_VerifiedAssets) {
        address deployerKey = address(uint160(vm.envUint("PRIVATE_KEY")));
        // address deployerKey = vm.envUint("PRIVATE_KEY"); // from .env
        vm.startBroadcast(deployerKey);
        RWA_VerifiedAssets va = new RWA_VerifiedAssets(deployerKey);
        vm.stopBroadcast();
        console.log("VerifiedAssets deployed at:", address(va));
        return va;
    }
}