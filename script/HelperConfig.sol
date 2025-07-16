//SPDX License-identifier: MIT
pragma solidity ^0.8.20;
import {Script} from "forge-std/Script.sol";
import { ERC20Mock } from "../test/mocks/ERC20mock.sol";
import {ERC721Mock} from "../test/mocks/ERC721mock.sol";

// This contract is used to deploy and manage configurations for different networks
// It allows for easy deployment of mock contracts for testing purposes but only anvil config is there right now 

contract HelperConfig is Script{
    struct NetworkConfig {
        address erc20Mock;
        address erc721Mock;
        uint256 deployerKey;
    }
    NetworkConfig public activeNetworkConfig;
    uint256 public constant DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
      constructor() {
        
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        
    }
 function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.erc20Mock != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast(DEFAULT_KEY);
        ERC20Mock erc20Mock = new ERC20Mock("Zenith", "ZNT", msg.sender, 1000000 ether);
        ERC721Mock erc721Mock = new ERC721Mock();
        activeNetworkConfig.erc20Mock = address(erc20Mock);
        activeNetworkConfig.erc721Mock = address(erc721Mock);
        activeNetworkConfig.deployerKey = DEFAULT_KEY;
        vm.stopBroadcast();
        return activeNetworkConfig;
    }
}
