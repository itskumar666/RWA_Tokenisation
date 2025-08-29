import { ethers } from 'ethers';
import { readFileSync } from 'fs';
import dotenv from 'dotenv';

dotenv.config();

const RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/wtwRDsMyNnq_hpPJLrFR4";
const PRIVATE_KEY = process.env.PRIVATE_KEY;

const RWA_MANAGER = "0x6C39352AE22A6e015aA5c2E166B98135b593f6c7";
const RWA_COINS = "0xD3834ee45eE0D76B828Ff02B11eFc19f259B67Eb";
const RWA_NFT = "0x8a6C86c56EE1F2a71E7cE4371F380BfF0ac496ed";

const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

const rwaManagerAbi = JSON.parse(readFileSync('./out/RWA_Manager.sol/RWA_Manager.json', 'utf8')).abi;
const rwaCoinsAbi = JSON.parse(readFileSync('./out/RWA_Coins.sol/RWA_Coins.json', 'utf8')).abi;
const rwaNftAbi = JSON.parse(readFileSync('./out/RWA_NFT.sol/RWA_NFT.json', 'utf8')).abi;

async function debugContractAddresses() {
    try {
        console.log("=== Debugging Contract Configuration ===");
        
        const managerContract = new ethers.Contract(RWA_MANAGER, rwaManagerAbi, wallet);
        const coinsContract = new ethers.Contract(RWA_COINS, rwaCoinsAbi, wallet);
        const nftContract = new ethers.Contract(RWA_NFT, rwaNftAbi, wallet);
        
        console.log("Expected addresses:");
        console.log("RWA_Manager:", RWA_MANAGER);
        console.log("RWA_Coins:", RWA_COINS);
        console.log("RWA_NFT:", RWA_NFT);
        
        // The issue might be that the RWA_Manager was deployed with the OLD contract addresses
        // Let's check what addresses the current RWA_Manager is configured to use
        console.log("\n=== Manager Contract Configuration ===");
        
        // We can't directly read the immutable variables, but we can check
        // by looking at the contract's bytecode or by calling functions that use them
        
        // Let's try to call the mint functions directly to see which contracts are being called
        console.log("Testing direct contract calls...");
        
        // Check ownership of the contracts we think the manager should own
        const coinsOwner = await coinsContract.owner();
        const nftOwner = await nftContract.owner();
        
        console.log("Current coins owner:", coinsOwner);
        console.log("Current NFT owner:", nftOwner);
        console.log("Manager is coins owner?", coinsOwner.toLowerCase() === RWA_MANAGER.toLowerCase());
        console.log("Manager is NFT owner?", nftOwner.toLowerCase() === RWA_MANAGER.toLowerCase());
        
        // Check minter role on coins
        const MINTER_ROLE = await coinsContract.MINTER_ROLE();
        const managerHasMinterRole = await coinsContract.hasRole(MINTER_ROLE, RWA_MANAGER);
        console.log("Manager has MINTER_ROLE on coins?", managerHasMinterRole);
        
        // Let's try to directly call the mint functions to see where the error comes from
        console.log("\n=== Testing Direct Mint Calls ===");
        
        console.log("1. Testing direct NFT mint...");
        try {
            const gasEstimate = await nftContract.mint.estimateGas(
                wallet.address,
                "test",
                0,
                "test",
                100
            );
            console.log("✅ NFT mint gas estimate:", gasEstimate.toString());
        } catch (error) {
            console.log("❌ NFT mint failed:", error.message);
            if (error.data) {
                console.log("Error data:", error.data);
            }
        }
        
        console.log("2. Testing direct Coins mint...");
        try {
            const gasEstimate = await coinsContract.mint.estimateGas(
                wallet.address,
                100
            );
            console.log("✅ Coins mint gas estimate:", gasEstimate.toString());
        } catch (error) {
            console.log("❌ Coins mint failed:", error.message);
            if (error.data) {
                console.log("Error data:", error.data);
            }
        }
        
    } catch (error) {
        console.error("Error:", error.message);
    }
}

debugContractAddresses();
