import { useMemo, useState } from 'react';
import { useAccount, useReadContract, useWaitForTransactionReceipt, useWriteContract } from 'wagmi';
import { parseEther, parseUnits, formatUnits } from 'viem';
import { addresses } from '../addresses';
import { rwaManagerAbi } from '../abi/rwaManager';
import { erc20Abi } from '../abi/erc20';
import { erc721Abi } from '../abi/erc721';

export function RwaManagerPanel() {
  const { address } = useAccount();
  const manager = addresses.rwaManager as `0x${string}`;
  const rwac = addresses.rwaCoins as `0x${string}`;

  // Shared tx state
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });
  const { data: memberRole } = useReadContract({ address: manager, abi: rwaManagerAbi, functionName: 'MEMBER_ROLE' });
  const { data: isMember } = useReadContract({
    address: manager,
    abi: rwaManagerAbi,
    functionName: 'hasRole',
    args: [memberRole as any, address ?? '0x0000000000000000000000000000000000000000'],
    query: { enabled: !!address && !!memberRole },
  });
  const { data: contractEth } = useReadContract({ address: manager, abi: rwaManagerAbi, functionName: 'getContractEthBalance' });
  const { data: contractCoin } = useReadContract({ address: manager, abi: rwaManagerAbi, functionName: 'getContractCoinBalance' });

  // Mint RWA flow
  const [requestId, setRequestId] = useState('');
  const [assetValue, setAssetValue] = useState('');
  const [assetOwner, setAssetOwner] = useState('');
  const [tokenUri, setTokenUri] = useState('');

  // Tradable
  const [tradTokenId, setTradTokenId] = useState('');
  const [tradRequestId, setTradRequestId] = useState('');
  const [tradAmount, setTradAmount] = useState('');

  // Burn/Withdraw
  const [burnTokenId, setBurnTokenId] = useState('');
  const [burnRequestId, setBurnRequestId] = useState('');
  const nftAddr = addresses.rwaNft as `0x${string}`;
  const { data: nftApproved } = useReadContract({
    address: nftAddr,
    abi: erc721Abi,
    functionName: 'isApprovedForAll',
    args: [address ?? '0x0000000000000000000000000000000000000000', manager],
    query: { enabled: !!address },
  });
  const { data: rwacAllow } = useReadContract({
    address: rwac,
    abi: erc20Abi,
    functionName: 'allowance',
    args: [address ?? '0x0000000000000000000000000000000000000000', manager],
    query: { enabled: !!address },
  });
  const { data: userAsset } = useReadContract({
    address: manager,
    abi: rwaManagerAbi,
    functionName: 'getUserAssetInfo',
    args: [address ?? '0x0000000000000000000000000000000000000000', burnRequestId ? BigInt(burnRequestId) : 0n],
    query: { enabled: !!address && !!burnRequestId },
  });
  const burnNeeded: bigint | undefined = (userAsset as any)?.valueInUSD;
  const needApproveWithdraw = useMemo(() => {
    if (!burnNeeded || typeof rwacAllow !== 'bigint') return true;
    return rwacAllow < burnNeeded;
  }, [rwacAllow, burnNeeded]);

  // Update value
  const [updTo, setUpdTo] = useState('');
  const [updRequestId, setUpdRequestId] = useState('');
  const [updValue, setUpdValue] = useState('');

  // Update image
  const [imgRequestId, setImgRequestId] = useState('');
  const [imgTokenId, setImgTokenId] = useState('');
  const [imgUri, setImgUri] = useState('');

  // Mint against ETH
  const [mintEthTo, setMintEthTo] = useState('');
  const [mintEthAmount, setMintEthAmount] = useState('');

  // Admin
  const [newMember, setNewMember] = useState('');
  const [rmMember, setRmMember] = useState('');
  const [newEthPrice, setNewEthPrice] = useState('');
  const [wdTo, setWdTo] = useState('');
  const [wdAmount, setWdAmount] = useState('');

  // Allowance for tradability flow
  const { data: allow } = useReadContract({
    address: rwac,
    abi: erc20Abi,
    functionName: 'allowance',
    args: [address ?? '0x0000000000000000000000000000000000000000', manager],
    query: { enabled: !!address },
  });

  const needApprove = useMemo(() => {
    if (!tradAmount || typeof allow !== 'bigint') return true;
    try { return allow < parseUnits(tradAmount, 18); } catch { return true; }
  }, [allow, tradAmount]);

  return (
    <div>
      <h4>RWA Manager</h4>

      {/* Mint: depositRWAAndMintNFT */}
      <div style={{ marginBottom: 12 }}>
        <h5>Deposit + Mint NFT & Coins</h5>
        <small style={{ color: '#666' }}>Direct contract call - no member role required</small>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          <input placeholder="Request ID" value={requestId} onChange={e => setRequestId(e.target.value)} />
          <input placeholder="Asset Value (USD)" value={assetValue} onChange={e => setAssetValue(e.target.value)} />
          <input placeholder="Asset Owner" value={assetOwner} onChange={e => setAssetOwner(e.target.value)} />
          <input placeholder="Token URI (metadata)" value={tokenUri} onChange={e => setTokenUri(e.target.value)} />
        </div>
        <div style={{ marginTop: 8 }}>
          <button
            disabled={!address || isPending}
            onClick={() => {
              const owner = (assetOwner || address) as `0x${string}`;
              const uri = tokenUri || `asset-${requestId || '0'}`;
              writeContract({
                address: manager,
                abi: rwaManagerAbi,
                functionName: 'depositRWAAndMintNFT',
                args: [BigInt(requestId || '0'), BigInt(assetValue || '0'), owner, uri],
              });
            }}
          >
            {isPending ? 'Minting...' : 'Mint NFT & Coins'}
          </button>
        </div>
      </div>

      {/* Change tradable: requires burning coins = valueInUSD */}
      <div style={{ marginBottom: 12 }}>
        <h5>Make NFT Tradable (burn coins)</h5>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          <input placeholder="Token ID" value={tradTokenId} onChange={e => setTradTokenId(e.target.value)} />
          <input placeholder="Request ID" value={tradRequestId} onChange={e => setTradRequestId(e.target.value)} />
          <input placeholder="Token Amount (RWAC to burn)" value={tradAmount} onChange={e => setTradAmount(e.target.value)} />
        </div>
        <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
          {needApprove ? (
            <button disabled={!address || isPending}
              onClick={() => writeContract({ address: rwac, abi: erc20Abi, functionName: 'approve', args: [manager, parseUnits(tradAmount || '0', 18)] })}>
              {isPending ? 'Approving…' : 'Approve RWAC'}
            </button>
          ) : (
            <button disabled={!address || isPending}
              onClick={() => writeContract({ address: manager, abi: rwaManagerAbi, functionName: 'changeNftTradable', args: [BigInt(tradTokenId || '0'), BigInt(tradRequestId || '0'), parseUnits(tradAmount || '0', 18)] })}>
              {isPending ? 'Submitting…' : 'Make Tradable'}
            </button>
          )}
        </div>
      </div>

      {/* Withdraw + burn */}
      <div style={{ marginBottom: 12 }}>
        <h5>Withdraw RWA (burn NFT & coins)</h5>
        <div style={{ padding: 8, background: '#fafafa', border: '1px solid #eee', borderRadius: 6, marginBottom: 8 }}>
          <p style={{ margin: 0 }}>NFT Approval for Manager: {nftApproved ? 'Approved' : 'Not approved'}</p>
          {!nftApproved && (
            <button style={{ marginTop: 6 }} disabled={!address || isPending}
              onClick={() => writeContract({ address: nftAddr, abi: erc721Abi, functionName: 'setApprovalForAll', args: [manager, true] })}>
              {isPending ? 'Approving…' : 'Approve NFT to Manager'}
            </button>
          )}
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          <input placeholder="Token ID" value={burnTokenId} onChange={e => setBurnTokenId(e.target.value)} />
          <input placeholder="Request ID" value={burnRequestId} onChange={e => setBurnRequestId(e.target.value)} />
        </div>
        <div style={{ marginTop: 8, display: 'flex', gap: 8, alignItems: 'center' }}>
          {!nftApproved && (
            <button disabled={!address || isPending}
              onClick={() => writeContract({ address: nftAddr, abi: erc721Abi, functionName: 'setApprovalForAll', args: [manager, true] })}>
              {isPending ? 'Approving NFT…' : 'Approve NFT'}
            </button>
          )}
          {needApproveWithdraw ? (
            <button disabled={!address || isPending}
              onClick={() => writeContract({ address: rwac, abi: erc20Abi, functionName: 'approve', args: [manager, burnNeeded ?? 0n] })}>
              {isPending ? 'Approving RWAC…' : 'Approve RWAC'}
            </button>
          ) : (
            <button disabled={!address || isPending}
              onClick={() => writeContract({ address: manager, abi: rwaManagerAbi, functionName: 'withdrawRWAAndBurnNFTandCoin', args: [BigInt(burnTokenId || '0'), BigInt(burnRequestId || '0')] })}>
              {isPending ? 'Burning…' : 'Withdraw & Burn'}
            </button>
          )}
          {typeof burnNeeded === 'bigint' && <small>Required burn: {formatUnits(burnNeeded, 18)} RWAC</small>}
        </div>
      </div>

      {/* View asset info */}
      <div style={{ marginBottom: 12 }}>
        <h5>View Asset Info</h5>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          <input placeholder="Request ID" value={updRequestId} onChange={e => setUpdRequestId(e.target.value)} />
        </div>
        <div style={{ marginTop: 8 }}>
          {updRequestId ? (
            <AssetInfo _requestId={updRequestId} />
          ) : (
            <small>Enter a Request ID to query.</small>
          )}
        </div>
      </div>

      {/* Tradability check */}
      <div style={{ marginBottom: 12 }}>
        <h5>Check Tradability</h5>
        <TradableCheck />
      </div>

      {/* Contract balances */}
      <div style={{ marginBottom: 12, padding: 8, background: '#fafafa', border: '1px solid #eee', borderRadius: 6 }}>
        <h5>Contract Balances</h5>
        <div>ETH: {typeof contractEth === 'bigint' ? formatUnits(contractEth, 18) : '0'} ETH</div>
        <div>RWAC: {typeof contractCoin === 'bigint' ? formatUnits(contractCoin, 18) : '0'} RWAC</div>
      </div>

      {/* Global asset info by Request ID (no user) */}
      <div style={{ marginBottom: 12 }}>
        <h5>Global Asset Info (by Request ID)</h5>
        <GlobalAssetInfo />
      </div>

      {/* Update value */}
      <div style={{ marginBottom: 12 }}>
        <h5>Update Asset Value</h5>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          <input placeholder="User (owner)" value={updTo} onChange={e => setUpdTo(e.target.value)} />
          <input placeholder="Request ID" value={updRequestId} onChange={e => setUpdRequestId(e.target.value)} />
          <input placeholder="New Value (USD)" value={updValue} onChange={e => setUpdValue(e.target.value)} />
        </div>
        <div style={{ marginTop: 8 }}>
          <button disabled={!address || isPending}
            onClick={() => writeContract({ address: manager, abi: rwaManagerAbi, functionName: 'updateAssetValue', args: [(updTo || address) as `0x${string}`, BigInt(updRequestId || '0'), BigInt(updValue || '0')] })}>
            {isPending ? 'Updating…' : 'Update'}
          </button>
        </div>
      </div>

      {/* Update image URI */}
      <div style={{ marginBottom: 12 }}>
        <h5>Update Asset Image URI</h5>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          <input placeholder="Request ID" value={imgRequestId} onChange={e => setImgRequestId(e.target.value)} />
          <input placeholder="Token ID" value={imgTokenId} onChange={e => setImgTokenId(e.target.value)} />
          <input placeholder="New Image URI" value={imgUri} onChange={e => setImgUri(e.target.value)} />
        </div>
        <div style={{ marginTop: 8 }}>
          <button disabled={!address || isPending}
            onClick={() => writeContract({ address: manager, abi: rwaManagerAbi, functionName: 'updateAssetImageUri', args: [BigInt(imgRequestId || '0'), BigInt(imgTokenId || '0'), imgUri] })}>
            {isPending ? 'Saving…' : 'Save Image URI'}
          </button>
        </div>
      </div>

      {/* Mint coins vs ETH */}
      <div style={{ marginBottom: 12 }}>
        <h5>Mint Coins Against ETH</h5>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          <input placeholder="Recipient" value={mintEthTo} onChange={e => setMintEthTo(e.target.value)} />
          <input placeholder="ETH amount" value={mintEthAmount} onChange={e => setMintEthAmount(e.target.value)} />
        </div>
        <div style={{ marginTop: 8 }}>
          <button disabled={!address || isPending}
            onClick={() => writeContract({ address: manager, abi: rwaManagerAbi, functionName: 'mintCoinAgainstEth', args: [(mintEthTo || address) as `0x${string}`], value: parseEther(mintEthAmount || '0') })}>
            {isPending ? 'Minting…' : 'Mint via ETH'}
          </button>
        </div>
      </div>

      {/* Admin actions */}
      <div style={{ marginBottom: 12 }}>
        <h5>Admin</h5>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          <input placeholder="New Member" value={newMember} onChange={e => setNewMember(e.target.value)} />
          <button disabled={!address || isPending} onClick={() => writeContract({ address: manager, abi: rwaManagerAbi, functionName: 'setNewMember', args: [newMember as `0x${string}`] })}>Add Member</button>
          <input placeholder="Remove Member" value={rmMember} onChange={e => setRmMember(e.target.value)} />
          <button disabled={!address || isPending} onClick={() => writeContract({ address: manager, abi: rwaManagerAbi, functionName: 'removeMember', args: [rmMember as `0x${string}`] })}>Remove</button>
          <input placeholder="New ETH Price (wei)" value={newEthPrice} onChange={e => setNewEthPrice(e.target.value)} />
          <button disabled={!address || isPending} onClick={() => writeContract({ address: manager, abi: rwaManagerAbi, functionName: 'updateEthPrice', args: [BigInt(newEthPrice || '0')] })}>Set Price</button>
          <input placeholder="Withdraw To" value={wdTo} onChange={e => setWdTo(e.target.value)} />
          <input placeholder="Withdraw Amount (wei)" value={wdAmount} onChange={e => setWdAmount(e.target.value)} />
          <button disabled={!address || isPending} onClick={() => writeContract({ address: manager, abi: rwaManagerAbi, functionName: 'withdraw', args: [wdTo as `0x${string}`, BigInt(wdAmount || '0')] })}>Withdraw ETH</button>
        </div>
      </div>

      {/* Status */}
      {hash && <p>Tx: {hash}</p>}
      {isConfirming && <p>Waiting for confirmation…</p>}
      {isSuccess && <p>Success!</p>}
      {error && <p style={{ color: 'crimson' }}>{(error as any)?.shortMessage || error.message}</p>}
    </div>
  );
}

function AssetInfo({ _requestId }: { _requestId: string }) {
  const manager = addresses.rwaManager as `0x${string}`;
  const { address } = useAccount();
  const { data } = useReadContract({
    address: manager,
    abi: rwaManagerAbi,
    functionName: 'getUserAssetInfo',
    args: [address ?? '0x0000000000000000000000000000000000000000', _requestId ? BigInt(_requestId) : 0n],
    query: { enabled: !!address && !!_requestId },
  });
  const info: any = data;
  if (!info) return null;
  return (
    <div style={{ padding: 8, background: '#fafafa', border: '1px solid #eee', borderRadius: 6 }}>
      <div>Asset Name: {info.assetName}</div>
      <div>Asset ID: {String(info.assetId)}</div>
      <div>Value (USD units): {String(info.valueInUSD)}</div>
      <div>Tradable: {String(info.tradable)}</div>
      <div>Locked: {String(info.isLocked)}</div>
    </div>
  );
}

function TradableCheck() {
  const manager = addresses.rwaManager as `0x${string}`;
  const { address } = useAccount();
  const [rid, setRid] = useState('');
  const { data } = useReadContract({
    address: manager,
    abi: rwaManagerAbi,
    functionName: 'checkIfAssetIsTradable',
    args: [address ?? '0x0000000000000000000000000000000000000000', rid ? BigInt(rid) : 0n],
    query: { enabled: !!address && !!rid },
  });
  return (
    <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
      <input placeholder="Request ID" value={rid} onChange={e => setRid(e.target.value)} />
      <div>Status: {data === undefined ? '-' : (data ? 'Tradable' : 'Not tradable')}</div>
    </div>
  );
}

function GlobalAssetInfo() {
  const [rid, setRid] = useState('');
  const manager = addresses.rwaManager as `0x${string}`;
  const { data: info1 } = useReadContract({
    address: manager,
    abi: rwaManagerAbi,
    functionName: 'getUserRWAInfo',
    args: [rid ? BigInt(rid) : 0n],
    query: { enabled: !!rid },
  });
  const { data: info2 } = useReadContract({
    address: manager,
    abi: rwaManagerAbi,
    functionName: 'getUserRWAInfoagainstRequestId',
    args: [rid ? BigInt(rid) : 0n],
    query: { enabled: !!rid },
  });
  const render = (label: string, info: any) => info ? (
    <div style={{ padding: 8, background: '#fafafa', border: '1px solid #eee', borderRadius: 6 }}>
      <strong>{label}</strong>
      <div>Asset Name: {info.assetName}</div>
      <div>Asset ID: {String(info.assetId)}</div>
      <div>Value (USD units): {String(info.valueInUSD)}</div>
      <div>Tradable: {String(info.tradable)}</div>
      <div>Locked: {String(info.isLocked)}</div>
      <div>Owner: {info.owner}</div>
    </div>
  ) : null;
  return (
    <div style={{ display: 'grid', gap: 8 }}>
      <input placeholder="Request ID" value={rid} onChange={e => setRid(e.target.value)} />
      {render('getUserRWAInfo', info1 as any)}
      {render('getUserRWAInfoagainstRequestId', info2 as any)}
    </div>
  );
}
