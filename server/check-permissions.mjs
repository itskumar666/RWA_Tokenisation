import { createPublicClient, http } from 'viem';
import { sepolia } from 'viem/chains';

const ownerAbi = [
  { "inputs": [], "name": "owner", "outputs": [{ "internalType": "address", "name": "", "type": "address" }], "stateMutability": "view", "type": "function" }
];

const minterAbi = [
  { "inputs": [{ "internalType": "address", "name": "", "type": "address" }], "name": "minters", "outputs": [{ "internalType": "bool", "name": "", "type": "bool" }], "stateMutability": "view", "type": "function" }
];

async function checkPermissions() {
  const RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/wtwRDsMyNnq_hpPJLrFR4";
  const publicClient = createPublicClient({ chain: sepolia, transport: http(RPC_URL) });

  const NEW_RWA_MANAGER = "0x6C39352AE22A6e015aA5c2E166B98135b593f6c7";
  const RWA_COINS = "0x933A942fB564c21563f4B404C2fD05e0878Dd60E";
  const RWA_NFT = "0xE1Fd0E733db55690ec96a8A7101719D5A456b726";

  console.log("🔍 Checking contract permissions...\n");

  try {
    // Check RWA_NFT owner
    const nftOwner = await publicClient.readContract({
      address: RWA_NFT,
      abi: ownerAbi,
      functionName: 'owner'
    });
    console.log("RWA_NFT owner:", nftOwner);
    console.log("Should be RWA_Manager:", NEW_RWA_MANAGER);
    console.log("NFT ownership correct:", nftOwner.toLowerCase() === NEW_RWA_MANAGER.toLowerCase());

    // Check RWA_Coins owner  
    const coinsOwner = await publicClient.readContract({
      address: RWA_COINS,
      abi: ownerAbi,
      functionName: 'owner'
    });
    console.log("\nRWA_Coins owner:", coinsOwner);
    console.log("Should be RWA_Manager:", NEW_RWA_MANAGER);
    console.log("Coins ownership correct:", coinsOwner.toLowerCase() === NEW_RWA_MANAGER.toLowerCase());

    // Check if RWA_Manager is a minter for RWA_Coins
    const isMinter = await publicClient.readContract({
      address: RWA_COINS,
      abi: minterAbi,
      functionName: 'minters',
      args: [NEW_RWA_MANAGER]
    });
    console.log("\nRWA_Manager is minter for RWA_Coins:", isMinter);

  } catch (error) {
    console.error("❌ Error checking permissions:", error.message);
  }
}

checkPermissions();
