import { ethers } from 'ethers';
import { readFileSync } from 'fs';
import dotenv from 'dotenv';

dotenv.config();

const RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/wtwRDsMyNnq_hpPJLrFR4";
const PRIVATE_KEY = process.env.PRIVATE_KEY;

// Updated contract addresses
const RWA_MANAGER = "0x6C39352AE22A6e015aA5c2E166B98135b593f6c7";
const RWA_VERIFIED_ASSETS = "0x21763032B2170d995c866E249fc85Da49E02aF4c";
const RWA_COINS = "0xD3834ee45eE0D76B828Ff02B11eFc19f259B67Eb";
const RWA_NFT = "0x8a6C86c56EE1F2a71E7cE4371F380BfF0ac496ed";

const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

// Read ABIs
const rwaManagerAbi = JSON.parse(readFileSync('./out/RWA_Manager.sol/RWA_Manager.json', 'utf8')).abi;
const rwaVerifiedAssetsAbi = JSON.parse(readFileSync('./out/RWA_VerifiedAssets.sol/RWA_VerifiedAssets.json', 'utf8')).abi;
const rwaCoinsAbi = JSON.parse(readFileSync('./out/RWA_Coins.sol/RWA_Coins.json', 'utf8')).abi;

async function testMinting() {
    try {
        console.log("=== Testing Complete Minting Flow ===");
        console.log("User wallet:", wallet.address);
        
        const managerContract = new ethers.Contract(RWA_MANAGER, rwaManagerAbi, wallet);
        const verifiedAssetsContract = new ethers.Contract(RWA_VERIFIED_ASSETS, rwaVerifiedAssetsAbi, wallet);
        const coinsContract = new ethers.Contract(RWA_COINS, rwaCoinsAbi, wallet);
        
        // Test parameters (using existing asset ID 13)
        const requestId = 13;
        const assetValue = ethers.parseEther("1000"); // 1000 ETH worth
        const assetOwner = wallet.address;
        const tokenURI = "https://example.com/metadata/13.json";
        
        console.log("\n1. Checking if asset exists in verified assets...");
        try {
            const assetData = await verifiedAssetsContract.verifiedAssets(assetOwner, requestId);
            console.log("Asset found:", {
                assetType: assetData[0],
                assetName: assetData[1],
                assetId: assetData[2].toString(),
                isVerified: assetData[4],
                valueInUSD: assetData[5].toString(),
                owner: assetData[6]
            });
        } catch (error) {
            console.log("Asset not found under owner, checking backend...");
            const backendSigner = await managerContract.backendSigner();
            const assetData = await verifiedAssetsContract.verifiedAssets(backendSigner, requestId);
            console.log("Asset found under backend:", {
                assetType: assetData[0],
                assetName: assetData[1],
                assetId: assetData[2].toString(),
                isVerified: assetData[4],
                valueInUSD: assetData[5].toString(),
                owner: assetData[6]
            });
        }
        
        console.log("\n2. Checking user's coin balance before minting...");
        const balanceBefore = await coinsContract.balanceOf(assetOwner);
        console.log("Coins balance before:", ethers.formatEther(balanceBefore));
        
        console.log("\n3. Attempting to mint NFT and coins...");
        try {
            // Estimate gas first
            const gasEstimate = await managerContract.depositRWAAndMintNFT.estimateGas(
                requestId,
                assetValue,
                assetOwner,
                tokenURI
            );
            console.log("Gas estimate:", gasEstimate.toString());
            
            const tx = await managerContract.depositRWAAndMintNFT(
                requestId,
                assetValue,
                assetOwner,
                tokenURI,
                {
                    gasLimit: gasEstimate * 2n // Double the gas estimate for safety
                }
            );
            console.log("Transaction hash:", tx.hash);
            console.log("Waiting for confirmation...");
            
            const receipt = await tx.wait();
            console.log("✅ Transaction confirmed! Block:", receipt.blockNumber);
            
            // Check balance after
            const balanceAfter = await coinsContract.balanceOf(assetOwner);
            console.log("Coins balance after:", ethers.formatEther(balanceAfter));
            console.log("Coins minted:", ethers.formatEther(balanceAfter - balanceBefore));
            
        } catch (error) {
            console.log("❌ Minting failed:", error.message);
            
            if (error.data) {
                // Try to decode the error
                try {
                    const decoded = managerContract.interface.parseError(error.data);
                    console.log("Decoded error:", decoded.name, decoded.args);
                } catch (decodeError) {
                    console.log("Raw error data:", error.data);
                }
            }
        }
        
    } catch (error) {
        console.error("Error:", error.message);
    }
}

testMinting();
