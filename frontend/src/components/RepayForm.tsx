import { useState } from 'react';
import { useAccount, useReadContract, useWaitForTransactionReceipt, useWriteContract } from 'wagmi';
import { parseUnits } from 'viem';
import { addresses } from '../addresses';
import { lendingManagerAbi } from '../abi/lendingManager';
import { erc20Abi } from '../abi/erc20';

export function RepayForm() {
  const { address } = useAccount();
  const [lender, setLender] = useState('');
  const [amount, setAmount] = useState('');
  const [tokenId, setTokenId] = useState('');
  const manager = addresses.lendingManager as `0x${string}`;
  const rwac = addresses.rwaCoins as `0x${string}`;

  const { data: allow } = useReadContract({
    address: rwac,
    abi: erc20Abi,
    functionName: 'allowance',
    args: [address ?? '0x0000000000000000000000000000000000000000', manager],
    query: { enabled: !!address },
  });

  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const needApprove = (() => {
    if (!amount || typeof allow !== 'bigint') return true;
    try { return allow < parseUnits(amount, 18); } catch { return true; }
  })();

  return (
    <div style={{ border: '1px solid #ddd', padding: 12, borderRadius: 8 }}>
      <h4>Repay</h4>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
        <input placeholder="Lender Address" value={lender} onChange={e => setLender(e.target.value)} />
        <input placeholder="Amount (RWAC)" value={amount} onChange={e => setAmount(e.target.value)} />
        <input placeholder="NFT TokenId" value={tokenId} onChange={e => setTokenId(e.target.value)} />
      </div>
      <div style={{ marginTop: 8, display: 'flex', gap: 8 }}>
        {needApprove ? (
          <button disabled={!address || isPending}
            onClick={() => writeContract({ address: rwac, abi: erc20Abi, functionName: 'approve', args: [manager, parseUnits(amount || '0', 18)] })}>
            {isPending ? 'Approving...' : 'Approve'}
          </button>
        ) : (
          <button disabled={!address || isPending}
            onClick={() => writeContract({
              address: manager, abi: lendingManagerAbi, functionName: 'returnCoinToLender',
              args: [lender as `0x${string}`, parseUnits(amount || '0', 18), BigInt(tokenId || '0')]
            })}>
            {isPending ? 'Submitting...' : 'Repay'}
          </button>
        )}
      </div>
      {hash && <p>Tx: {hash}</p>}
      {isConfirming && <p>Waiting for confirmation...</p>}
      {isSuccess && <p>Success!</p>}
    </div>
  );
}
