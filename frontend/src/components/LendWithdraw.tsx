import { useState } from 'react';
import { useAccount, useWaitForTransactionReceipt, useWriteContract } from 'wagmi';
import { parseUnits } from 'viem';
import { addresses } from '../addresses';
import { lendingManagerAbi } from '../abi/lendingManager';

export function LendWithdraw() {
  const { address } = useAccount();
  const [amount, setAmount] = useState('');
  const manager = addresses.lendingManager as `0x${string}`;
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  return (
    <div style={{ border: '1px solid #ddd', padding: 12, borderRadius: 8 }}>
      <h4>Lender Withdraw</h4>
      <div style={{ display: 'flex', gap: 8 }}>
        <input placeholder="Amount (RWAC)" value={amount} onChange={e => setAmount(e.target.value)} style={{ width: 160 }} />
        <button disabled={!address || isPending}
          onClick={() => writeContract({ address: manager, abi: lendingManagerAbi, functionName: 'withdrawPartialLendedCoin', args: [parseUnits(amount || '0', 18)] })}>
          Partial Withdraw
        </button>
        <button disabled={!address || isPending}
          onClick={() => writeContract({ address: manager, abi: lendingManagerAbi, functionName: 'withdrawtotalLendedCoin', args: [parseUnits(amount || '0', 18)] })}>
          Total Withdraw
        </button>
      </div>
      {hash && <p>Tx: {hash}</p>}
      {isConfirming && <p>Waiting for confirmation...</p>}
      {isSuccess && <p>Success!</p>}
    </div>
  );
}
