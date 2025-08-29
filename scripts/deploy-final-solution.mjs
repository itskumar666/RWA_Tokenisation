import { ethers } from 'ethers';
import { readFileSync } from 'fs';
import dotenv from 'dotenv';

dotenv.config();

const RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/wtwRDsMyNnq_hpPJLrFR4";
const PRIVATE_KEY = process.env.PRIVATE_KEY;

const RWA_VERIFIED_ASSETS = "0x21763032B2170d995c866E249fc85Da49E02aF4c";
const FRESH_RWA_NFT = "0xaEbbA9173657795BeA06Dfe48E59b0d57778F1Fd";
const FRESH_RWA_COINS = "0xb36Fe8b07D0E1b59ae8f10965A6F161d63ddC8e1";

const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

async function deployFinalManagerAndSetup() {
    try {
        console.log("=== Deploying Final RWA_Manager with Fresh Contracts ===");
        console.log("Deployer:", wallet.address);
        console.log("RWA_VerifiedAssets:", RWA_VERIFIED_ASSETS);
        console.log("Fresh RWA_NFT:", FRESH_RWA_NFT);
        console.log("Fresh RWA_Coins:", FRESH_RWA_COINS);
        
        // Read the contract bytecode and ABI
        const contractData = JSON.parse(readFileSync('./out/RWA_Manager.sol/RWA_Manager.json', 'utf8'));
        
        // Create contract factory
        const factory = new ethers.ContractFactory(
            contractData.abi,
            contractData.bytecode,
            wallet
        );
        
        console.log("\nDeploying RWA_Manager...");
        const managerContract = await factory.deploy(
            RWA_VERIFIED_ASSETS,
            FRESH_RWA_NFT,
            FRESH_RWA_COINS,
            {
                gasLimit: 3000000
            }
        );
        
        console.log("Transaction hash:", managerContract.deploymentTransaction().hash);
        console.log("Waiting for deployment...");
        
        await managerContract.waitForDeployment();
        const managerAddress = await managerContract.getAddress();
        
        console.log("✅ RWA_Manager deployed at:", managerAddress);
        
        // Now setup the dependencies
        console.log("\n=== Setting Up Dependencies ===");
        
        const coinsAbi = JSON.parse(readFileSync('./out/RWA_Coins.sol/RWA_Coins.json', 'utf8')).abi;
        const nftAbi = JSON.parse(readFileSync('./out/RWA_NFT.sol/RWA_NFT.json', 'utf8')).abi;
        
        const coinsContract = new ethers.Contract(FRESH_RWA_COINS, coinsAbi, wallet);
        const nftContract = new ethers.Contract(FRESH_RWA_NFT, nftAbi, wallet);
        
        // Grant MINTER_ROLE to manager on coins
        console.log("1. Granting MINTER_ROLE to manager on coins...");
        const MINTER_ROLE = await coinsContract.MINTER_ROLE();
        const grantTx = await coinsContract.grantRole(MINTER_ROLE, managerAddress);
        await grantTx.wait();
        console.log("✅ MINTER_ROLE granted");
        
        // Transfer ownership of coins to manager
        console.log("2. Transferring coins ownership...");
        const coinsTransferTx = await coinsContract.transferOwnership(managerAddress);
        await coinsTransferTx.wait();
        console.log("✅ Coins ownership transferred");
        
        // Transfer ownership of NFT to manager
        console.log("3. Transferring NFT ownership...");
        const nftTransferTx = await nftContract.transferOwnership(managerAddress);
        await nftTransferTx.wait();
        console.log("✅ NFT ownership transferred");
        
        // Set backend signer
        console.log("4. Setting backend signer...");
        const setSignerTx = await managerContract.setBackendSigner(wallet.address);
        await setSignerTx.wait();
        console.log("✅ Backend signer set");
        
        console.log("\n=== Final Verification ===");
        const finalCoinsOwner = await coinsContract.owner();
        const finalNftOwner = await nftContract.owner();
        const managerHasMinterRole = await coinsContract.hasRole(MINTER_ROLE, managerAddress);
        const backendSigner = await managerContract.backendSigner();
        
        console.log("Coins owner:", finalCoinsOwner);
        console.log("NFT owner:", finalNftOwner);
        console.log("Manager has MINTER_ROLE:", managerHasMinterRole);
        console.log("Backend signer:", backendSigner);
        
        console.log("\n=== Testing Minting ===");
        
        // Test minting with Asset ID 2
        const requestId = 2;
        const assetValue = 56;
        const assetOwner = wallet.address;
        const tokenURI = "https://example.com/metadata/final-test.json";
        
        console.log("Attempting to mint with Asset ID", requestId, "...");
        
        const coinsBefore = await coinsContract.balanceOf(assetOwner);
        const nftBefore = await nftContract.balanceOf(assetOwner);
        
        try {
            const mintTx = await managerContract.depositRWAAndMintNFT(
                requestId,
                assetValue,
                assetOwner,
                tokenURI,
                {
                    gasLimit: 500000
                }
            );
            console.log("Mint transaction hash:", mintTx.hash);
            await mintTx.wait();
            
            const coinsAfter = await coinsContract.balanceOf(assetOwner);
            const nftAfter = await nftContract.balanceOf(assetOwner);
            
            console.log("✅ MINTING SUCCESSFUL!");
            console.log("Coins minted:", ethers.formatEther(coinsAfter - coinsBefore));
            console.log("NFTs minted:", (nftAfter - nftBefore).toString());
            
        } catch (error) {
            console.log("❌ Minting failed:", error.message);
            if (error.data) {
                try {
                    const decoded = managerContract.interface.parseError(error.data);
                    console.log("Decoded error:", decoded.name, decoded.args);
                } catch (decodeError) {
                    console.log("Raw error data:", error.data);
                }
            }
        }
        
        console.log("\n🎉 FINAL SETUP COMPLETE!");
        console.log("=== Update these addresses ===");
        console.log("RWA_Manager:", managerAddress);
        console.log("RWA_Coins:", FRESH_RWA_COINS);
        console.log("RWA_NFT:", FRESH_RWA_NFT);
        
        return {
            manager: managerAddress,
            coins: FRESH_RWA_COINS,
            nft: FRESH_RWA_NFT
        };
        
    } catch (error) {
        console.error("Deployment failed:", error.message);
    }
}

deployFinalManagerAndSetup();
