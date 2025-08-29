import { ethers } from 'ethers';

const RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/wtwRDsMyNnq_hpPJLrFR4";
const RWA_MANAGER_ADDRESS = "0x6C39352AE22A6e015aA5c2E166B98135b593f6c7";

const provider = new ethers.JsonRpcProvider(RPC_URL);

async function checkConstructorParams() {
    try {
        // Get contract creation transaction
        const receipt = await provider.getTransactionReceipt("0x8ded91cbdf7a02b69fcc71b0cab3b9bdd52b05bb6901b6a0fb1b1d5d89b7aa2e");
        console.log("Contract creation receipt:", receipt);
        
        // Check storage slots to see immutable variables
        console.log("\nChecking storage...");
        
        // Since these are immutable variables set in constructor, 
        // let's check the constructor parameters by decoding the transaction input
        const creationTx = await provider.getTransaction("0x8ded91cbdf7a02b69fcc71b0cab3b9bdd52b05bb6901b6a0fb1b1d5d89b7aa2e");
        
        console.log("Constructor params in transaction data:");
        console.log("Input data length:", creationTx.data.length);
        
        // For the old RWA_Manager at 0x73E82673Fc42b501EbF7aC06afe159120f32B587
        console.log("\nLet's check what the old contract dependencies were:");
        
    } catch (error) {
        console.error("Error:", error.message);
    }
}

checkConstructorParams();
