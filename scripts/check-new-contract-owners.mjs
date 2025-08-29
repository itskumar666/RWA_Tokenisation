import { ethers } from 'ethers';
import { readFileSync } from 'fs';

const RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/wtwRDsMyNnq_hpPJLrFR4";

// New contract addresses
const NEW_RWA_COINS = "0xD3834ee45eE0D76B828Ff02B11eFc19f259B67Eb";
const NEW_RWA_NFT = "0x8a6C86c56EE1F2a71E7cE4371F380BfF0ac496ed";
const NEW_RWA_MANAGER = "0x6C39352AE22A6e015aA5c2E166B98135b593f6c7";

const provider = new ethers.JsonRpcProvider(RPC_URL);

// Read ABIs
const rwaCoinsAbi = JSON.parse(readFileSync('./out/RWA_Coins.sol/RWA_Coins.json', 'utf8')).abi;
const rwaNftAbi = JSON.parse(readFileSync('./out/RWA_NFT.sol/RWA_NFT.json', 'utf8')).abi;

async function checkOwners() {
    try {
        const coinsContract = new ethers.Contract(NEW_RWA_COINS, rwaCoinsAbi, provider);
        const nftContract = new ethers.Contract(NEW_RWA_NFT, rwaNftAbi, provider);
        
        console.log("=== Contract Ownership Check ===");
        
        // Check RWA_Coins owner
        try {
            const coinsOwner = await coinsContract.owner();
            console.log(`RWA_Coins (${NEW_RWA_COINS}) owner:`, coinsOwner);
            console.log(`Should be RWA_Manager:`, NEW_RWA_MANAGER);
            console.log(`Coins owner matches?`, coinsOwner.toLowerCase() === NEW_RWA_MANAGER.toLowerCase());
        } catch (error) {
            console.log("Error checking coins owner:", error.message);
        }
        
        // Check RWA_NFT owner
        try {
            const nftOwner = await nftContract.owner();
            console.log(`\nRWA_NFT (${NEW_RWA_NFT}) owner:`, nftOwner);
            console.log(`Should be RWA_Manager:`, NEW_RWA_MANAGER);
            console.log(`NFT owner matches?`, nftOwner.toLowerCase() === NEW_RWA_MANAGER.toLowerCase());
        } catch (error) {
            console.log("Error checking NFT owner:", error.message);
        }
        
        // Check if RWA_Manager has minter role on coins
        try {
            const MINTER_ROLE = await coinsContract.MINTER_ROLE();
            const hasMinterRole = await coinsContract.hasRole(MINTER_ROLE, NEW_RWA_MANAGER);
            console.log(`\nRWA_Manager has MINTER_ROLE on coins?`, hasMinterRole);
        } catch (error) {
            console.log("Error checking minter role:", error.message);
        }
        
        // Check if RWA_Manager has minter role on NFT
        try {
            const MINTER_ROLE = await nftContract.MINTER_ROLE();
            const hasMinterRole = await nftContract.hasRole(MINTER_ROLE, NEW_RWA_MANAGER);
            console.log(`RWA_Manager has MINTER_ROLE on NFT?`, hasMinterRole);
        } catch (error) {
            console.log("Error checking NFT minter role:", error.message);
        }
        
    } catch (error) {
        console.error("Error:", error.message);
    }
}

checkOwners();
