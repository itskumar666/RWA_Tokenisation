import { useMemo, useState } from 'react';
import { useAccount, useReadContract, useWaitForTransactionReceipt, useWriteContract } from 'wagmi';
import { parseUnits, formatUnits } from 'viem';
import { addresses } from '../addresses';
import { stakingCoinAbi } from '../abi/stakingCoin';
import { erc20Abi } from '../abi/erc20';

export function StakingPanel() {
  const { address } = useAccount();
  const [amount, setAmount] = useState('');
  const rwac = addresses.rwaCoins as `0x${string}`;
  const staking = addresses.staking as `0x${string}`;

  const { data: staked } = useReadContract({
    address: staking,
    abi: stakingCoinAbi,
    functionName: 'getStakedAmountOf',
    args: [address ?? '0x0000000000000000000000000000000000000000'],
    query: { enabled: !!address },
  });
  const { data: rewards } = useReadContract({
    address: staking,
    abi: stakingCoinAbi,
    functionName: 'getCurrentRewardOf',
    args: [address ?? '0x0000000000000000000000000000000000000000'],
    query: { enabled: !!address },
  });

  const { data: allow } = useReadContract({
    address: rwac,
    abi: erc20Abi,
    functionName: 'allowance',
    args: [address ?? '0x0000000000000000000000000000000000000000', staking],
    query: { enabled: !!address },
  });

  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const needApprove = useMemo(() => {
    if (!amount || typeof allow !== 'bigint') return true;
    try { return allow < parseUnits(amount, 18); } catch { return true; }
  }, [allow, amount]);

  return (
    <div style={{ border: '1px solid #ddd', padding: 12, borderRadius: 8 }}>
      <h4>Staking</h4>
      <p>Staked: {typeof staked === 'bigint' ? formatUnits(staked, 18) : '0'}</p>
      <p>Rewards: {typeof rewards === 'bigint' ? formatUnits(rewards, 18) : '0'}</p>
      <div style={{ display: 'flex', gap: 8 }}>
        <input placeholder="Amount" value={amount} onChange={e => setAmount(e.target.value)} style={{ width: 160 }} />
        {!address ? (
          <button disabled>Connect</button>
        ) : needApprove ? (
          <button disabled={isPending}
            onClick={() => writeContract({ address: rwac, abi: erc20Abi, functionName: 'approve', args: [staking, parseUnits(amount || '0', 18)] })}>
            {isPending ? 'Approving...' : 'Approve'}
          </button>
        ) : (
          <button disabled={isPending}
            onClick={() => writeContract({ address: staking, abi: stakingCoinAbi, functionName: 'stakeCoin', args: [rwac, parseUnits(amount || '0', 18)] })}>
            {isPending ? 'Staking...' : 'Stake'}
          </button>
        )}
        <button disabled={!address || isPending}
          onClick={() => writeContract({ address: staking, abi: stakingCoinAbi, functionName: 'withdrawCoin', args: [parseUnits(amount || '0', 18)] })}>
          Withdraw
        </button>
        <button disabled={!address || isPending}
          onClick={() => writeContract({ address: staking, abi: stakingCoinAbi, functionName: 'claimFullReward', args: [] })}>
          Claim Rewards
        </button>
      </div>
      {hash && <p>Tx: {hash}</p>}
      {isConfirming && <p>Waiting for confirmation...</p>}
      {isSuccess && <p>Success!</p>}
    </div>
  );
}
