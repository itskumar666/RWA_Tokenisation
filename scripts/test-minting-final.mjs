import { ethers } from 'ethers';
import { readFileSync } from 'fs';
import dotenv from 'dotenv';

dotenv.config();

const RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/wtwRDsMyNnq_hpPJLrFR4";
const PRIVATE_KEY = process.env.PRIVATE_KEY;

// Updated contract addresses
const RWA_MANAGER = "0x6C39352AE22A6e015aA5c2E166B98135b593f6c7";
const RWA_COINS = "0xD3834ee45eE0D76B828Ff02B11eFc19f259B67Eb";
const RWA_NFT = "0x8a6C86c56EE1F2a71E7cE4371F380BfF0ac496ed";

const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

// Read ABIs
const rwaManagerAbi = JSON.parse(readFileSync('./out/RWA_Manager.sol/RWA_Manager.json', 'utf8')).abi;
const rwaCoinsAbi = JSON.parse(readFileSync('./out/RWA_Coins.sol/RWA_Coins.json', 'utf8')).abi;
const rwaNftAbi = JSON.parse(readFileSync('./out/RWA_NFT.sol/RWA_NFT.json', 'utf8')).abi;

async function testMintingWithValidAsset() {
    try {
        console.log("=== Testing Minting with Valid Asset ===");
        console.log("User wallet:", wallet.address);
        
        const managerContract = new ethers.Contract(RWA_MANAGER, rwaManagerAbi, wallet);
        const coinsContract = new ethers.Contract(RWA_COINS, rwaCoinsAbi, wallet);
        const nftContract = new ethers.Contract(RWA_NFT, rwaNftAbi, wallet);
        
        // Use Asset ID 1 which we know exists and belongs to our wallet
        const requestId = 1;
        const assetValue = 50; // Value in USD as shown in the asset data
        const assetOwner = wallet.address;
        const tokenURI = "https://example.com/metadata/1.json";
        
        console.log("\n1. Checking balances before minting...");
        const coinsBefore = await coinsContract.balanceOf(assetOwner);
        const nftBalance = await nftContract.balanceOf(assetOwner);
        console.log("Coins balance before:", ethers.formatEther(coinsBefore));
        console.log("NFT balance before:", nftBalance.toString());
        
        console.log("\n2. Attempting to mint NFT and coins...");
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
            console.log("\n3. Balances after minting:");
            console.log("Coins balance after:", ethers.formatEther(coinsAfter));
            console.log("NFT balance after:", nftAfter.toString());
            console.log("Coins minted:", ethers.formatEther(coinsAfter - coinsBefore));
            console.log("NFTs minted:", (nftAfter - nftBalance).toString());
            
            // Check events
            console.log("\n4. Transaction events:");
            for (const log of receipt.logs) {
                try {
                    const parsed = managerContract.interface.parseLog(log);
                    if (parsed) {
                        console.log(`Event: ${parsed.name}`, parsed.args);
                    }
                } catch (error) {
                    // Not a manager contract event, try others
                    try {
                        const parsedCoins = coinsContract.interface.parseLog(log);
                        if (parsedCoins) {
                            console.log(`Coins Event: ${parsedCoins.name}`, parsedCoins.args);
                        }
                    } catch (error2) {
                        try {
                            const parsedNft = nftContract.interface.parseLog(log);
                            if (parsedNft) {
                                console.log(`NFT Event: ${parsedNft.name}`, parsedNft.args);
                            }
                        } catch (error3) {
                            // Unknown event
                        }
                    }
                }
            }
            
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

testMintingWithValidAsset();
