import { useState } from 'react';
import { useAccount, useReadContract, useWaitForTransactionReceipt, useWriteContract } from 'wagmi';
import { parseUnits } from 'viem';
import { addresses } from '../addresses';
import { lendingManagerAbi } from '../abi/lendingManager';
import { erc721Abi } from '../abi/erc721';

export function BorrowForm() {
  const { address } = useAccount();
  const [amount, setAmount] = useState('');
  const [tokenId, setTokenId] = useState('');
  const [lender, setLender] = useState('');
  const [assetId, setAssetId] = useState('');
  const manager = addresses.lendingManager as `0x${string}`;
  const nft = addresses.rwaNft as `0x${string}`;
  const nftVault = addresses.nftVault as `0x${string}`;
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });
  const { data: approved } = useReadContract({
    address: nft,
    abi: erc721Abi,
    functionName: 'isApprovedForAll',
    args: [address ?? '0x0000000000000000000000000000000000000000', nftVault],
    query: { enabled: !!address },
  });

  return (
    <div style={{ border: '1px solid #ddd', padding: 12, borderRadius: 8 }}>
      <h4>Borrow</h4>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
        <input placeholder="Amount (RWAC)" value={amount} onChange={e => setAmount(e.target.value)} />
        <input placeholder="NFT TokenId" value={tokenId} onChange={e => setTokenId(e.target.value)} />
        <input placeholder="Lender Address" value={lender} onChange={e => setLender(e.target.value)} />
        <input placeholder="AssetId" value={assetId} onChange={e => setAssetId(e.target.value)} />
      </div>
      <div style={{ marginTop: 8, display: 'flex', gap: 8 }}>
        {!approved ? (
          <button disabled={!address || isPending}
            onClick={() => writeContract({ address: nft, abi: erc721Abi, functionName: 'setApprovalForAll', args: [nftVault, true] })}>
            {isPending ? 'Approving NFT...' : 'Approve NFT'}
          </button>
        ) : null}
        <button disabled={!address || isPending}
          onClick={() => writeContract({
            address: manager, abi: lendingManagerAbi, functionName: 'borrowCoin',
            args: [parseUnits(amount || '0', 18), BigInt(tokenId || '0'), lender as `0x${string}`, BigInt(assetId || '0')]
          })}>
          {isPending ? 'Submitting...' : 'Borrow'}
        </button>
      </div>
      {hash && <p>Tx: {hash}</p>}
      {isConfirming && <p>Waiting for confirmation...</p>}
      {isSuccess && <p>Success!</p>}
    </div>
  );
}
