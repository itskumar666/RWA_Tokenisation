// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Script, console} from "forge-std/Script.sol";
import {FunctionsRouter} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsRouter.sol";

contract DeployFunctionsRouter is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);
        
        // ✅ Correct declaration and initialization
        uint32[] memory callbackGasLimits = new uint32[](1);
        callbackGasLimits[0] = 5_000_000; // Example test value
        
        FunctionsRouter.Config memory config = FunctionsRouter.Config({
            maxConsumersPerSubscription: 10,
            adminFee: 0,
            handleOracleFulfillmentSelector: bytes4(keccak256("handleOracleFulfillment(bytes32,bytes,bytes)")),
            gasForCallExactCheck: 5000,
            maxCallbackGasLimits: callbackGasLimits,
            subscriptionDepositMinimumRequests: 0,
            subscriptionDepositJuels: 0
        });
        
        // Use address(1) as LINK token mock for Anvil testing
        FunctionsRouter router = new FunctionsRouter(address(1), config);
        vm.stopBroadcast();
        
        console.log("FunctionsRouter deployed at:", address(router));
    }
}