import { ethers } from 'ethers';
import { readFileSync } from 'fs';
import dotenv from 'dotenv';

dotenv.config();

const RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/wtwRDsMyNnq_hpPJLrFR4";
const PRIVATE_KEY = process.env.PRIVATE_KEY;

// Contract addresses
const NEW_RWA_COINS = "0xD3834ee45eE0D76B828Ff02B11eFc19f259B67Eb";
const NEW_RWA_NFT = "0x8a6C86c56EE1F2a71E7cE4371F380BfF0ac496ed";
const NEW_RWA_MANAGER = "0x6C39352AE22A6e015aA5c2E166B98135b593f6c7";

const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

// Read ABIs
const rwaCoinsAbi = JSON.parse(readFileSync('./out/RWA_Coins.sol/RWA_Coins.json', 'utf8')).abi;
const rwaNftAbi = JSON.parse(readFileSync('./out/RWA_NFT.sol/RWA_NFT.json', 'utf8')).abi;

async function fixOwnershipAndPermissions() {
    try {
        console.log("=== Fixing Contract Ownership and Permissions ===");
        console.log("Deployer wallet:", wallet.address);
        console.log("Target RWA_Manager:", NEW_RWA_MANAGER);
        
        const coinsContract = new ethers.Contract(NEW_RWA_COINS, rwaCoinsAbi, wallet);
        const nftContract = new ethers.Contract(NEW_RWA_NFT, rwaNftAbi, wallet);
        
        // 1. Grant MINTER_ROLE to RWA_Manager on RWA_Coins
        console.log("\n1. Granting MINTER_ROLE to RWA_Manager on RWA_Coins...");
        try {
            const MINTER_ROLE = await coinsContract.MINTER_ROLE();
            const tx1 = await coinsContract.grantRole(MINTER_ROLE, NEW_RWA_MANAGER);
            console.log("Transaction hash:", tx1.hash);
            await tx1.wait();
            console.log("✅ MINTER_ROLE granted to RWA_Manager on RWA_Coins");
        } catch (error) {
            console.log("❌ Error granting MINTER_ROLE on coins:", error.message);
        }
        
        // 2. Grant MINTER_ROLE to RWA_Manager on RWA_NFT (if it has this role)
        console.log("\n2. Granting MINTER_ROLE to RWA_Manager on RWA_NFT...");
        try {
            // Check if NFT contract has MINTER_ROLE
            const nftFunctions = nftContract.interface.fragments
                .filter(f => f.type === 'function')
                .map(f => f.name);
            
            if (nftFunctions.includes('grantRole')) {
                const MINTER_ROLE = await nftContract.MINTER_ROLE();
                const tx2 = await nftContract.grantRole(MINTER_ROLE, NEW_RWA_MANAGER);
                console.log("Transaction hash:", tx2.hash);
                await tx2.wait();
                console.log("✅ MINTER_ROLE granted to RWA_Manager on RWA_NFT");
            } else {
                console.log("ℹ️ RWA_NFT doesn't use role-based minting");
            }
        } catch (error) {
            console.log("❌ Error granting MINTER_ROLE on NFT:", error.message);
        }
        
        // 3. Transfer ownership of RWA_Coins to RWA_Manager
        console.log("\n3. Transferring ownership of RWA_Coins to RWA_Manager...");
        try {
            const tx3 = await coinsContract.transferOwnership(NEW_RWA_MANAGER);
            console.log("Transaction hash:", tx3.hash);
            await tx3.wait();
            console.log("✅ RWA_Coins ownership transferred to RWA_Manager");
        } catch (error) {
            console.log("❌ Error transferring coins ownership:", error.message);
        }
        
        // 4. Transfer ownership of RWA_NFT to RWA_Manager
        console.log("\n4. Transferring ownership of RWA_NFT to RWA_Manager...");
        try {
            const tx4 = await nftContract.transferOwnership(NEW_RWA_MANAGER);
            console.log("Transaction hash:", tx4.hash);
            await tx4.wait();
            console.log("✅ RWA_NFT ownership transferred to RWA_Manager");
        } catch (error) {
            console.log("❌ Error transferring NFT ownership:", error.message);
        }
        
        console.log("\n=== Verification ===");
        // Verify the changes
        const newCoinsOwner = await coinsContract.owner();
        const newNftOwner = await nftContract.owner();
        const MINTER_ROLE = await coinsContract.MINTER_ROLE();
        const hasMinterRole = await coinsContract.hasRole(MINTER_ROLE, NEW_RWA_MANAGER);
        
        console.log("RWA_Coins new owner:", newCoinsOwner);
        console.log("RWA_NFT new owner:", newNftOwner);
        console.log("RWA_Manager has MINTER_ROLE on coins:", hasMinterRole);
        console.log("All permissions set correctly:", 
            newCoinsOwner.toLowerCase() === NEW_RWA_MANAGER.toLowerCase() &&
            newNftOwner.toLowerCase() === NEW_RWA_MANAGER.toLowerCase() &&
            hasMinterRole
        );
        
    } catch (error) {
        console.error("Error:", error.message);
    }
}

fixOwnershipAndPermissions();
