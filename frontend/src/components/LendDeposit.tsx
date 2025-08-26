import { useMemo, useState } from 'react';
import { useAccount, useReadContract, useWaitForTransactionReceipt, useWriteContract } from 'wagmi';
import { parseUnits } from 'viem';
import { addresses } from '../addresses';
import { lendingManagerAbi } from '../abi/lendingManager';
import { erc20Abi } from '../abi/erc20';

export function LendDeposit() {
  const { address } = useAccount();
  const [amount, setAmount] = useState('');
  const [interest, setInterest] = useState('5');
  const [minBorrow, setMinBorrow] = useState('1');
  const [returnPeriod, setReturnPeriod] = useState('1209600'); // 14 days default

  const rwac = addresses.rwaCoins as `0x${string}`;
  const manager = addresses.lendingManager as `0x${string}`;

  const { data: allow } = useReadContract({
    address: rwac,
    abi: erc20Abi,
    functionName: 'allowance',
    args: [address ?? '0x0000000000000000000000000000000000000000', manager],
    query: { enabled: !!address },
  });

  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const needApprove = useMemo(() => {
    if (!amount || typeof allow !== 'bigint') return true;
    try { return allow < parseUnits(amount, 18); } catch { return true; }
  }, [allow, amount]);

  const onSubmit = () => {
    writeContract({
      address: manager,
      abi: lendingManagerAbi,
      functionName: 'depositCoinToLend',
      args: [parseUnits(amount || '0', 18), Number(interest) as any, Number(minBorrow) as any, BigInt(returnPeriod)],
    });
  };

  return (
    <div>
      <h4>Lend: Deposit RWAC</h4>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
        <input placeholder="Amount" value={amount} onChange={e => setAmount(e.target.value)} />
        <input placeholder="Interest % (<=30)" value={interest} onChange={e => setInterest(e.target.value)} />
        <input placeholder="Min Borrow (RWAC)" value={minBorrow} onChange={e => setMinBorrow(e.target.value)} />
        <input placeholder="Return Period (sec)" value={returnPeriod} onChange={e => setReturnPeriod(e.target.value)} />
      </div>
      <div className="row mt-2">
        {needApprove ? (
          <button disabled={!address || isPending}
            onClick={() => writeContract({ address: rwac, abi: erc20Abi, functionName: 'approve', args: [manager, parseUnits(amount || '0', 18)] })}>
            {isPending ? 'Approving...' : 'Approve'}
          </button>
        ) : (
          <button disabled={!address || isPending} onClick={onSubmit}>
            {isPending ? 'Submitting...' : 'Deposit'}
          </button>
        )}
      </div>
      {hash && <p className="mono break">Tx: {hash}</p>}
      {isConfirming && <p className="subtle">Waiting for confirmation...</p>}
      {isSuccess && <p>Success!</p>}
    </div>
  );
}
