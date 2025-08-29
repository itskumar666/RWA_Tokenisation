import { ethers } from 'ethers';
import { readFileSync } from 'fs';

const RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/wtwRDsMyNnq_hpPJLrFR4";
const RWA_MANAGER_ADDRESS = "0x6C39352AE22A6e015aA5c2E166B98135b593f6c7";

const provider = new ethers.JsonRpcProvider(RPC_URL);

// Read ABI
const rwaManagerAbi = JSON.parse(readFileSync('./out/RWA_Manager.sol/RWA_Manager.json', 'utf8')).abi;

async function checkDependencies() {
    try {
        const contract = new ethers.Contract(RWA_MANAGER_ADDRESS, rwaManagerAbi, provider);
        
        const nftAddress = await contract.nftContract();
        const coinAddress = await contract.coinContract();
        
        console.log("RWA_Manager Dependencies:");
        console.log("NFT Contract:", nftAddress);
        console.log("Coin Contract:", coinAddress);
        
        console.log("\nNew Deployed Contracts:");
        console.log("New RWA_Coins:", "0xD3834ee45eE0D76B828Ff02B11eFc19f259B67Eb");
        console.log("New RWA_NFT:", "0x8a6C86c56EE1F2a71E7cE4371F380BfF0ac496ed");
        
        console.log("\nContracts Match:", {
            nft: nftAddress.toLowerCase() === "0x8a6c86c56ee1f2a71e7ce4371f380bff0ac496ed",
            coin: coinAddress.toLowerCase() === "0xd3834ee45ee0d76b828ff02b11efc19f259b67eb"
        });
        
    } catch (error) {
        console.error("Error:", error.message);
    }
}

checkDependencies();
