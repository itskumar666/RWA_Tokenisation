import { useAccount, useReadContract } from 'wagmi';
import { addresses } from '../addresses';
import { lendingManagerAbi } from '../abi/lendingManager';

export function LendingHealth() {
  const { address } = useAccount();
  const { data } = useReadContract({
    address: addresses.lendingManager as `0x${string}`,
    abi: lendingManagerAbi,
    functionName: 'getborrowingInfo',
    args: [address ?? '0x0000000000000000000000000000000000000000'],
    query: { enabled: !!address },
  });
  const loans = (data as any[]) || [];

  return (
    <div>
      <h4>Your Loans</h4>
      {(!address || loans.length === 0) ? <p className="subtle">No active loans.</p> : (
        <ul className="reset">
          {loans.map((l: any, i: number) => (
            <li key={i} className="break">
              amount: {l[0]?.toString?.()} | tokenId: {l[1]?.toString?.()} | lender: {l[2]} | due: {l[5]?.toString?.()} | returned: {String(l[6])}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
