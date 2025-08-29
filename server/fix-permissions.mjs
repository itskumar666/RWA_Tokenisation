import { createWalletClient, createPublicClient, http } from 'viem';
import { sepolia } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';

const ownershipAbi = [
  { "inputs": [{ "internalType": "address", "name": "newOwner", "type": "address" }], "name": "transferOwnership", "outputs": [], "stateMutability": "nonpayable", "type": "function" },
  { "inputs": [{ "internalType": "address", "name": "_minter", "type": "address" }], "name": "addMinter", "outputs": [], "stateMutability": "nonpayable", "type": "function" }
];

async function fixPermissions() {
  const PRIVATE_KEY = "0x6a8f095cc171ef2371d06af1f18663051b1e4847d3c83107664946e481ddd402";
  const RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/wtwRDsMyNnq_hpPJLrFR4";
  
  const NEW_RWA_MANAGER = "0x6C39352AE22A6e015aA5c2E166B98135b593f6c7";
  const RWA_COINS = "0x933A942fB564c21563f4B404C2fD05e0878Dd60E";
  const RWA_NFT = "0xE1Fd0E733db55690ec96a8A7101719D5A456b726";
  
  const account = privateKeyToAccount(PRIVATE_KEY);
  const wallet = createWalletClient({ account, chain: sepolia, transport: http(RPC_URL) });
  const publicClient = createPublicClient({ chain: sepolia, transport: http(RPC_URL) });

  console.log("🔧 Fixing contract permissions...");
  console.log("Account:", account.address);

  try {
    // 1. Add new manager as minter to RWA_Coins first (while we still own it)
    console.log("\n1. Adding new manager as minter to RWA_Coins...");
    const addMinterTx = await wallet.writeContract({
      address: RWA_COINS,
      abi: ownershipAbi,
      functionName: 'addMinter',
      args: [NEW_RWA_MANAGER],
    });
    await publicClient.waitForTransactionReceipt({ hash: addMinterTx });
    console.log(`✅ Minter added: ${addMinterTx}`);

    // 2. Transfer RWA_Coins ownership to new manager
    console.log("\n2. Transferring RWA_Coins ownership...");
    const transferCoinsTx = await wallet.writeContract({
      address: RWA_COINS,
      abi: ownershipAbi,
      functionName: 'transferOwnership',
      args: [NEW_RWA_MANAGER],
    });
    await publicClient.waitForTransactionReceipt({ hash: transferCoinsTx });
    console.log(`✅ RWA_Coins ownership transferred: ${transferCoinsTx}`);

    // 3. Transfer RWA_NFT ownership to new manager
    console.log("\n3. Transferring RWA_NFT ownership...");
    const transferNftTx = await wallet.writeContract({
      address: RWA_NFT,
      abi: ownershipAbi,
      functionName: 'transferOwnership',
      args: [NEW_RWA_MANAGER],
    });
    await publicClient.waitForTransactionReceipt({ hash: transferNftTx });
    console.log(`✅ RWA_NFT ownership transferred: ${transferNftTx}`);

    console.log("\n🎉 All permissions fixed! The new RWA_Manager should now work properly.");

  } catch (error) {
    console.error("❌ Error fixing permissions:", error.message);
    if (error.cause && error.cause.signature) {
      console.error("Error signature:", error.cause.signature);
    }
  }
}

fixPermissions();
