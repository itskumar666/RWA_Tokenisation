import 'dotenv/config';
import express, { Request, Response } from 'express';
import cors from 'cors';
import multer from 'multer';
import fs from 'fs';
import path from 'path';
import { createWalletClient, createPublicClient, encodeAbiParameters, http, parseAbiParameters, keccak256, parseAbiItem } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { sepolia } from 'viem/chains';
import { rwaVerifiedAssetsAbi } from './abi/rwaVerifiedAssets.js';
import { rwaManagerAbi } from './abi/rwaManager.js';
// Minimal ABI for RWA_NFT used in read-only endpoints
const rwaNftAbi = [
  { type: 'function', name: 'ownerOf', stateMutability: 'view', inputs: [ { name: 'tokenId', type: 'uint256' } ], outputs: [ { type: 'address' } ] },
  { type: 'function', name: 'balanceOf', stateMutability: 'view', inputs: [ { name: 'owner', type: 'address' } ], outputs: [ { type: 'uint256' } ] },
  { type: 'function', name: 'owner', stateMutability: 'view', inputs: [], outputs: [ { type: 'address' } ] },
] as const;

// Minimal ABI for AccessControl-aware coins to check MINTER_ROLE
const accessControlAbi = [
  { type: 'function', name: 'hasRole', stateMutability: 'view', inputs: [ { name: 'role', type: 'bytes32' }, { name: 'account', type: 'address' } ], outputs: [ { type: 'bool' } ] },
  { type: 'function', name: 'MINTER_ROLE', stateMutability: 'view', inputs: [], outputs: [ { type: 'bytes32' } ] },
] as const;
import { nextAssetId } from './state.js';

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 25 * 1024 * 1024 } });

// Optional static hosting for saved files
const UPLOAD_DIR = process.env.UPLOAD_DIR || path.join(process.cwd(), 'uploads');
if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}
app.use('/uploads', express.static(UPLOAD_DIR));

// Legacy IPFS endpoint retained for compatibility (unused by new flow)
app.post('/upload', upload.single('file'), async (_req: Request, res: Response) => {
  res.status(410).json({ error: 'Deprecated. Use /assets/register with files.' });
});

app.post('/assets/register', upload.array('files', 10), async (req: Request, res: Response) => {
  try {
  const { assetType, assetName, valueUSD, owner, isLocked: isLockedRaw } = req.body as { assetType: string; assetName: string; valueUSD: string; owner?: string; isLocked?: string };
    const files = (req.files as Express.Multer.File[]) || [];
    if (!files.length) return res.status(400).json({ error: 'files missing' });
    if (!assetName || typeof assetName !== 'string') return res.status(400).json({ error: 'assetName required' });
    if (assetType === undefined) return res.status(400).json({ error: 'assetType required' });

  // normalize boolean
  const isLocked = typeof isLockedRaw === 'string' ? ['true', '1', 'yes', 'y', 'on'].includes(isLockedRaw.trim().toLowerCase()) : false;

  // Prepare chain clients and addresses
  const pk = process.env.BACKEND_PRIVATE_KEY?.startsWith('0x') ? (process.env.BACKEND_PRIVATE_KEY as `0x${string}`) : (`0x${process.env.BACKEND_PRIVATE_KEY}` as `0x${string}`);
  const rpcUrl = process.env.SEPOLIA_RPC_URL;
  const vaAddr = process.env.RWA_VERIFIED_ASSETS as `0x${string}`;
  if (!pk || pk.length < 10) throw new Error('Missing BACKEND_PRIVATE_KEY');
  if (!rpcUrl) throw new Error('Missing SEPOLIA_RPC_URL');
  if (!vaAddr) throw new Error('Missing RWA_VERIFIED_ASSETS');

  const account = privateKeyToAccount(pk);
  const wallet = createWalletClient({ account, chain: sepolia, transport: http(rpcUrl) });
  const pub = createPublicClient({ chain: sepolia, transport: http(rpcUrl) });

  // 1) Compute assetId to equal the on-chain index (length) under the backend registry key
  //    so RWA_Manager's index-based lookup and equality check succeed without redeploys.
  let id: number = 0;
  try {
    const existing = await pub.readContract({ address: vaAddr, abi: rwaVerifiedAssetsAbi, functionName: 'getVerifiedAssets', args: [account.address] });
    id = Array.isArray(existing) ? (existing as any[]).length : 0;
  } catch {
    // Fallback to local counter if RPC fails
    id = nextAssetId();
  }

  // Resolve the intended asset owner once, use consistently both in function arg and encoded payload
  const ownerAddr = (owner && /^0x[0-9a-fA-F]{40}$/.test(owner)) ? (owner as `0x${string}`) : account.address;

  // 2) Persist files locally under uploads/<assetId>
  const assetDir = path.join(UPLOAD_DIR, String(id));
  if (!fs.existsSync(assetDir)) fs.mkdirSync(assetDir, { recursive: true });
  const saved: string[] = [];
  for (const f of files) {
    const safeName = f.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
    const target = path.join(assetDir, safeName);
    fs.writeFileSync(target, f.buffer);
    saved.push(`/uploads/${id}/${safeName}`);
  }

  // 3) Encode payload per contract
  const encoded = encodeAbiParameters(
    parseAbiParameters('uint8, string, uint256, bool, uint256, address'),
    [
      Number(assetType || 0),
      `${assetName} [files:${saved.length}]`,
      BigInt(id),
      isLocked,
      BigInt(valueUSD || '0'),
      ownerAddr,
    ],
  );

  // 4) Send tx via viem; this server must be a MEMBER
  const hash = await wallet.writeContract({ address: vaAddr, abi: rwaVerifiedAssetsAbi, functionName: 'registerVerifiedAsset', args: [ownerAddr, encoded] });

  res.json({ assetId: id, isLocked, txHash: hash });
  } catch (e: any) {
    res.status(500).json({ error: e?.shortMessage || e?.message || 'register failed' });
  }
});

// Deregister an asset (server-signed)
app.post('/assets/deregister', async (req: Request, res: Response) => {
  try {
    const { owner, assetId } = req.body as { owner?: string; assetId?: string };
    if (!owner || !assetId) return res.status(400).json({ error: 'owner and assetId required' });

    const pk = process.env.BACKEND_PRIVATE_KEY?.startsWith('0x') ? process.env.BACKEND_PRIVATE_KEY as `0x${string}` : (`0x${process.env.BACKEND_PRIVATE_KEY}` as `0x${string}`);
    const rpcUrl = process.env.SEPOLIA_RPC_URL;
    const vaAddr = process.env.RWA_VERIFIED_ASSETS as `0x${string}`;
    if (!pk || pk.length < 10) throw new Error('Missing BACKEND_PRIVATE_KEY');
    if (!rpcUrl) throw new Error('Missing SEPOLIA_RPC_URL');
    if (!vaAddr) throw new Error('Missing RWA_VERIFIED_ASSETS');

    const account = privateKeyToAccount(pk);
    const wallet = createWalletClient({ account, chain: sepolia, transport: http(rpcUrl) });
    const hash = await wallet.writeContract({ address: vaAddr, abi: rwaVerifiedAssetsAbi, functionName: 'DeRegisterVerifiedAsset', args: [owner as `0x${string}`, BigInt(assetId)] });
    res.json({ txHash: hash });
  } catch (e: any) {
    res.status(500).json({ error: e?.shortMessage || e?.message || 'deregister failed' });
  }
});

// Update asset value (server-signed)
app.post('/assets/update', async (req: Request, res: Response) => {
  try {
    const { owner, assetId, newValueUSD, isLocked, tradable } = req.body as { owner?: string; assetId?: string; newValueUSD?: string; isLocked?: string | boolean; tradable?: string | boolean };
    if (!owner || !assetId || !newValueUSD) return res.status(400).json({ error: 'owner, assetId, newValueUSD required' });
    const lock = typeof isLocked === 'string' ? ['true','1','yes','y','on'].includes(isLocked.toLowerCase()) : !!isLocked;
    const trad = typeof tradable === 'string' ? ['true','1','yes','y','on'].includes(tradable.toLowerCase()) : !!tradable;

    const pk = process.env.BACKEND_PRIVATE_KEY?.startsWith('0x') ? process.env.BACKEND_PRIVATE_KEY as `0x${string}` : (`0x${process.env.BACKEND_PRIVATE_KEY}` as `0x${string}`);
    const rpcUrl = process.env.SEPOLIA_RPC_URL;
    const vaAddr = process.env.RWA_VERIFIED_ASSETS as `0x${string}`;
    if (!pk || pk.length < 10) throw new Error('Missing BACKEND_PRIVATE_KEY');
    if (!rpcUrl) throw new Error('Missing SEPOLIA_RPC_URL');
    if (!vaAddr) throw new Error('Missing RWA_VERIFIED_ASSETS');

    const account = privateKeyToAccount(pk);
    const wallet = createWalletClient({ account, chain: sepolia, transport: http(rpcUrl) });
    const hash = await wallet.writeContract({ address: vaAddr, abi: rwaVerifiedAssetsAbi, functionName: 'upDateAssetValue', args: [owner as `0x${string}`, BigInt(assetId), BigInt(newValueUSD), lock, trad] });
    res.json({ txHash: hash });
  } catch (e: any) {
    res.status(500).json({ error: e?.shortMessage || e?.message || 'update failed' });
  }
});

// Sign a mint proof: keccak256(abi.encode(owner, requestId)) signed by backend
app.post('/mint/proof', async (req: Request, res: Response) => {
  try {
    const { owner, requestId } = req.body as { owner?: string; requestId?: string };
    if (!owner || !/^0x[0-9a-fA-F]{40}$/.test(owner || '')) return res.status(400).json({ error: 'valid owner required' });
    if (!requestId) return res.status(400).json({ error: 'requestId required' });

    const pk = process.env.BACKEND_PRIVATE_KEY?.startsWith('0x') ? (process.env.BACKEND_PRIVATE_KEY as `0x${string}`) : (`0x${process.env.BACKEND_PRIVATE_KEY}` as `0x${string}`);
    if (!pk || pk.length < 10) throw new Error('Missing BACKEND_PRIVATE_KEY');

  const account = privateKeyToAccount(pk);
  const abiBytes = encodeAbiParameters(parseAbiParameters('address,uint256'), [owner as `0x${string}`, BigInt(requestId)]);
  const digest = keccak256(abiBytes);
  const sig = await account.signMessage({ message: { raw: digest } });
  res.json({ signer: account.address, signature: sig, digest });
  } catch (e: any) {
    res.status(500).json({ error: e?.message || 'proof failed' });
  }
});

// Backend-initiated or relayed deposit+mint into Manager with proof
// DEPRECATED: Users can now call depositRWAAndMintNFT directly from frontend
// app.post('/manager/deposit', async (req: Request, res: Response) => {
//   // This endpoint is no longer needed since onlyMember modifier was removed
// });

// DEPRECATED: Raw deposit endpoint no longer needed  
// app.post('/manager/deposit/raw', async (req: Request, res: Response) => {
//   // This endpoint is no longer needed since users can call contract directly
// });

// DEPRECATED: Test endpoint no longer needed since users can register and mint directly
// app.post('/test/register-and-mint', async (req: Request, res: Response) => {
//   // This endpoint is no longer needed since users can call contracts directly
// });

// Preflight diagnostics for manager deposit
app.get('/debug/manager/preflight', async (req: Request, res: Response) => {
  try {
    const owner = (req.query.owner as string) || '';
    const requestId = (req.query.requestId as string) || '';
    if (!owner || !/^0x[0-9a-fA-F]{40}$/.test(owner)) return res.status(400).json({ error: 'valid owner required' });
    if (!requestId) return res.status(400).json({ error: 'requestId required' });

    const rpcUrl = process.env.SEPOLIA_RPC_URL;
  const managerAddr = process.env.RWA_MANAGER as `0x${string}`;
    const vaAddr = process.env.RWA_VERIFIED_ASSETS as `0x${string}`;
    const nftAddr = process.env.RWA_NFT as `0x${string}`;
  const coinAddr = (process.env.RWA_COINS as `0x${string}` | undefined) || (process.env.RWA_Coins as `0x${string}` | undefined);
    if (!rpcUrl || !managerAddr || !vaAddr || !nftAddr) throw new Error('env missing');

    const pk = process.env.BACKEND_PRIVATE_KEY?.startsWith('0x') ? (process.env.BACKEND_PRIVATE_KEY as `0x${string}`) : (`0x${process.env.BACKEND_PRIVATE_KEY}` as `0x${string}`);
    const backend = privateKeyToAccount(pk);
    const pub = createPublicClient({ chain: sepolia, transport: http(rpcUrl) });

    // 1) Manager member role for backend
    const managerAccessAbi = [
      { type: 'function', name: 'MEMBER_ROLE', stateMutability: 'view', inputs: [], outputs: [ { type: 'bytes32' } ] },
      { type: 'function', name: 'hasRole', stateMutability: 'view', inputs: [ { name: 'role', type: 'bytes32' }, { name: 'account', type: 'address' } ], outputs: [ { type: 'bool' } ] },
    ] as const;
    const memberRole: `0x${string}` = await pub.readContract({ address: managerAddr, abi: managerAccessAbi, functionName: 'MEMBER_ROLE' });
    const isBackendMember: boolean = await pub.readContract({ address: managerAddr, abi: managerAccessAbi, functionName: 'hasRole', args: [memberRole, backend.address] });

    // 2) VerifiedAssets checks: under owner vs backend
  const assetsOwner = (await pub.readContract({ address: vaAddr, abi: rwaVerifiedAssetsAbi, functionName: 'getVerifiedAssets', args: [owner as `0x${string}`] })) as unknown as any[];
  const assetsBackend = (await pub.readContract({ address: vaAddr, abi: rwaVerifiedAssetsAbi, functionName: 'getVerifiedAssets', args: [backend.address] })) as unknown as any[];
  const foundUnderOwner = (assetsOwner || []).some((a: any) => (a.assetId as bigint) === BigInt(requestId));
  const foundUnderBackend = (assetsBackend || []).some((a: any) => (a.assetId as bigint) === BigInt(requestId));

    // 3) NFT owner is manager?
    const nftOwner: string = await pub.readContract({ address: nftAddr, abi: rwaNftAbi, functionName: 'owner' });
    const isNftOwnerManager = nftOwner.toLowerCase() === managerAddr.toLowerCase();

    // 4) Coin minter role
    let coinMinterOk: boolean | null = null;
    try {
      if (coinAddr) {
        const role: `0x${string}` = await pub.readContract({ address: coinAddr as `0x${string}`, abi: accessControlAbi, functionName: 'MINTER_ROLE' });
        coinMinterOk = await pub.readContract({ address: coinAddr as `0x${string}`, abi: accessControlAbi, functionName: 'hasRole', args: [role, managerAddr] });
      }
    } catch { coinMinterOk = null; }

    res.json({
      backend: backend.address,
      manager: managerAddr,
      roles: { isBackendMember },
      verifiedAssets: { foundUnderOwner, foundUnderBackend },
      nft: { owner: nftOwner, isNftOwnerManager },
      coin: { coinAddr: coinAddr ?? null, coinMinterOk },
    });
  } catch (e: any) {
    res.status(500).json({ error: e?.message || 'preflight failed' });
  }
});

// Debug: examine exact asset struct data 
app.get('/debug/asset/:registryKey/:assetId', async (req: Request, res: Response) => {
  try {
    const { registryKey, assetId } = req.params;
    if (!registryKey || !assetId) return res.status(400).json({ error: 'registryKey and assetId required' });

    const rpcUrl = process.env.SEPOLIA_RPC_URL;
    const vaAddr = process.env.RWA_VERIFIED_ASSETS as `0x${string}`;
    if (!rpcUrl || !vaAddr) throw new Error('env missing');

    const pub = createPublicClient({ chain: sepolia, transport: http(rpcUrl) });
    const assets = await pub.readContract({ 
      address: vaAddr, 
      abi: rwaVerifiedAssetsAbi, 
      functionName: 'getVerifiedAssets', 
      args: [registryKey as `0x${string}`] 
    });

    const found = (assets as any[]).find((a: any) => 
      (a.assetId as bigint) === BigInt(assetId)
    );

    if (!found) {
      return res.json({ error: 'Asset not found', registryKey, assetId, totalAssets: (assets as any[]).length });
    }

    // Normalize for JSON
    const normalized = {
      assetType: Number(found.assetType),
      assetName: found.assetName,
      assetId: found.assetId.toString(),
      isLocked: found.isLocked,
      isVerified: found.isVerified,
      valueInUSD: found.valueInUSD.toString(),
      owner: found.owner,
      tradable: found.tradable,
    };

    res.json({ asset: normalized, registryKey, searchedAssetId: assetId });
  } catch (e: any) {
    res.status(500).json({ error: e?.message || 'debug asset failed' });
  }
});
// Get minted status for a user and requestId via RWA_Manager view
app.get('/manager/status', async (req: Request, res: Response) => {
  try {
    const user = (req.query.user as string) || '';
    const requestId = (req.query.requestId as string) || '';
    if (!user || !/^0x[0-9a-fA-F]{40}$/.test(user)) return res.status(400).json({ error: 'valid user query param required' });
    if (!requestId) return res.status(400).json({ error: 'requestId required' });

    const rpcUrl = process.env.SEPOLIA_RPC_URL;
    const managerAddr = process.env.RWA_MANAGER as `0x${string}`;
    if (!rpcUrl) throw new Error('Missing SEPOLIA_RPC_URL');
    if (!managerAddr) throw new Error('Missing RWA_MANAGER');

    const pub = createPublicClient({ chain: sepolia, transport: http(rpcUrl) });
    const info: any = await pub.readContract({ address: managerAddr, abi: rwaManagerAbi, functionName: 'getUserAssetInfo', args: [user as `0x${string}`, BigInt(requestId)] });
    const minted = info && info.assetId && BigInt(info.assetId) === BigInt(requestId) && info.owner?.toLowerCase() === user.toLowerCase();
    const normalized = info
      ? {
          assetType: typeof info.assetType === 'bigint' ? Number(info.assetType) : info.assetType,
          assetName: info.assetName,
          assetId: info.assetId ? info.assetId.toString() : '0',
          isLocked: !!info.isLocked,
          isVerified: !!info.isVerified,
          valueInUSD: info.valueInUSD ? info.valueInUSD.toString() : '0',
          owner: info.owner,
          tradable: !!info.tradable,
        }
      : null;
    res.json({ minted: !!minted, info: normalized });
  } catch (e: any) {
    res.status(500).json({ error: e?.shortMessage || e?.message || 'status failed' });
  }
});

// List assets for an address (reads on-chain)
app.get('/assets/list', async (req: Request, res: Response) => {
  try {
    const owner = (req.query.owner as string) || '';
    if (!owner || !/^0x[0-9a-fA-F]{40}$/.test(owner)) return res.status(400).json({ error: 'valid owner query param required' });

    const rpcUrl = process.env.SEPOLIA_RPC_URL;
    const vaAddr = process.env.RWA_VERIFIED_ASSETS as `0x${string}`;
    if (!rpcUrl) throw new Error('Missing SEPOLIA_RPC_URL');
    if (!vaAddr) throw new Error('Missing RWA_VERIFIED_ASSETS');

    const pub = createPublicClient({ chain: sepolia, transport: http(rpcUrl) });
    const data = await pub.readContract({ address: vaAddr, abi: rwaVerifiedAssetsAbi, functionName: 'getVerifiedAssets', args: [owner as `0x${string}`] });
    // Normalize BigInt fields for JSON
    const assets = (data as any[]).map((a: any) => ({
      assetType: typeof a.assetType === 'bigint' ? Number(a.assetType) : a.assetType,
      assetName: a.assetName,
      assetId: typeof a.assetId === 'bigint' ? a.assetId.toString() : String(a.assetId),
      isLocked: a.isLocked,
      isVerified: a.isVerified,
      valueInUSD: typeof a.valueInUSD === 'bigint' ? a.valueInUSD.toString() : String(a.valueInUSD),
      owner: a.owner,
      tradable: a.tradable,
    }));
    res.json({ assets });
  } catch (e: any) {
    res.status(500).json({ error: e?.shortMessage || e?.message || 'list failed' });
  }
});

// Check if an address has MEMBER_ROLE (via isOwnerAllowed)
app.get('/assets/member', async (req: Request, res: Response) => {
  try {
    const addr = (req.query.addr as string) || '';
    if (!addr || !/^0x[0-9a-fA-F]{40}$/.test(addr)) return res.status(400).json({ error: 'valid addr query param required' });

    const rpcUrl = process.env.SEPOLIA_RPC_URL;
    const vaAddr = process.env.RWA_VERIFIED_ASSETS as `0x${string}`;
    if (!rpcUrl) throw new Error('Missing SEPOLIA_RPC_URL');
    if (!vaAddr) throw new Error('Missing RWA_VERIFIED_ASSETS');

    const pub = createPublicClient({ chain: sepolia, transport: http(rpcUrl) });
    const allowed = await pub.readContract({ address: vaAddr, abi: rwaVerifiedAssetsAbi, functionName: 'isOwnerAllowed', args: [addr as `0x${string}`] });
    res.json({ allowed });
  } catch (e: any) {
    res.status(500).json({ error: e?.shortMessage || e?.message || 'member check failed' });
  }
});

// Grant MEMBER_ROLE to an address so they can self-register assets
app.post('/assets/member/add', async (req: Request, res: Response) => {
  try {
    const { addr } = req.body as { addr?: string };
    if (!addr || !/^0x[0-9a-fA-F]{40}$/.test(addr)) return res.status(400).json({ error: 'valid addr required' });

    const pk = process.env.BACKEND_PRIVATE_KEY?.startsWith('0x') ? (process.env.BACKEND_PRIVATE_KEY as `0x${string}`) : (`0x${process.env.BACKEND_PRIVATE_KEY}` as `0x${string}`);
    const rpcUrl = process.env.SEPOLIA_RPC_URL;
    const vaAddr = process.env.RWA_VERIFIED_ASSETS as `0x${string}`;
    if (!pk || pk.length < 10) throw new Error('Missing BACKEND_PRIVATE_KEY');
    if (!rpcUrl) throw new Error('Missing SEPOLIA_RPC_URL');
    if (!vaAddr) throw new Error('Missing RWA_VERIFIED_ASSETS');

    const account = privateKeyToAccount(pk);
    const wallet = createWalletClient({ account, chain: sepolia, transport: http(rpcUrl) });
    const pub = createPublicClient({ chain: sepolia, transport: http(rpcUrl) });
    const txHash = await wallet.writeContract({ address: vaAddr, abi: rwaVerifiedAssetsAbi, functionName: 'addMember', args: [addr as `0x${string}`] });
    const receipt = await pub.waitForTransactionReceipt({ hash: txHash });
    const ok = (receipt as any)?.status === 'success' || (receipt as any)?.status === 1;
    res.json({ ok, txHash });
  } catch (e: any) {
    res.status(200).json({ ok: false, error: e?.shortMessage || e?.message || 'add member failed' });
  }
});

// Expose backend signer (registry) address for convenience when viewing assets
app.get('/assets/registry', async (_req: Request, res: Response) => {
  try {
    const pk = process.env.BACKEND_PRIVATE_KEY?.startsWith('0x') ? (process.env.BACKEND_PRIVATE_KEY as `0x${string}`) : (`0x${process.env.BACKEND_PRIVATE_KEY}` as `0x${string}`);
    if (!pk || pk.length < 10) throw new Error('Missing BACKEND_PRIVATE_KEY');
    const account = privateKeyToAccount(pk);
    res.json({ address: account.address });
  } catch (e: any) {
    res.status(500).json({ error: e?.message || 'registry failed' });
  }
});

// List ERC721 tokenIds received by an owner from RWA_NFT by scanning Transfer logs
app.get('/nft/tokensOf', async (req: Request, res: Response) => {
  try {
    const owner = (req.query.owner as string) || '';
    if (!owner || !/^0x[0-9a-fA-F]{40}$/.test(owner)) return res.status(400).json({ error: 'valid owner query param required' });

    const rpcUrl = process.env.SEPOLIA_RPC_URL;
    const nftAddr = process.env.RWA_NFT as `0x${string}`;
    if (!rpcUrl) throw new Error('Missing SEPOLIA_RPC_URL');
    if (!nftAddr) throw new Error('Missing RWA_NFT');

    const pub = createPublicClient({ chain: sepolia, transport: http(rpcUrl) });
    const head = await pub.getBlockNumber();
    const range: bigint = 200_000n; // adjust if needed
    const fromBlock = head > range ? head - range : 0n;

    const transferEvent = parseAbiItem('event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)');
    const logs = await pub.getLogs({ address: nftAddr, fromBlock, toBlock: head, event: transferEvent, args: { to: owner as `0x${string}` } });
    const seen = new Set<string>();
    const candidateIds = logs.map((l: any) => (l.args?.tokenId ? (l.args.tokenId as bigint).toString() : '0')).filter((s: string) => s !== '0');
    const unique = Array.from(new Set(candidateIds));
    const finalIds: string[] = [];
    for (const id of unique) {
      try {
        const currentOwner = await pub.readContract({ address: nftAddr, abi: rwaNftAbi, functionName: 'ownerOf', args: [BigInt(id)] });
        if ((currentOwner as string).toLowerCase() === owner.toLowerCase()) {
          if (!seen.has(id)) { seen.add(id); finalIds.push(id); }
        }
      } catch {
        // ignore tokens that error (burned/nonexistent)
      }
    }
    res.json({ tokenIds: finalIds });
  } catch (e: any) {
    res.status(500).json({ error: e?.shortMessage || e?.message || 'tokensOf failed' });
  }
});

const port = process.env.PORT || 8787;
app.listen(port, () => {
  const missing = [
    ['SEPOLIA_RPC_URL', process.env.SEPOLIA_RPC_URL],
    ['BACKEND_PRIVATE_KEY', process.env.BACKEND_PRIVATE_KEY],
    ['RWA_MANAGER', process.env.RWA_MANAGER],
    ['RWA_VERIFIED_ASSETS', process.env.RWA_VERIFIED_ASSETS],
    ['RWA_NFT', process.env.RWA_NFT],
  ].filter(([, v]) => !v);
  console.log(`zenith-server listening on http://localhost:${port}`);
  if (missing.length) {
    console.warn('Missing env:', missing.map(([k]) => k).join(', '), '— copy server/.env.example to server/.env and fill values.');
  }
});
