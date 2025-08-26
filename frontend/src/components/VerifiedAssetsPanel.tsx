import { useState } from 'react';
import { encodeAbiParameters, parseAbiParameters, isAddress } from 'viem';
import { useAccount, usePublicClient, useReadContract, useReadContracts, useWaitForTransactionReceipt, useWriteContract } from 'wagmi';
import { addresses } from '../addresses';
import { rwaVerifiedAssetsAbi } from '../abi/rwaVerifiedAssets';

export function VerifiedAssetsPanel() {
  const { address } = useAccount();
  const va = addresses.rwaVerifiedAssets as `0x${string}`;

  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const { data: memberRole } = useReadContract({ address: va, abi: rwaVerifiedAssetsAbi, functionName: 'MEMBER_ROLE' });
  const { data: isMember } = useReadContract({ address: va, abi: rwaVerifiedAssetsAbi, functionName: 'hasRole', args: [memberRole as any, address ?? '0x0000000000000000000000000000000000000000'], query: { enabled: !!address && !!memberRole } });

  // Register
  const [owner, setOwner] = useState('');
  const [assetType, setAssetType] = useState('0');
  const [assetName, setAssetName] = useState('');
  const [assetId, setAssetId] = useState('');
  const [isLocked, setIsLocked] = useState(false);
  const [valueUSD, setValueUSD] = useState('');
  const [ownerEcho, setOwnerEcho] = useState('');

  const ownerValid = !owner || isAddress(owner as `0x${string}`);
  const ownerEchoValid = !ownerEcho || isAddress(ownerEcho as `0x${string}`);
  const encoded = () => {
    // abi.encode(uint8,string,uint256,bool,uint256,address)
    try {
      return encodeAbiParameters(
        parseAbiParameters('uint8, string, uint256, bool, uint256, address'),
        [
          Number(assetType),
          assetName,
          BigInt(assetId || '0'),
          isLocked,
          BigInt(valueUSD || '0'),
          ((ownerEcho || owner || address) ?? '0x0000000000000000000000000000000000000000') as `0x${string}`,
        ],
      );
    } catch {
      return undefined;
    }
  };

  const { data: list } = useReadContract({ address: va, abi: rwaVerifiedAssetsAbi, functionName: 'getVerifiedAssets', args: [address ?? '0x0000000000000000000000000000000000000000'], query: { enabled: !!address } });

  return (
    <div>
      <h4>Verified Assets</h4>
      <small>Member: {isMember ? 'Yes' : 'No'}</small>

      <div className="mt-2">
        <h5>Register Asset</h5>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          <input placeholder="Owner" value={owner} onChange={e => setOwner(e.target.value)} />
          <input placeholder="Asset Type (0..3)" value={assetType} onChange={e => setAssetType(e.target.value)} />
          <input placeholder="Asset Name" value={assetName} onChange={e => setAssetName(e.target.value)} />
          <input placeholder="Asset ID" value={assetId} onChange={e => setAssetId(e.target.value)} />
          <label style={{ display: 'flex', gap: 6, alignItems: 'center' }}><input type="checkbox" checked={isLocked} onChange={e => setIsLocked(e.target.checked)} /> Locked</label>
          <input placeholder="Value (USD)" value={valueUSD} onChange={e => setValueUSD(e.target.value)} />
          <input placeholder="Owner echo (for encoded)" value={ownerEcho} onChange={e => setOwnerEcho(e.target.value)} />
        </div>
  <button disabled={!address || isPending || !encoded() || !ownerValid || !ownerEchoValid} onClick={() => writeContract({ address: va, abi: rwaVerifiedAssetsAbi, functionName: 'registerVerifiedAsset', args: [(owner || address) as `0x${string}`, encoded() as `0x${string}`] })}>{isPending ? 'Registering…' : 'Register'}</button>
  {(!ownerValid || !ownerEchoValid) && <div className="subtle mt-1">Enter valid Ethereum addresses (0x...). Leave blank to auto-fill.</div>}
      </div>

      <div className="mt-3">
        <h5>Deregister Asset</h5>
        <DeregisterForm />
      </div>

      <div className="mt-3">
        <h5>Update Value</h5>
        <UpdateValueForm />
      </div>

      <div className="mt-3">
        <h5>Your Verified Assets</h5>
        {Array.isArray(list) && list.length > 0 ? (
          <ul className="reset">
            {list.map((a: any, i: number) => (
              <li key={i} className="break">#{String(a.assetId)} {a.assetName} — USD: {String(a.valueInUSD)} — Tradable: {String(a.tradable)} — Locked: {String(a.isLocked)}</li>
            ))}
          </ul>
        ) : <small>None</small>}
      </div>

  <AdminMembers memberRole={memberRole as any} />

  {hash && <p className="mono break">Tx: {hash}</p>}
  {isConfirming && <p className="subtle">Waiting for confirmation…</p>}
      {isSuccess && <p>Success!</p>}
  {error && <p style={{ color: 'crimson' }}>{(error as any)?.shortMessage || (error as any)?.message}</p>}
    </div>
  );
}
function AdminMembers({ memberRole }: { memberRole?: `0x${string}` }) {
  const { address } = useAccount();
  const va = addresses.rwaVerifiedAssets as `0x${string}`;
  const publicClient = usePublicClient();
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });
  const [member, setMember] = useState('');
  const memberValid = isAddress(member as `0x${string}`);
  const { data: ownerAddress } = useReadContract({ address: va, abi: rwaVerifiedAssetsAbi, functionName: 'owner' });
  const [actionError, setActionError] = useState<string | null>(null);

  // Single check
  const [checkAddr, setCheckAddr] = useState('');
  const checkValid = isAddress(checkAddr as `0x${string}`);
  const { data: singleStatus } = useReadContract({
    address: va,
    abi: rwaVerifiedAssetsAbi,
    functionName: 'hasRole',
    args: [memberRole as any, (checkAddr || '0x0000000000000000000000000000000000000000') as `0x${string}`],
    query: { enabled: !!memberRole && checkValid },
  });

  // Bulk check
  const [bulkText, setBulkText] = useState('');
  const bulkList = Array.from(new Set(bulkText.split(/\s|,|\n|\r/).map(s => s.trim()).filter(s => s.length > 0)));
  const validBulk = bulkList.filter(a => isAddress(a as `0x${string}`));
  const bulkContracts = (validBulk || []).map(a => ({ address: va, abi: rwaVerifiedAssetsAbi, functionName: 'hasRole' as const, args: [memberRole as any, a as `0x${string}`] }));
  const { data: bulkStatuses } = useReadContracts({
    contracts: bulkContracts,
    allowFailure: true,
    query: { enabled: !!memberRole && validBulk.length > 0 },
  });

  async function ensureOwner(): Promise<boolean> {
    try {
      if (!address) {
        setActionError('Connect your wallet.');
        return false;
      }
      if (!publicClient) {
        setActionError('RPC client not ready.');
        return false;
      }
      const onchainOwner = await publicClient.readContract({ address: va, abi: rwaVerifiedAssetsAbi, functionName: 'owner' });
      const ok = String(onchainOwner).toLowerCase() === String(address).toLowerCase();
      if (!ok) setActionError('Only the contract owner can add or remove members.');
      return ok;
    } catch (e: any) {
      setActionError(e?.shortMessage || e?.message || 'Failed to verify owner on-chain.');
      return false;
    }
  }

  async function handleAdd() {
    setActionError(null);
    if (!memberValid) return;
    if (!(await ensureOwner())) return;
    writeContract({ address: va, abi: rwaVerifiedAssetsAbi, functionName: 'addMember', args: [member as `0x${string}`] });
  }

  async function handleRemove() {
    setActionError(null);
    if (!memberValid) return;
    if (!(await ensureOwner())) return;
    writeContract({ address: va, abi: rwaVerifiedAssetsAbi, functionName: 'removeMember', args: [member as `0x${string}`] });
  }
  return (
    <div className="mt-3">
      <h5>Admin: Members</h5>
      {ownerAddress && (
        <div className="input-row">
          <input readOnly value={ownerAddress as string} />
          <span className="subtle">Contract Owner</span>
        </div>
      )}
      <div className="input-row">
        <input placeholder="Member address" value={member} onChange={e => setMember(e.target.value)} />
        <button disabled={!address || isPending || !memberValid} onClick={handleAdd}>{isPending ? 'Adding…' : 'Add Member'}</button>
        <button disabled={!address || isPending || !memberValid} onClick={handleRemove}>{isPending ? 'Removing…' : 'Remove Member'}</button>
      </div>
      {actionError && <small className="subtle" style={{ color: 'orange' }}>{actionError}</small>}
      {!memberValid && member.length > 0 && <small className="subtle">Enter a valid 0x address.</small>}

      <div className="mt-2">
        <h5>Check Member Status</h5>
        <div className="input-row">
          <input placeholder="0xAddress" value={checkAddr} onChange={e => setCheckAddr(e.target.value)} />
          <span className="subtle">Status: {checkValid ? (singleStatus ? 'Member' : 'Not a member') : '—'}</span>
        </div>
      </div>

      <div className="mt-2">
        <h5>Bulk Check (paste addresses, comma/space/newline)</h5>
        <textarea rows={3} placeholder="0xabc..., 0xdef..." value={bulkText} onChange={e => setBulkText(e.target.value)} style={{ width: '100%' }} />
        {validBulk.length > 0 && (
          <ul className="reset mt-1">
            {validBulk.map((a, i) => (
              <li key={a} className="break">{a}: {bulkStatuses && bulkStatuses[i] && typeof (bulkStatuses[i] as any).result !== 'undefined' ? ((bulkStatuses[i] as any).result ? 'Member' : 'Not a member') : '—'}</li>
            ))}
          </ul>
        )}
      </div>
      {isConfirming && <small className="subtle">Confirming…</small>}
      {isSuccess && <small>Done</small>}
    </div>
  );
}

function DeregisterForm() {
  const { address } = useAccount();
  const va = addresses.rwaVerifiedAssets as `0x${string}`;
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });
  const [owner, setOwner] = useState('');
  const [assetId, setAssetId] = useState('');
  return (
    <div className="input-row">
      <input placeholder="Owner" value={owner} onChange={e => setOwner(e.target.value)} />
      <input placeholder="Asset ID" value={assetId} onChange={e => setAssetId(e.target.value)} />
      <button disabled={!address || isPending} onClick={() => writeContract({ address: va, abi: rwaVerifiedAssetsAbi, functionName: 'DeRegisterVerifiedAsset', args: [owner as `0x${string}`, BigInt(assetId||'0')] })}>{isPending ? 'Deregistering…' : 'Deregister'}</button>
      {isConfirming && <small>Confirming…</small>}
      {isSuccess && <small>Done</small>}
    </div>
  );
}

function UpdateValueForm() {
  const { address } = useAccount();
  const va = addresses.rwaVerifiedAssets as `0x${string}`;
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });
  const [owner, setOwner] = useState('');
  const [assetId, setAssetId] = useState('');
  const [newValue, setNewValue] = useState('');
  const [locked, setLocked] = useState(false);
  const [tradable, setTradable] = useState(true);
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
      <input placeholder="Owner" value={owner} onChange={e => setOwner(e.target.value)} />
      <input placeholder="Asset ID" value={assetId} onChange={e => setAssetId(e.target.value)} />
      <input placeholder="New Value (USD)" value={newValue} onChange={e => setNewValue(e.target.value)} />
      <label><input type="checkbox" checked={locked} onChange={e => setLocked(e.target.checked)} /> Locked</label>
      <label><input type="checkbox" checked={tradable} onChange={e => setTradable(e.target.checked)} /> Tradable</label>
      <button disabled={!address || isPending} onClick={() => writeContract({ address: va, abi: rwaVerifiedAssetsAbi, functionName: 'upDateAssetValue', args: [owner as `0x${string}`, BigInt(assetId||'0'), BigInt(newValue||'0'), locked, tradable] })}>{isPending ? 'Updating…' : 'Update'}</button>
      {isConfirming && <small>Confirming…</small>}
      {isSuccess && <small>Done</small>}
    </div>
  );
}
