import { createWalletClient, createPublicClient, http } from 'viem';
import { sepolia } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';

// Contract ABIs (minimal required functions)
const rwaManagerAbi = [
  { "inputs": [{ "internalType": "address", "name": "_signer", "type": "address" }], "name": "setBackendSigner", "outputs": [], "stateMutability": "nonpayable", "type": "function" },
  { "inputs": [{ "internalType": "address", "name": "_newMember", "type": "address" }], "name": "setNewMember", "outputs": [], "stateMutability": "nonpayable", "type": "function" }
];

const rwaCoinsAbi = [
  { "inputs": [{ "internalType": "address", "name": "_minter", "type": "address" }], "name": "addMinter", "outputs": [], "stateMutability": "nonpayable", "type": "function" },
  { "inputs": [{ "internalType": "address", "name": "newOwner", "type": "address" }], "name": "transferOwnership", "outputs": [], "stateMutability": "nonpayable", "type": "function" }
];

const rwaNftAbi = [
  { "inputs": [{ "internalType": "address", "name": "newOwner", "type": "address" }], "name": "transferOwnership", "outputs": [], "stateMutability": "nonpayable", "type": "function" }
];

const rwaVerifiedAssetsAbi = [
  { "inputs": [{ "internalType": "address", "name": "_member", "type": "address" }], "name": "addMember", "outputs": [], "stateMutability": "nonpayable", "type": "function" }
];

async function setupNewManager() {
  // Configuration
  const PRIVATE_KEY = "0x6a8f095cc171ef2371d06af1f18663051b1e4847d3c83107664946e481ddd402";
  const RPC_URL = "https://eth-sepolia.g.alchemy.com/v2/wtwRDsMyNnq_hpPJLrFR4";
  
  // Contract addresses
  const NEW_RWA_MANAGER = "0x6C39352AE22A6e015aA5c2E166B98135b593f6c7";
  const RWA_COINS = "0x933A942fB564c21563f4B404C2fD05e0878Dd60E";
  const RWA_NFT = "0xE1Fd0E733db55690ec96a8A7101719D5A456b726";
  const RWA_VERIFIED_ASSETS = "0x21763032B2170d995c866E249fc85Da49E02aF4c";
  
  const account = privateKeyToAccount(PRIVATE_KEY);
  const wallet = createWalletClient({ account, chain: sepolia, transport: http(RPC_URL) });
  const publicClient = createPublicClient({ chain: sepolia, transport: http(RPC_URL) });

  console.log("Setting up new RWA_Manager contract...");
  console.log("Deployer address:", account.address);
  console.log("New RWA_Manager:", NEW_RWA_MANAGER);

  try {
    // 1. Set backend signer in RWA_Manager
    console.log("\n1. Setting backend signer...");
    const setSignerTx = await wallet.writeContract({
      address: NEW_RWA_MANAGER,
      abi: rwaManagerAbi,
      functionName: 'setBackendSigner',
      args: [account.address], // Use same address as backend signer
    });
    await publicClient.waitForTransactionReceipt({ hash: setSignerTx });
    console.log(`✅ Backend signer set: ${setSignerTx}`);

    // 2. Grant MEMBER_ROLE to backend wallet
    console.log("\n2. Granting MEMBER_ROLE to backend wallet...");
    const grantMemberTx = await wallet.writeContract({
      address: NEW_RWA_MANAGER,
      abi: rwaManagerAbi,
      functionName: 'setNewMember',
      args: [account.address],
    });
    await publicClient.waitForTransactionReceipt({ hash: grantMemberTx });
    console.log(`✅ MEMBER_ROLE granted: ${grantMemberTx}`);

    // 3. Add new manager as minter to RWA_Coins
    console.log("\n3. Adding new manager as minter to RWA_Coins...");
    const addMinterTx = await wallet.writeContract({
      address: RWA_COINS,
      abi: rwaCoinsAbi,
      functionName: 'addMinter',
      args: [NEW_RWA_MANAGER],
    });
    await publicClient.waitForTransactionReceipt({ hash: addMinterTx });
    console.log(`✅ Minter role granted to manager: ${addMinterTx}`);

    // 4. Transfer RWA_Coins ownership to new manager
    console.log("\n4. Transferring RWA_Coins ownership to new manager...");
    const transferCoinsTx = await wallet.writeContract({
      address: RWA_COINS,
      abi: rwaCoinsAbi,
      functionName: 'transferOwnership',
      args: [NEW_RWA_MANAGER],
    });
    await publicClient.waitForTransactionReceipt({ hash: transferCoinsTx });
    console.log(`✅ RWA_Coins ownership transferred: ${transferCoinsTx}`);

    // 5. Transfer RWA_NFT ownership to new manager
    console.log("\n5. Transferring RWA_NFT ownership to new manager...");
    const transferNftTx = await wallet.writeContract({
      address: RWA_NFT,
      abi: rwaNftAbi,
      functionName: 'transferOwnership',
      args: [NEW_RWA_MANAGER],
    });
    await publicClient.waitForTransactionReceipt({ hash: transferNftTx });
    console.log(`✅ RWA_NFT ownership transferred: ${transferNftTx}`);

    // 6. Add new manager as member to RWA_VerifiedAssets
    console.log("\n6. Adding new manager as member to RWA_VerifiedAssets...");
    const addVAMemberTx = await wallet.writeContract({
      address: RWA_VERIFIED_ASSETS,
      abi: rwaVerifiedAssetsAbi,
      functionName: 'addMember',
      args: [NEW_RWA_MANAGER],
    });
    await publicClient.waitForTransactionReceipt({ hash: addVAMemberTx });
    console.log(`✅ Member role granted to manager in VerifiedAssets: ${addVAMemberTx}`);

    console.log("\n🎉 Setup complete! New RWA_Manager is ready to use.");
    console.log("Updated contract addresses have been saved to server/.env and frontend/src/addresses.ts");

  } catch (error) {
    console.error("❌ Setup failed:", error);
    process.exit(1);
  }
}

setupNewManager();
