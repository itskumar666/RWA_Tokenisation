import { ethers } from 'ethers';
import { readFileSync } from 'fs';
import dotenv from 'dotenv';

dotenv.config();

const RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/wtwRDsMyNnq_hpPJLrFR4";
const PRIVATE_KEY = process.env.PRIVATE_KEY;

// New contract address
const NEW_RWA_MANAGER = "0xc949605cF609adCe31493888e4CCC0a8D1b52b0A";
const RWA_COINS = "0xD3834ee45eE0D76B828Ff02B11eFc19f259B67Eb";
const RWA_NFT = "0x8a6C86c56EE1F2a71E7cE4371F380BfF0ac496ed";

const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

const rwaManagerAbi = JSON.parse(readFileSync('./out/RWA_Manager.sol/RWA_Manager.json', 'utf8')).abi;
const rwaCoinsAbi = JSON.parse(readFileSync('./out/RWA_Coins.sol/RWA_Coins.json', 'utf8')).abi;
const rwaNftAbi = JSON.parse(readFileSync('./out/RWA_NFT.sol/RWA_NFT.json', 'utf8')).abi;

async function testNewManager() {
    try {
        console.log("=== Testing New RWA_Manager ===");
        console.log("User wallet:", wallet.address);
        console.log("New RWA_Manager:", NEW_RWA_MANAGER);
        
        const managerContract = new ethers.Contract(NEW_RWA_MANAGER, rwaManagerAbi, wallet);
        const coinsContract = new ethers.Contract(RWA_COINS, rwaCoinsAbi, wallet);
        const nftContract = new ethers.Contract(RWA_NFT, rwaNftAbi, wallet);
        
        // Use Asset ID 2 which we know exists and belongs to our wallet
        const requestId = 2;
        const assetValue = 56; // Value in USD as shown in the asset data
        const assetOwner = wallet.address;
        const tokenURI = "https://example.com/metadata/2.json";
        
        console.log("\n1. Checking balances before minting...");
        const coinsBefore = await coinsContract.balanceOf(assetOwner);
        const nftBalance = await nftContract.balanceOf(assetOwner);
        console.log("Coins balance before:", ethers.formatEther(coinsBefore));
        console.log("NFT balance before:", nftBalance.toString());
        
        console.log("\n2. Testing direct mint functions to verify configuration...");
        
        // Test if the new manager can mint NFTs
        console.log("2a. Testing NFT mint from new manager...");
        try {
            // Create a contract instance with the manager as the signer
            // We can't actually sign as the manager contract, but we can simulate
            const gasEstimate = await nftContract.mint.estimateGas(
                wallet.address,
                "test",
                0,
                "test",
                100,
                { from: NEW_RWA_MANAGER }
            );
            console.log("✅ NFT mint would work (gas estimate:", gasEstimate.toString(), ")");
        } catch (error) {
            console.log("❌ NFT mint would fail:", error.message);
        }
        
        console.log("\n3. Attempting full minting flow...");
        try {
            const tx = await managerContract.depositRWAAndMintNFT(
                requestId,
                assetValue,
                assetOwner,
                tokenURI,
                {
                    gasLimit: 500000 // Set a reasonable gas limit
                }
            );
            console.log("Transaction hash:", tx.hash);
            console.log("Waiting for confirmation...");
            
            const receipt = await tx.wait();
            console.log("✅ Transaction confirmed! Block:", receipt.blockNumber);
            
            // Check balances after
            const coinsAfter = await coinsContract.balanceOf(assetOwner);
            const nftAfter = await nftContract.balanceOf(assetOwner);
            console.log("\n4. Balances after minting:");
            console.log("Coins balance after:", ethers.formatEther(coinsAfter));
            console.log("NFT balance after:", nftAfter.toString());
            console.log("Coins minted:", ethers.formatEther(coinsAfter - coinsBefore));
            console.log("NFTs minted:", (nftAfter - nftBalance).toString());
            
            console.log("\n🎉 SUCCESS! Minting works with the new RWA_Manager!");
            
        } catch (error) {
            console.log("❌ Minting failed:", error.message);
            
            if (error.data) {
                try {
                    const decoded = managerContract.interface.parseError(error.data);
                    console.log("Decoded error:", decoded.name, decoded.args);
                } catch (decodeError) {
                    console.log("Raw error data:", error.data);
                    // Check for known errors
                    if (error.data === "0xbc278ded") {
                        console.log("This is RWA_Manager__AssetNotVerified error");
                    } else if (error.data.startsWith("0x118cdaa7")) {
                        console.log("This is OwnableUnauthorizedAccount error");
                    }
                }
            }
        }
        
    } catch (error) {
        console.error("Error:", error.message);
    }
}

testNewManager();
