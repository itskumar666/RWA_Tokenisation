// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {RWA_Verification} from "../../src/CoinMintingAndManaging/RWA_Verification.sol";

contract DeployRWAVerification is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        address router = vm.envAddress("FUNCTIONS_ROUTER_ADDRESS"); // Mock FunctionsRouter deployed on Anvil
        address rwa_Types = vm.envAddress("RWA_TYPES_ADDRESS"); // optional, adjust if used in constructor

        vm.startBroadcast(deployerKey);

        RWA_Verification rwaVerification = new RWA_Verification(
            rwa_Types,
            router
        );

        vm.stopBroadcast();
        console.log("RWA_Verification deployed at:", address(rwaVerification));
    }
}
 