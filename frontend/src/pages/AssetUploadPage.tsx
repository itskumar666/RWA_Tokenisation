import { useState } from 'react';
import { useAccount } from 'wagmi';
import { BACKEND_URL } from '../config';

export default function AssetUploadPage() {
  const { address } = useAccount();
  const [files, setFiles] = useState<FileList | null>(null);
  const [assetType, setAssetType] = useState('');
  const [assetName, setAssetName] = useState('');
  const [valueUSD, setValueUSD] = useState('');
  const [ownerEcho, setOwnerEcho] = useState('');
  const [isLocked, setIsLocked] = useState(false);
  const [assetId, setAssetId] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [txHash, setTxHash] = useState<string | null>(null);
  const [submittingRegister, setSubmittingRegister] = useState(false);
  const [submittingDeregister, setSubmittingDeregister] = useState(false);
  const [submittingUpdate, setSubmittingUpdate] = useState(false);
  // state for management
  const [dgOwner, setDgOwner] = useState('');
  const [dgAssetId, setDgAssetId] = useState('');
  const [updOwner, setUpdOwner] = useState('');
  const [updAssetId, setUpdAssetId] = useState('');
  const [updValue, setUpdValue] = useState('');
  const [updLocked, setUpdLocked] = useState(false);
  const [updTradable, setUpdTradable] = useState(false);


  async function registerViaBackend() {
  setError(null);
  setSubmittingRegister(true);
    setTxHash(null);
    setAssetId(null);
  // no IPFS in this flow
    try {
  if (!files || files.length === 0) throw new Error('Choose at least one file');
      const body = new FormData();
  Array.from(files).forEach(f => body.append('files', f));
      body.append('assetType', assetType);
      body.append('assetName', assetName);
      body.append('valueUSD', valueUSD);
  if (ownerEcho || address) body.append('owner', (ownerEcho || address) as string);
  body.append('isLocked', isLocked ? 'true' : 'false');
  const resp = await fetch(`${BACKEND_URL}/assets/register`, { method: 'POST', body });
      const json = await resp.json();
      if (!resp.ok) throw new Error(json?.error || 'Register failed');
      setAssetId(json.assetId ?? null);
  setTxHash(json.txHash ?? null);
    } catch (e: any) {
      setError(e?.message || 'Register error');
    } finally {
      setSubmittingRegister(false);
    }
  }

  async function deregister() {
  setError(null);
  setSubmittingDeregister(true);
    try {
      const body = new URLSearchParams();
      body.set('owner', dgOwner || address || '');
      body.set('assetId', dgAssetId);
      const resp = await fetch(`${BACKEND_URL}/assets/deregister`, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body });
      const json = await resp.json();
      if (!resp.ok) throw new Error(json?.error || 'Deregister failed');
      setTxHash(json.txHash ?? null);
    } catch (e: any) {
      setError(e?.message || 'Deregister error');
    } finally {
      setSubmittingDeregister(false);
    }
  }

  async function updateValue() {
  setError(null);
  setSubmittingUpdate(true);
    try {
      const body = new URLSearchParams();
      body.set('owner', updOwner || address || '');
      body.set('assetId', updAssetId);
      body.set('newValueUSD', updValue);
      body.set('isLocked', updLocked ? 'true' : 'false');
      body.set('tradable', updTradable ? 'true' : 'false');
      const resp = await fetch(`${BACKEND_URL}/assets/update`, { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body });
      const json = await resp.json();
      if (!resp.ok) throw new Error(json?.error || 'Update failed');
      setTxHash(json.txHash ?? null);
    } catch (e: any) {
      setError(e?.message || 'Update error');
    } finally {
      setSubmittingUpdate(false);
    }
  }

  return (
    <div>
        <h3>This page is supposed to be used by members only and admin but for testing purpose i have unlocked it for now It deduct eth from my wallet so use it once or twice for testing Thank you</h3>
  <h4>Register asset</h4>
      <div className="input-row">
        <input type="file" multiple onChange={e => setFiles(e.target.files)} />
      </div>

      <h5 className="mt-3">Asset Details</h5>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
        <input placeholder="Asset Type (0..3)" value={assetType} onChange={e => setAssetType(e.target.value)} />
        <input placeholder="Asset Name" value={assetName} onChange={e => setAssetName(e.target.value)} />
        <input placeholder="Value (USD)" value={valueUSD} onChange={e => setValueUSD(e.target.value)} />
        <input placeholder="Owner Echo (optional)" value={ownerEcho} onChange={e => setOwnerEcho(e.target.value)} />
        <h6>Asset type- 0:House, 1:Car, 2:Art, 3:Collectible</h6>
      </div>
      <div className="mt-2" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <label style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <input type="checkbox" checked={isLocked} onChange={e => setIsLocked(e.target.checked)} />
          <span>Lock Asset</span>
        </label>
      </div>
      <div className="mt-2">
  <button disabled={!files || files.length === 0 || submittingRegister} onClick={registerViaBackend}>{submittingRegister ? 'Submitting…' : 'Register'}</button>
      </div>
      {assetId !== null && <p>Asset ID: {assetId}</p>}

      <hr className="mt-4" />
      <h5>Deregister Asset</h5>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
        <input placeholder="Owner" value={dgOwner} onChange={e => setDgOwner(e.target.value)} />
        <input placeholder="Asset ID" value={dgAssetId} onChange={e => setDgAssetId(e.target.value)} />
      </div>
      <div className="mt-2">
  <button disabled={!dgAssetId || submittingDeregister} onClick={deregister}>{submittingDeregister ? 'Submitting…' : 'Deregister'}</button>
      </div>

      <hr className="mt-4" />
      <h5>Update Asset Value</h5>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
        <input placeholder="Owner" value={updOwner} onChange={e => setUpdOwner(e.target.value)} />
        <input placeholder="Asset ID" value={updAssetId} onChange={e => setUpdAssetId(e.target.value)} />
        <input placeholder="New Value (USD)" value={updValue} onChange={e => setUpdValue(e.target.value)} />
        <label style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <input type="checkbox" checked={updLocked} onChange={e => setUpdLocked(e.target.checked)} />
          <span>Locked</span>
        </label>
        <label style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <input type="checkbox" checked={updTradable} onChange={e => setUpdTradable(e.target.checked)} />
          <span>Tradable</span>
        </label>
      </div>
      <div className="mt-2">
  <button disabled={!updAssetId || !updValue || submittingUpdate} onClick={updateValue}>{submittingUpdate ? 'Submitting…' : 'Update Value'}</button>
      </div>
  {error && <p style={{ color: 'crimson' }}>{error}</p>}
    </div>
  );
}
