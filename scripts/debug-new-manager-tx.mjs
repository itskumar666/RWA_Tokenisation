import { ethers } from 'ethers';
import { readFileSync } from 'fs';

const RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/wtwRDsMyNnq_hpPJLrFR4";
const provider = new ethers.JsonRpcProvider(RPC_URL);

const NEW_RWA_MANAGER = "0xc949605cF609adCe31493888e4CCC0a8D1b52b0A";
const rwaManagerAbi = JSON.parse(readFileSync('./out/RWA_Manager.sol/RWA_Manager.json', 'utf8')).abi;

async function debugNewManagerTransaction() {
    try {
        const managerContract = new ethers.Contract(NEW_RWA_MANAGER, rwaManagerAbi, provider);
        
        console.log("=== Debugging New Manager Transaction ===");
        
        // Get the transaction details
        const txHash = "0xfdc2933ea5d4ed71521f075f37a5bbfdb835d00b9b4df3684a9ac2019be48c1d";
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
                    
                    // Check if it's known errors
                    if (error.data === "0xbc278ded") {
                        console.log("This is RWA_Manager__AssetNotVerified error");
                    } else if (error.data.startsWith("0x118cdaa7")) {
                        console.log("This is OwnableUnauthorizedAccount error");
                        console.log("Unauthorized account:", "0x" + error.data.slice(10));
                    }
                }
            }
        }
        
        // Check what the new manager is configured with
        console.log("\n=== Checking New Manager Configuration ===");
        const backendSigner = await managerContract.backendSigner();
        console.log("Backend signer:", backendSigner);
        
        // Test if we can call a simple view function
        console.log("Testing manager contract connection...");
        try {
            const ethBalance = await managerContract.getContractEthBalance();
            console.log("Manager ETH balance:", ethBalance.toString());
            console.log("✅ Manager contract is accessible");
        } catch (error) {
            console.log("❌ Manager contract not accessible:", error.message);
        }
        
    } catch (error) {
        console.error("Error:", error.message);
    }
}

debugNewManagerTransaction();
