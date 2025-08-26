import { useEffect, useState } from 'react';
import { useAccount } from 'wagmi';
import { BACKEND_URL } from '../config';

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

export default function ViewAssetsPage() {
  const { address } = useAccount();
  const [owner, setOwner] = useState('');
  const [assets, setAssets] = useState<Asset[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (address && !owner) setOwner(address);
  }, [address]);

  async function load() {
    setError(null);
    setLoading(true);
    try {
      if (!owner) throw new Error('owner required');
      const resp = await fetch(`${BACKEND_URL}/assets/list?owner=${owner}`);
      const json = await resp.json();
      if (!resp.ok) throw new Error(json?.error || 'load failed');
      setAssets(json.assets || []);
    } catch (e: any) {
      setError(e?.message || 'load error');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h4>View Assets</h4>
      <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
        <input placeholder="Owner address" value={owner} onChange={e => setOwner(e.target.value)} style={{ flex: 1 }} />
        <button onClick={load} disabled={!owner || loading}>{loading ? 'Loading…' : 'Load'}</button>
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
              <div><strong>Owner (struct):</strong> {a.owner}</div>
            </div>
          </div>
        ))}
        {!loading && assets.length === 0 && <p>No assets found.</p>}
      </div>
    </div>
  );
}
