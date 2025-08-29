import { useEffect, useMemo, useState } from 'react';
import { useAccount, usePublicClient, useWalletClient, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { BACKEND_URL } from '../config';
import { addresses } from '../addresses';
import { rwaManagerAbi } from '../abi/rwaManager';

type Asset = {
  assetType: number;
  assetName: string;
  assetId: string;
  isLocked: boolean;
  isVerified: boolean;
  valueInUSD: string;
  owner: string;
  tradable: boolean;
};
type AssetWithStatus = Asset & { minted?: boolean };

export default function ViewAssetsPage() {
  const { address, isConnected } = useAccount();
  const publicClient = usePublicClient();
  const { data: walletClient } = useWalletClient();
  const [assets, setAssets] = useState<AssetWithStatus[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [minting, setMinting] = useState<Record<string, boolean>>({});

  // Direct contract interaction
  const { writeContract, data: hash, isPending, error: contractError } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  async function loadMyAssets() {
    if (!address) return;
    setError(null);
    setLoading(true);
    try {
      // Get registry (mapping key) internally – we don't show this to the user.
      const regResp = await fetch(`${BACKEND_URL}/assets/registry`);
      const regJson = await regResp.json();
      if (!regResp.ok || !regJson?.address) throw new Error(regJson?.error || 'registry unavailable');

      // Load all assets under the registry and filter to my wallet as struct owner.
      const listResp = await fetch(`${BACKEND_URL}/assets/list?owner=${regJson.address}`);
      const listJson = await listResp.json();
      if (!listResp.ok) throw new Error(listJson?.error || 'load failed');
      const list: Asset[] = listJson.assets || [];
      const mine = list.filter(a => a.owner?.toLowerCase() === address.toLowerCase());

      // Fetch minted status per asset (non-blocking sequence to keep simple)
      const withStatus: AssetWithStatus[] = [];
      for (const a of mine) {
        try {
          const s = await fetch(`${BACKEND_URL}/manager/status?user=${address}&requestId=${a.assetId}`);
          const sj = await s.json();
          withStatus.push({ ...a, minted: !!sj?.minted });
        } catch {
          withStatus.push({ ...a, minted: undefined });
        }
      }
      setAssets(withStatus);
    } catch (e: any) {
      setError(e?.message || 'load error');
    } finally {
      setLoading(false);
    }
  }

  async function mintAsset(a: AssetWithStatus) {
    if (!address) return;
    setError(null);
    setMinting((m) => ({ ...m, [a.assetId]: true }));
    try {
      const tokenURI = `asset-${a.assetId}`;
      
      // Call contract directly instead of backend
      writeContract({
        address: addresses.rwaManager as `0x${string}`,
        abi: rwaManagerAbi,
        functionName: 'depositRWAAndMintNFT',
        args: [BigInt(a.assetId), BigInt(a.valueInUSD), address, tokenURI],
      });
      
    } catch (e: any) {
      setError(e?.message || 'mint failed');
      setMinting((m) => ({ ...m, [a.assetId]: false }));
    }
  }

  // Handle transaction success
  useEffect(() => {
    if (isSuccess) {
      // Refresh assets after successful mint
      loadMyAssets();
      // Reset minting state for all assets
      setMinting({});
    }
  }, [isSuccess]);

  // Handle contract errors
  useEffect(() => {
    if (contractError) {
      setError((contractError as any)?.shortMessage || contractError.message || 'Transaction failed');
      setMinting({});
    }
  }, [contractError]);

  useEffect(() => {
    if (isConnected) {
      // Auto-load when wallet connects/changes
      loadMyAssets();
    } else {
      setAssets([]);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [address, isConnected]);

  return (
    <div>
      <h4>My Verified Assets</h4>
      {!isConnected && <p>Connect your wallet to see your assets.</p>}
      <div style={{ marginTop: 8 }}>
        <button onClick={loadMyAssets} disabled={!isConnected || loading}>{loading ? 'Loading…' : 'Refresh'}</button>
      </div>
      {error && <p style={{ color: 'crimson' }}>{error}</p>}
      <div className="mt-3" style={{ display: 'grid', gap: 12 }}>
        {assets.map((a) => (
          <div key={`${a.owner}-${a.assetId}`} className="card">
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6 }}>
              <div><strong>ID:</strong> {a.assetId}</div>
              <div><strong>Type:</strong> {a.assetType}</div>
              <div><strong>Name:</strong> {a.assetName}</div>
              <div><strong>Value USD:</strong> {a.valueInUSD}</div>
              <div><strong>Locked:</strong> {String(a.isLocked)}</div>
              <div><strong>Verified:</strong> {String(a.isVerified)}</div>
              <div><strong>Tradable:</strong> {String(a.tradable)}</div>
              <div><strong>Minted:</strong> {a.minted === undefined ? '—' : String(a.minted)}</div>
              {!a.minted && (
                <div style={{ gridColumn: '1 / -1', marginTop: 6 }}>
                  <button 
                    onClick={() => mintAsset(a)} 
                    disabled={minting[a.assetId] || !isConnected || isPending || isConfirming}
                  >
                    {isPending ? 'Confirming Transaction...' : 
                     isConfirming ? 'Waiting for Confirmation...' : 
                     minting[a.assetId] ? 'Minting…' : 'Mint NFT & Coins'}
                  </button>
                </div>
              )}
            </div>
          </div>
        ))}
        {!loading && isConnected && assets.length === 0 && <p>No assets found for your wallet.</p>}
      </div>
      
      {/* Transaction Status */}
      {hash && (
        <div style={{ marginTop: 12, padding: 8, background: '#f0f8ff', border: '1px solid #cce7ff', borderRadius: 6 }}>
          <p><strong>Transaction:</strong> {hash}</p>
          {isConfirming && <p>⏳ Waiting for confirmation...</p>}
          {isSuccess && <p style={{ color: 'green' }}>✅ Transaction successful!</p>}
        </div>
      )}
    </div>
  );
}
