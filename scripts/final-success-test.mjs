import { ethers } from 'ethers';
import { readFileSync } from 'fs';
import dotenv from 'dotenv';

dotenv.config();

const RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/wtwRDsMyNnq_hpPJLrFR4";
const PRIVATE_KEY = process.env.PRIVATE_KEY;

const FINAL_RWA_MANAGER = "0x51293558BBD882FC7aFd4c04aFC277C46A8E3AE5";
const FINAL_RWA_COINS = "0xb36Fe8b07D0E1b59ae8f10965A6F161d63ddC8e1";
const FINAL_RWA_NFT = "0xaEbbA9173657795BeA06Dfe48E59b0d57778F1Fd";

const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

const rwaManagerAbi = JSON.parse(readFileSync('./out/RWA_Manager.sol/RWA_Manager.json', 'utf8')).abi;
const coinsAbi = JSON.parse(readFileSync('./out/RWA_Coins.sol/RWA_Coins.json', 'utf8')).abi;
const nftAbi = JSON.parse(readFileSync('./out/RWA_NFT.sol/RWA_NFT.json', 'utf8')).abi;

async function finalSuccessfulMint() {
    try {
        console.log("=== Final Successful Minting Test ===");
        console.log("User wallet:", wallet.address);
        console.log("RWA_Manager:", FINAL_RWA_MANAGER);
        
        const managerContract = new ethers.Contract(FINAL_RWA_MANAGER, rwaManagerAbi, wallet);
        const coinsContract = new ethers.Contract(FINAL_RWA_COINS, coinsAbi, wallet);
        const nftContract = new ethers.Contract(FINAL_RWA_NFT, nftAbi, wallet);
        
        // Check balances before
        console.log("\n1. Balances before minting:");
        const coinsBefore = await coinsContract.balanceOf(wallet.address);
        const nftBefore = await nftContract.balanceOf(wallet.address);
        console.log("Coins balance:", ethers.formatEther(coinsBefore));
        console.log("NFT balance:", nftBefore.toString());
        
        // Parameters for Asset ID 2
        const requestId = 2;
        const assetValue = 56;
        const assetOwner = wallet.address;
        const tokenURI = "https://example.com/metadata/successful-mint.json";
        
        console.log("\n2. Estimating gas...");
        const gasEstimate = await managerContract.depositRWAAndMintNFT.estimateGas(
            requestId,
            assetValue,
            assetOwner,
            tokenURI
        );
        console.log("Gas estimate:", gasEstimate.toString());
        
        const gasLimit = gasEstimate * 150n / 100n; // +50% buffer
        console.log("Gas limit with buffer:", gasLimit.toString());
        
        console.log("\n3. Attempting mint with proper gas limit...");
        const mintTx = await managerContract.depositRWAAndMintNFT(
            requestId,
            assetValue,
            assetOwner,
            tokenURI,
            {
                gasLimit: gasLimit
            }
        );
        
        console.log("Transaction hash:", mintTx.hash);
        console.log("Waiting for confirmation...");
        
        const receipt = await mintTx.wait();
        console.log("✅ Transaction confirmed! Block:", receipt.blockNumber);
        console.log("Gas used:", receipt.gasUsed.toString());
        console.log("Gas efficiency:", Math.round(Number(receipt.gasUsed) * 100 / Number(gasLimit)), "%");
        
        // Check balances after
        console.log("\n4. Balances after minting:");
        const coinsAfter = await coinsContract.balanceOf(wallet.address);
        const nftAfter = await nftContract.balanceOf(wallet.address);
        console.log("Coins balance:", ethers.formatEther(coinsAfter));
        console.log("NFT balance:", nftAfter.toString());
        
        console.log("\n5. Summary:");
        console.log("Coins minted:", ethers.formatEther(coinsAfter - coinsBefore));
        console.log("NFTs minted:", (nftAfter - nftBefore).toString());
        
        // Get the newest NFT details
        if (nftAfter > nftBefore) {
            const latestTokenId = nftAfter - 1n; // Assuming 0-based indexing
            try {
                const tokenURI_result = await nftContract.tokenURI(latestTokenId);
                console.log("Latest NFT token URI:", tokenURI_result);
            } catch (error) {
                console.log("Could not get token URI for latest NFT");
            }
        }
        
        console.log("\n🎉🚀 COMPLETE SUCCESS! 🚀🎉");
        console.log("=== The RWA tokenization system is now fully functional! ===");
        console.log("\nFinal Contract Addresses:");
        console.log("RWA_Manager:", FINAL_RWA_MANAGER);
        console.log("RWA_Coins:", FINAL_RWA_COINS);
        console.log("RWA_NFT:", FINAL_RWA_NFT);
        console.log("RWA_VerifiedAssets: 0x21763032B2170d995c866E249fc85Da49E02aF4c");
        
    } catch (error) {
        console.error("❌ Final test failed:", error.message);
        if (error.data) {
            console.log("Error data:", error.data);
        }
    }
}

finalSuccessfulMint();
