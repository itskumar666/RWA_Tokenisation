import { useState } from 'react';
import { useAccount, useReadContract, useWaitForTransactionReceipt, useWriteContract } from 'wagmi';
import { addresses } from '../addresses';
import { lendingManagerAbi } from '../abi/lendingManager';

export function LendingAdmin() {
  const { address } = useAccount();
  const manager = addresses.lendingManager as `0x${string}`;
  const { writeContract, data: hash, isPending, error } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const { data: minReturn } = useReadContract({ address: manager, abi: lendingManagerAbi, functionName: 'getMinReturnPeriod' });
  const { data: processing } = useReadContract({ address: manager, abi: lendingManagerAbi, functionName: 'getProcessingState' });

  const [newMinReturn, setNewMinReturn] = useState('');
  const [newAuction, setNewAuction] = useState('');

  return (
    <div style={{ border: '1px solid #ddd', padding: 12, borderRadius: 8 }}>
      <h4>Lending Admin</h4>
      <div>Min Return Period: {String(minReturn ?? 0n)} sec</div>
      <div>Processing State: {processing ? `${(processing as any)[0]}/${(processing as any)[1]}` : '-'}</div>
      <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
        <button disabled={!address || isPending} onClick={() => writeContract({ address: manager, abi: lendingManagerAbi, functionName: 'performUpkeep', args: [] })}>
          {isPending ? 'Running…' : 'Run Upkeep'}
        </button>
        <button disabled={!address || isPending} onClick={() => writeContract({ address: manager, abi: lendingManagerAbi, functionName: 'resetProcessingState', args: [] })}>
          Reset Upkeep State
        </button>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginTop: 8 }}>
        <input placeholder="New Min Return Period (sec)" value={newMinReturn} onChange={e => setNewMinReturn(e.target.value)} />
        <button disabled={!address || isPending} onClick={() => writeContract({ address: manager, abi: lendingManagerAbi, functionName: 'setMinReturnPeriod', args: [BigInt(newMinReturn || '0')] })}>Set Min Return Period</button>
        <input placeholder="New AuctionHouse Address" value={newAuction} onChange={e => setNewAuction(e.target.value)} />
        <button disabled={!address || isPending} onClick={() => writeContract({ address: manager, abi: lendingManagerAbi, functionName: 'setAddressAuctionHouse', args: [newAuction as `0x${string}`] })}>Set AuctionHouse</button>
      </div>
      {hash && <p>Tx: {hash}</p>}
      {isConfirming && <p>Waiting for confirmation…</p>}
      {isSuccess && <p>Success!</p>}
      {error && <p style={{ color: 'crimson' }}>{(error as any)?.shortMessage || error.message}</p>}
    </div>
  );
}
