import { ethers } from 'ethers';
import { readFileSync } from 'fs';
import dotenv from 'dotenv';

dotenv.config();

const RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/wtwRDsMyNnq_hpPJLrFR4";
const PRIVATE_KEY = process.env.PRIVATE_KEY;

// Contract addresses
const OLD_RWA_MANAGER = "0x6C39352AE22A6e015aA5c2E166B98135b593f6c7";
const NEW_RWA_MANAGER = "0xc949605cF609adCe31493888e4CCC0a8D1b52b0A";
const RWA_COINS = "0xD3834ee45eE0D76B828Ff02B11eFc19f259B67Eb";
const RWA_NFT = "0x8a6C86c56EE1F2a71E7cE4371F380BfF0ac496ed";

const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

async function setupNewManager() {
    try {
        console.log("=== Setting Up New RWA_Manager ===");
        console.log("Old RWA_Manager:", OLD_RWA_MANAGER);
        console.log("New RWA_Manager:", NEW_RWA_MANAGER);
        console.log("User wallet:", wallet.address);
        
        // Load ABIs
        const managerAbi = JSON.parse(readFileSync('./out/RWA_Manager.sol/RWA_Manager.json', 'utf8')).abi;
        const coinsAbi = JSON.parse(readFileSync('./out/RWA_Coins.sol/RWA_Coins.json', 'utf8')).abi;
        const nftAbi = JSON.parse(readFileSync('./out/RWA_NFT.sol/RWA_NFT.json', 'utf8')).abi;
        
        const oldManagerContract = new ethers.Contract(OLD_RWA_MANAGER, managerAbi, wallet);
        const newManagerContract = new ethers.Contract(NEW_RWA_MANAGER, managerAbi, wallet);
        const coinsContract = new ethers.Contract(RWA_COINS, coinsAbi, wallet);
        const nftContract = new ethers.Contract(RWA_NFT, nftAbi, wallet);
        
        console.log("\n1. Checking current ownership...");
        const coinsOwner = await coinsContract.owner();
        const nftOwner = await nftContract.owner();
        const oldManagerOwner = await oldManagerContract.owner();
        const newManagerOwner = await newManagerContract.owner();
        
        console.log("Coins owner:", coinsOwner);
        console.log("NFT owner:", nftOwner);
        console.log("Old manager owner:", oldManagerOwner);
        console.log("New manager owner:", newManagerOwner);
        
        // Check if our wallet owns the old manager
        if (oldManagerOwner.toLowerCase() === wallet.address.toLowerCase()) {
            console.log("\n2. We own the old manager, transferring ownership of coins and NFTs...");
            
            // The old manager should transfer ownership of the dependent contracts to the new manager
            // But since the old manager is owned by user wallet, we need to do it manually
            
            // First revoke minter role from old manager
            console.log("2a. Revoking MINTER_ROLE from old manager...");
            try {
                const MINTER_ROLE = await coinsContract.MINTER_ROLE();
                const revokeTx = await coinsContract.revokeRole(MINTER_ROLE, OLD_RWA_MANAGER);
                await revokeTx.wait();
                console.log("✅ MINTER_ROLE revoked from old manager");
            } catch (error) {
                console.log("❌ Error revoking minter role:", error.message);
            }
            
            // Grant minter role to new manager
            console.log("2b. Granting MINTER_ROLE to new manager...");
            try {
                const MINTER_ROLE = await coinsContract.MINTER_ROLE();
                const grantTx = await coinsContract.grantRole(MINTER_ROLE, NEW_RWA_MANAGER);
                await grantTx.wait();
                console.log("✅ MINTER_ROLE granted to new manager");
            } catch (error) {
                console.log("❌ Error granting minter role:", error.message);
            }
            
            // Transfer ownership
            console.log("2c. Transferring coins ownership...");
            try {
                const transferCoinsTx = await coinsContract.transferOwnership(NEW_RWA_MANAGER);
                await transferCoinsTx.wait();
                console.log("✅ Coins ownership transferred");
            } catch (error) {
                console.log("❌ Error transferring coins ownership:", error.message);
            }
            
            console.log("2d. Transferring NFT ownership...");
            try {
                const transferNftTx = await nftContract.transferOwnership(NEW_RWA_MANAGER);
                await transferNftTx.wait();
                console.log("✅ NFT ownership transferred");
            } catch (error) {
                console.log("❌ Error transferring NFT ownership:", error.message);
            }
            
        } else {
            console.log("❌ We don't own the old manager. Owner is:", oldManagerOwner);
        }
        
        console.log("\n3. Setting up new manager...");
        
        // Set backend signer on new manager
        console.log("3a. Setting backend signer...");
        try {
            const setSignerTx = await newManagerContract.setBackendSigner(wallet.address);
            await setSignerTx.wait();
            console.log("✅ Backend signer set");
        } catch (error) {
            console.log("❌ Error setting backend signer:", error.message);
        }
        
        console.log("\n=== Final Verification ===");
        const finalCoinsOwner = await coinsContract.owner();
        const finalNftOwner = await nftContract.owner();
        const MINTER_ROLE = await coinsContract.MINTER_ROLE();
        const newManagerHasMinterRole = await coinsContract.hasRole(MINTER_ROLE, NEW_RWA_MANAGER);
        const backendSigner = await newManagerContract.backendSigner();
        
        console.log("Final coins owner:", finalCoinsOwner);
        console.log("Final NFT owner:", finalNftOwner);
        console.log("New manager has MINTER_ROLE:", newManagerHasMinterRole);
        console.log("Backend signer:", backendSigner);
        
        console.log("\n✅ Setup complete! New RWA_Manager ready at:", NEW_RWA_MANAGER);
        
    } catch (error) {
        console.error("Setup failed:", error.message);
    }
}

setupNewManager();
