import { ethers } from 'ethers';
import { readFileSync } from 'fs';
import dotenv from 'dotenv';

dotenv.config();

const RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/wtwRDsMyNnq_hpPJLrFR4";
const PRIVATE_KEY = process.env.PRIVATE_KEY;

const RWA_MANAGER = "0x6C39352AE22A6e015aA5c2E166B98135b593f6c7";
const RWA_VERIFIED_ASSETS = "0x21763032B2170d995c866E249fc85Da49E02aF4c";

const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

const rwaManagerAbi = JSON.parse(readFileSync('./out/RWA_Manager.sol/RWA_Manager.json', 'utf8')).abi;
const rwaVerifiedAssetsAbi = JSON.parse(readFileSync('./out/RWA_VerifiedAssets.sol/RWA_VerifiedAssets.json', 'utf8')).abi;

async function findAvailableAssets() {
    try {
        console.log("=== Finding Available Assets ===");
        console.log("User wallet:", wallet.address);
        
        const managerContract = new ethers.Contract(RWA_MANAGER, rwaManagerAbi, wallet);
        const verifiedAssetsContract = new ethers.Contract(RWA_VERIFIED_ASSETS, rwaVerifiedAssetsAbi, wallet);
        
        const backendSigner = await managerContract.backendSigner();
        console.log("Backend signer:", backendSigner);
        
        console.log("\n1. Checking assets under user address...");
        // Try to find assets for IDs 1-20
        for (let i = 1; i <= 20; i++) {
            try {
                const assetData = await verifiedAssetsContract.verifiedAssets(wallet.address, i);
                if (assetData[4]) { // isVerified
                    console.log(`Asset ID ${i} under user:`, {
                        assetName: assetData[1],
                        assetId: assetData[2].toString(),
                        isVerified: assetData[4],
                        valueInUSD: assetData[5].toString(),
                        owner: assetData[6]
                    });
                }
            } catch (error) {
                // Asset doesn't exist, continue
            }
        }
        
        console.log("\n2. Checking assets under backend signer...");
        for (let i = 1; i <= 20; i++) {
            try {
                const assetData = await verifiedAssetsContract.verifiedAssets(backendSigner, i);
                if (assetData[4] && assetData[6].toLowerCase() === wallet.address.toLowerCase()) { // isVerified and owner matches
                    console.log(`Asset ID ${i} under backend (owner: ${assetData[6]}):`, {
                        assetName: assetData[1],
                        assetId: assetData[2].toString(),
                        isVerified: assetData[4],
                        valueInUSD: assetData[5].toString(),
                        owner: assetData[6]
                    });
                }
            } catch (error) {
                // Asset doesn't exist, continue
            }
        }
        
        console.log("\n3. Let's register a new asset for testing...");
        try {
            const registerTx = await verifiedAssetsContract.registerAsset(
                0, // assetType (Real Estate)
                "Test Property for Minting",
                21, // Use ID 21 for new test
                false, // isLocked
                ethers.parseEther("1000"), // 1000 USD value
                wallet.address // owner
            );
            console.log("Registration transaction:", registerTx.hash);
            await registerTx.wait();
            console.log("✅ New asset registered with ID 21");
            
            // Verify the asset
            const verifyTx = await verifiedAssetsContract.verifyAsset(wallet.address, 21);
            console.log("Verification transaction:", verifyTx.hash);
            await verifyTx.wait();
            console.log("✅ Asset verified");
            
            // Check the new asset
            const newAssetData = await verifiedAssetsContract.verifiedAssets(wallet.address, 21);
            console.log("New asset data:", {
                assetName: newAssetData[1],
                assetId: newAssetData[2].toString(),
                isVerified: newAssetData[4],
                valueInUSD: newAssetData[5].toString(),
                owner: newAssetData[6]
            });
            
        } catch (error) {
            console.log("❌ Error registering new asset:", error.message);
        }
        
    } catch (error) {
        console.error("Error:", error.message);
    }
}

findAvailableAssets();
