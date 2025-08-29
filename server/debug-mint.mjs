import { createWalletClient, createPublicClient, http } from 'viem';
import { sepolia } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';

const rwaManagerAbi = [
  {
    "inputs": [
      { "internalType": "uint256", "name": "_requestId", "type": "uint256" },
      { "internalType": "uint256", "name": "_assetValue", "type": "uint256" },
      { "internalType": "address", "name": "_assetOwner", "type": "address" },
      { "internalType": "string", "name": "_tokenURI", "type": "string" }
    ],
    "name": "depositRWAAndMintNFT",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  }
];

async function debugMint() {
  const PRIVATE_KEY = "0x6a8f095cc171ef2371d06af1f18663051b1e4847d3c83107664946e481ddd402";
  const RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/wtwRDsMyNnq_hpPJLrFR4";
  const RWA_MANAGER = "0x6C39352AE22A6e015aA5c2E166B98135b593f6c7";
  
  const account = privateKeyToAccount(PRIVATE_KEY);
  const wallet = createWalletClient({ account, chain: sepolia, transport: http(RPC_URL) });
  const publicClient = createPublicClient({ chain: sepolia, transport: http(RPC_URL) });

  console.log("Testing mint with account:", account.address);
  console.log("RWA_Manager address:", RWA_MANAGER);

  try {
    // Test with asset ID 10 that has a different owner (0x0BFB2e11baE45e68459178785B94c7958B358a9A)
    console.log("\n🧪 Attempting to mint asset ID 10...");
    
    const txHash = await wallet.writeContract({
      address: RWA_MANAGER,
      abi: rwaManagerAbi,
      functionName: 'depositRWAAndMintNFT',
      args: [
        BigInt(10), // requestId
        BigInt(1111),  // assetValue matches the asset
        "0x0BFB2e11baE45e68459178785B94c7958B358a9A", // actual asset owner
        "asset-10" // tokenURI
      ],
    });
    
    console.log("✅ Transaction sent:", txHash);
    
    const receipt = await publicClient.waitForTransactionReceipt({ hash: txHash });
    console.log("✅ Transaction confirmed:", receipt.status);
    
  } catch (error) {
    console.error("❌ Transaction failed:");
    console.error("Error message:", error.message);
    console.error("Error details:", error.details || error.cause?.details);
    
    // Try to get more specific error information
    if (error.cause && error.cause.signature) {
      console.error("Error signature:", error.cause.signature);
    }
    
    // Check if it's a revert with specific error
    if (error.shortMessage) {
      console.error("Short message:", error.shortMessage);
    }
  }
}

debugMint();
