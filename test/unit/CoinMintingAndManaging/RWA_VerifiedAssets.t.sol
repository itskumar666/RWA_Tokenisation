//SPDX License-Identifier: MIT
pragma solidity ^0.8.20;
import { Test, console } from "forge-std/Test.sol";
import {RWA_VerifiedAssets} from "../../../src/CoinMintingAndManaging/RWA_VerifiedAssets.sol";
contract  RWA_VerifiedAssetsTest is Test{

    RWA_VerifiedAssets public rwaVA;

    address testingOwner=address(100);

    function setUp()public{
        rwaVA=new RWA_VerifiedAssets(testingOwner);

    }
    // function test
    

}