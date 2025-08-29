import { ethers } from 'ethers';
import { readFileSync } from 'fs';

const RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/wtwRDsMyNnq_hpPJLrFR4";
const provider = new ethers.JsonRpcProvider(RPC_URL);

const FINAL_RWA_MANAGER = "0x51293558BBD882FC7aFd4c04aFC277C46A8E3AE5";
const rwaManagerAbi = JSON.parse(readFileSync('./out/RWA_Manager.sol/RWA_Manager.json', 'utf8')).abi;

async function debugFinalTransaction() {
    try {
        const managerContract = new ethers.Contract(FINAL_RWA_MANAGER, rwaManagerAbi, provider);
        
        console.log("=== Debugging Final Transaction ===");
        
        // Get the transaction details - this one ran out of gas
        const txHash = "0x24032f7f331c6b7b4fab7b7213d05cc50110a0f2a0d02deacd4cf1acec373c95";
        const tx = await provider.getTransaction(txHash);
        const receipt = await provider.getTransactionReceipt(txHash);
        
        console.log("Transaction status:", receipt.status); // 0 = failed, 1 = success
        console.log("Gas used:", receipt.gasUsed.toString());
        console.log("Gas limit:", tx.gasLimit.toString());
        console.log("Gas used == Gas limit?", receipt.gasUsed.toString() === tx.gasLimit.toString());
        
        if (receipt.gasUsed.toString() === tx.gasLimit.toString()) {
            console.log("🔥 TRANSACTION RAN OUT OF GAS!");
            console.log("Let's estimate gas for this call...");
            
            // Try to estimate gas for the same call
            try {
                const gasEstimate = await managerContract.depositRWAAndMintNFT.estimateGas(
                    2, // requestId
                    56, // assetValue
                    "0x6edb706D0BD486BCcA07ddd189586481bbfD4811", // assetOwner
                    "https://example.com/metadata/final-test.json" // tokenURI
                );
                console.log("✅ Gas estimate:", gasEstimate.toString());
                console.log("Recommended gas limit:", (gasEstimate * 120n / 100n).toString(), "(+20% buffer)");
                
                // Now try the actual call with proper gas
                console.log("\n=== Attempting Mint with Proper Gas Limit ===");
                const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
                const managerWithSigner = new ethers.Contract(FINAL_RWA_MANAGER, rwaManagerAbi, wallet);
                
                const mintTx = await managerWithSigner.depositRWAAndMintNFT(
                    2,
                    56,
                    wallet.address,
                    "https://example.com/metadata/success.json",
                    {
                        gasLimit: gasEstimate * 150n / 100n // +50% buffer
                    }
                );
                
                console.log("New mint transaction hash:", mintTx.hash);
                console.log("Waiting for confirmation...");
                
                const newReceipt = await mintTx.wait();
                console.log("🎉 SUCCESS! Block:", newReceipt.blockNumber);
                console.log("Gas used:", newReceipt.gasUsed.toString());
                
                // Check balances
                const coinsAbi = JSON.parse(readFileSync('./out/RWA_Coins.sol/RWA_Coins.json', 'utf8')).abi;
                const nftAbi = JSON.parse(readFileSync('./out/RWA_NFT.sol/RWA_NFT.json', 'utf8')).abi;
                
                const coinsContract = new ethers.Contract("0xb36Fe8b07D0E1b59ae8f10965A6F161d63ddC8e1", coinsAbi, provider);
                const nftContract = new ethers.Contract("0xaEbbA9173657795BeA06Dfe48E59b0d57778F1Fd", nftAbi, provider);
                
                const coinsBalance = await coinsContract.balanceOf(wallet.address);
                const nftBalance = await nftContract.balanceOf(wallet.address);
                
                console.log("Final coins balance:", ethers.formatEther(coinsBalance));
                console.log("Final NFT balance:", nftBalance.toString());
                
                console.log("\n🚀 COMPLETE SUCCESS! The system is now working!");
                
            } catch (error) {
                console.log("❌ Gas estimation failed:", error.message);
                if (error.data) {
                    try {
                        const decoded = managerContract.interface.parseError(error.data);
                        console.log("Decoded error:", decoded.name, decoded.args);
                    } catch (decodeError) {
                        console.log("Raw error data:", error.data);
                        if (error.data === "0xbc278ded") {
                            console.log("This is RWA_Manager__AssetNotVerified error");
                        }
                    }
                }
            }
        }
        
    } catch (error) {
        console.error("Error:", error.message);
    }
}

debugFinalTransaction();
