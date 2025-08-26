import { useEffect, useMemo, useState } from 'react';
import { useAccount, useReadContract, useWaitForTransactionReceipt, useWriteContract } from 'wagmi';
import { formatUnits, parseUnits } from 'viem';
import { addresses } from '../addresses';
import { auctionHouseAbi } from '../abi/auctionHouse';
import { erc20Abi } from '../abi/erc20';

export function AuctionHousePanel() {
  const { address } = useAccount();
  const ah = addresses.auctionHouse as `0x${string}`;
  const rwac = addresses.rwaCoins as `0x${string}`;
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const { data: active } = useReadContract({ address: ah, abi: auctionHouseAbi, functionName: 'getActiveAuctions' });
  const { data: expired } = useReadContract({ address: ah, abi: auctionHouseAbi, functionName: 'getExpiredAuctions' });

  const [tokenId, setTokenId] = useState('');
  const [bidAmount, setBidAmount] = useState('');

  const { data: allow } = useReadContract({ address: rwac, abi: erc20Abi, functionName: 'allowance', args: [address ?? '0x0000000000000000000000000000000000000000', ah], query: { enabled: !!address } });
  const needApprove = useMemo(() => {
    if (!bidAmount || typeof allow !== 'bigint') return true;
    try { return allow < parseUnits(bidAmount, 18); } catch { return true; }
  }, [allow, bidAmount]);

  const { data: auction } = useReadContract({
    address: ah,
    abi: auctionHouseAbi,
    functionName: 'getAuction',
    args: [tokenId ? BigInt(tokenId) : 0n],
    query: { enabled: !!tokenId },
  });

  return (
    <div style={{ border: '1px solid #ddd', padding: 12, borderRadius: 8 }}>
      <h4>Auction House</h4>
      <div style={{ marginBottom: 8 }}>
        <h5>Bid on NFT</h5>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          <input placeholder="Token ID" value={tokenId} onChange={e => setTokenId(e.target.value)} />
          <input placeholder="Bid (RWAC)" value={bidAmount} onChange={e => setBidAmount(e.target.value)} />
        </div>
        <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
          {needApprove ? (
            <button disabled={!address || isPending}
              onClick={() => writeContract({ address: rwac, abi: erc20Abi, functionName: 'approve', args: [ah, parseUnits(bidAmount || '0', 18)] })}>
              {isPending ? 'Approving…' : 'Approve RWAC'}
            </button>
          ) : (
            <button disabled={!address || isPending}
              onClick={() => writeContract({ address: ah, abi: auctionHouseAbi, functionName: 'bidOnNFT', args: [BigInt(tokenId || '0'), parseUnits(bidAmount || '0', 18)] })}>
              {isPending ? 'Bidding…' : 'Bid'}
            </button>
          )}
          <button disabled={!address || isPending}
            onClick={() => writeContract({ address: ah, abi: auctionHouseAbi, functionName: 'endAuction', args: [BigInt(tokenId || '0')] })}>
            End Auction
          </button>
        </div>
        {auction && (
          <div style={{ marginTop: 8, padding: 8, background: '#fafafa', border: '1px solid #eee', borderRadius: 6 }}>
            <div>Starting: {formatUnits((auction as any).startingPrice, 18)} RWAC</div>
            <div>Highest: {formatUnits((auction as any).highestBid, 18)} RWAC</div>
            <div>Highest Bidder: {(auction as any).highestBidder}</div>
            <div>Ends: {new Date(Number((auction as any).endTime) * 1000).toLocaleString()}</div>
          </div>
        )}
      </div>

      <div style={{ marginTop: 12 }}>
        <h5>Active Auctions</h5>
        {Array.isArray(active) && active.length > 0 ? (
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {active.map((t: any, i: number) => (
              <button key={i} onClick={() => setTokenId(String(t))}>Token #{String(t)}</button>
            ))}
          </div>
        ) : <small>None</small>}
      </div>

      <div style={{ marginTop: 12 }}>
        <h5>Expired Auctions</h5>
        {Array.isArray(expired) && expired.length > 0 ? (
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {expired.map((t: any, i: number) => (
              <span key={i}>#{String(t)}</span>
            ))}
          </div>
        ) : <small>None</small>}
      </div>

      {hash && <p>Tx: {hash}</p>}
      {isConfirming && <p>Waiting for confirmation…</p>}
      {isSuccess && <p>Success!</p>}
      {error && <p style={{ color: 'crimson' }}>{(error as any)?.shortMessage || error.message}</p>}
    </div>
  );
}
