import { useAccount, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { useState } from 'react';
import { parseUnits } from 'viem';
import { addresses } from '../addresses';
import { rwaCoinsAbi } from '../abi/rwaCoins';

export function TokenTransfer() {
  const { address } = useAccount();
  const [to, setTo] = useState('');
  const [amount, setAmount] = useState('');
  const { data: hash, isPending, writeContract } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  return (
    <div>
      <h4>Transfer RWAC</h4>
      <div className="input-row">
        <input placeholder="0xRecipient" value={to} onChange={e => setTo(e.target.value)} />
        <input placeholder="Amount" value={amount} onChange={e => setAmount(e.target.value)} style={{ maxWidth: 140 }} />
        <button
          className="nowrap"
          disabled={!address || !to || !amount || isPending}
          onClick={() => writeContract({
            address: addresses.rwaCoins as `0x${string}`,
            abi: rwaCoinsAbi,
            functionName: 'transfer',
            args: [to as `0x${string}`, parseUnits(amount, 18)],
          })}
        >
          {isPending ? 'Sending…' : 'Send'}
        </button>
      </div>
      {hash && <p className="mono break">Tx: {hash}</p>}
      {isConfirming && <p className="subtle">Waiting for confirmation…</p>}
      {isSuccess && <p>Success!</p>}
    </div>
  );
}
