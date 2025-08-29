import { ethers } from 'ethers';
import { readFileSync } from 'fs';
import dotenv from 'dotenv';

dotenv.config();

const RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/wtwRDsMyNnq_hpPJLrFR4";
const PRIVATE_KEY = process.env.PRIVATE_KEY;

const RWA_VERIFIED_ASSETS = "0x21763032B2170d995c866E249fc85Da49E02aF4c";
const NEW_RWA_NFT = "0x8a6C86c56EE1F2a71E7cE4371F380BfF0ac496ed";
const NEW_RWA_COINS = "0xD3834ee45eE0D76B828Ff02B11eFc19f259B67Eb";

const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

async function deployCorrectRWAManager() {
    try {
        console.log("=== Deploying RWA_Manager with Correct Addresses ===");
        console.log("Deployer:", wallet.address);
        console.log("RWA_VerifiedAssets:", RWA_VERIFIED_ASSETS);
        console.log("RWA_NFT:", NEW_RWA_NFT);
        console.log("RWA_Coins:", NEW_RWA_COINS);
        
        // Read the contract bytecode and ABI
        const contractData = JSON.parse(readFileSync('./out/RWA_Manager.sol/RWA_Manager.json', 'utf8'));
        
        // Create contract factory
        const factory = new ethers.ContractFactory(
            contractData.abi,
            contractData.bytecode,
            wallet
        );
        
        console.log("\nDeploying contract...");
        const contract = await factory.deploy(
            RWA_VERIFIED_ASSETS,
            NEW_RWA_NFT,
            NEW_RWA_COINS,
            {
                gasLimit: 3000000 // Set a generous gas limit
            }
        );
        
        console.log("Transaction hash:", contract.deploymentTransaction().hash);
        console.log("Waiting for deployment...");
        
        await contract.waitForDeployment();
        const address = await contract.getAddress();
        
        console.log("✅ RWA_Manager deployed at:", address);
        
        // Now transfer ownership of NFT and Coins to the new manager
        console.log("\n=== Transferring Ownership to New Manager ===");
        
        const coinsAbi = JSON.parse(readFileSync('./out/RWA_Coins.sol/RWA_Coins.json', 'utf8')).abi;
        const nftAbi = JSON.parse(readFileSync('./out/RWA_NFT.sol/RWA_NFT.json', 'utf8')).abi;
        
        const coinsContract = new ethers.Contract(NEW_RWA_COINS, coinsAbi, wallet);
        const nftContract = new ethers.Contract(NEW_RWA_NFT, nftAbi, wallet);
        
        // Grant MINTER_ROLE to new manager
        console.log("1. Granting MINTER_ROLE to new manager on coins...");
        const MINTER_ROLE = await coinsContract.MINTER_ROLE();
        const grantTx = await coinsContract.grantRole(MINTER_ROLE, address);
        await grantTx.wait();
        console.log("✅ MINTER_ROLE granted");
        
        // Transfer ownership of coins
        console.log("2. Transferring coins ownership...");
        const coinsTransferTx = await coinsContract.transferOwnership(address);
        await coinsTransferTx.wait();
        console.log("✅ Coins ownership transferred");
        
        // Transfer ownership of NFT
        console.log("3. Transferring NFT ownership...");
        const nftTransferTx = await nftContract.transferOwnership(address);
        await nftTransferTx.wait();
        console.log("✅ NFT ownership transferred");
        
        // Set backend signer
        console.log("4. Setting backend signer...");
        const setSignerTx = await contract.setBackendSigner(wallet.address);
        await setSignerTx.wait();
        console.log("✅ Backend signer set");
        
        console.log("\n=== Deployment Complete ===");
        console.log("New RWA_Manager address:", address);
        console.log("Update this address in your .env and frontend files!");
        
        return address;
        
    } catch (error) {
        console.error("Deployment failed:", error.message);
        if (error.reason) {
            console.error("Reason:", error.reason);
        }
    }
}

deployCorrectRWAManager();
