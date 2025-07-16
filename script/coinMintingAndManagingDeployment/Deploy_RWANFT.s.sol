//SPDX License-Identifier:MIT
pragma solidity ^0.8.20;
import {Script} from 'forge-std/Script.sol';
import {RWA_NFT} from '../../src/CoinMintingAndManaging/RWA_NFT.sol';
contract Deploy_RWANFT is Script{
    RWA_NFT public rwaNFT;
    function run() external returns(RWA_NFT) {
        vm.startBroadcast();
        rwaNFT = new RWA_NFT();
        vm.stopBroadcast();
        return rwaNFT;
    }
}