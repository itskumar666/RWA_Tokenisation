import { ethers } from 'ethers';
import { readFileSync } from 'fs';
import dotenv from 'dotenv';

dotenv.config();

const RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/wtwRDsMyNnq_hpPJLrFR4";
const PRIVATE_KEY = process.env.PRIVATE_KEY;

const RWA_MANAGER = "0x6C39352AE22A6e015aA5c2E166B98135b593f6c7";

const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

const rwaManagerAbi = JSON.parse(readFileSync('./out/RWA_Manager.sol/RWA_Manager.json', 'utf8')).abi;

async function debugFailedTransaction() {
    try {
        const managerContract = new ethers.Contract(RWA_MANAGER, rwaManagerAbi, wallet);
        
        console.log("=== Debugging Failed Transaction ===");
        
        // Get the transaction details
        const txHash = "0x4684e30e5ae2456df53879064565f554d7c5f662fac9e51e7f458d37fa829b99";
        const tx = await provider.getTransaction(txHash);
        const receipt = await provider.getTransactionReceipt(txHash);
        
        console.log("Transaction status:", receipt.status); // 0 = failed, 1 = success
        console.log("Gas used:", receipt.gasUsed.toString());
        console.log("Gas limit:", tx.gasLimit.toString());
        
        // Try to simulate the call to get the revert reason
        try {
            const result = await provider.call({
                to: tx.to,
                data: tx.data,
                from: tx.from,
                gasLimit: tx.gasLimit,
                gasPrice: tx.gasPrice,
                value: tx.value
            }, receipt.blockNumber - 1);
            console.log("Call result:", result);
        } catch (error) {
            console.log("Call error:", error.message);
            if (error.data) {
                console.log("Error data:", error.data);
                
                // Try to decode the error
                try {
                    const decoded = managerContract.interface.parseError(error.data);
                    console.log("Decoded error:", decoded.name, decoded.args);
                } catch (decodeError) {
                    console.log("Could not decode error");
                    
                    // Check if it's the asset not verified error
                    if (error.data === "0xbc278ded") {
                        console.log("This is RWA_Manager__AssetNotVerified error");
                    }
                }
            }
        }
        
        // Let's also check if the asset data for ID 1 has changed
        console.log("\n=== Checking Asset Status ===");
        const rwaVerifiedAssetsAbi = JSON.parse(readFileSync('./out/RWA_VerifiedAssets.sol/RWA_VerifiedAssets.json', 'utf8')).abi;
        const verifiedAssetsContract = new ethers.Contract("0x21763032B2170d995c866E249fc85Da49E02aF4c", rwaVerifiedAssetsAbi, wallet);
        
        const assetData = await verifiedAssetsContract.verifiedAssets(wallet.address, 1);
        console.log("Asset 1 data:", {
            assetType: assetData[0],
            assetName: assetData[1],
            assetId: assetData[2].toString(),
            isLocked: assetData[3],
            isVerified: assetData[4],
            valueInUSD: assetData[5].toString(),
            owner: assetData[6],
            tradable: assetData[7]
        });
        
        // Check if it exists under backend signer
        const backendSigner = await managerContract.backendSigner();
        const backendAssetData = await verifiedAssetsContract.verifiedAssets(backendSigner, 1);
        console.log("Asset 1 under backend:", {
            assetType: backendAssetData[0],
            assetName: backendAssetData[1], 
            assetId: backendAssetData[2].toString(),
            isLocked: backendAssetData[3],
            isVerified: backendAssetData[4],
            valueInUSD: backendAssetData[5].toString(),
            owner: backendAssetData[6],
            tradable: backendAssetData[7]
        });
        
    } catch (error) {
        console.error("Error:", error.message);
    }
}

debugFailedTransaction();
