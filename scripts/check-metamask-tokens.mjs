import { ethers } from 'ethers';
import { readFileSync } from 'fs';
import dotenv from 'dotenv';

dotenv.config();

const RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/wtwRDsMyNnq_hpPJLrFR4";
const PRIVATE_KEY = process.env.PRIVATE_KEY;

const RWA_COINS = "0xb36Fe8b07D0E1b59ae8f10965A6F161d63ddC8e1";
const RWA_NFT = "0xaEbbA9173657795BeA06Dfe48E59b0d57778F1Fd";

const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

const coinsAbi = JSON.parse(readFileSync('./out/RWA_Coins.sol/RWA_Coins.json', 'utf8')).abi;
const nftAbi = JSON.parse(readFileSync('./out/RWA_NFT.sol/RWA_NFT.json', 'utf8')).abi;

async function checkTokenBalances() {
    try {
        console.log("🔍 Checking Your Token Balances");
        console.log("Your wallet:", wallet.address);
        console.log("Network: Sepolia Testnet");
        
        const coinsContract = new ethers.Contract(RWA_COINS, coinsAbi, provider);
        const nftContract = new ethers.Contract(RWA_NFT, nftAbi, provider);
        
        // Check RWA Coins balance
        console.log("\n💰 RWA COINS (RWAC)");
        console.log("Contract address:", RWA_COINS);
        
        const coinsBalance = await coinsContract.balanceOf(wallet.address);
        const coinSymbol = await coinsContract.symbol();
        const coinName = await coinsContract.name();
        const coinDecimals = await coinsContract.decimals();
        
        console.log("Token name:", coinName);
        console.log("Token symbol:", coinSymbol);
        console.log("Token decimals:", coinDecimals.toString());
        console.log("Raw balance:", coinsBalance.toString());
        console.log("Formatted balance:", ethers.formatUnits(coinsBalance, coinDecimals));
        
        // Check NFT balance
        console.log("\n🖼️  RWA NFTs");
        console.log("Contract address:", RWA_NFT);
        
        const nftBalance = await nftContract.balanceOf(wallet.address);
        console.log("NFT count:", nftBalance.toString());
        
        // Get details of each NFT
        if (nftBalance > 0) {
            console.log("\nYour NFTs:");
            for (let i = 0; i < Number(nftBalance); i++) {
                try {
                    const tokenId = await nftContract.tokenOfOwnerByIndex(wallet.address, i);
                    const tokenURI = await nftContract.tokenURI(tokenId);
                    console.log(`  NFT #${tokenId}: ${tokenURI}`);
                } catch (error) {
                    console.log(`  NFT #${i}: Could not get details`);
                }
            }
        }
        
        console.log("\n📱 TO ADD COINS TO METAMASK:");
        console.log("1. Open MetaMask");
        console.log("2. Make sure you're on Sepolia Testnet");
        console.log("3. Click 'Import tokens'");
        console.log("4. Enter these details:");
        console.log(`   Contract Address: ${RWA_COINS}`);
        console.log(`   Token Symbol: ${coinSymbol}`);
        console.log(`   Token Decimals: ${coinDecimals}`);
        console.log("5. Click 'Add Custom Token' then 'Import Tokens'");
        
        if (coinsBalance > 0) {
            console.log(`\n✅ You should see ${ethers.formatUnits(coinsBalance, coinDecimals)} ${coinSymbol} in MetaMask!`);
        } else {
            console.log("\n⚠️  You have 0 coins. Try minting some first!");
        }
        
    } catch (error) {
        console.error("Error checking balances:", error.message);
    }
}

checkTokenBalances();
