import { useState } from 'react';
import { useAccount, useReadContract } from 'wagmi';
import { addresses } from '../addresses';
import { nftVaultAbi } from '../abi/nftVault';

export function NftVaultPanel() {
  const { address } = useAccount();
  const vault = addresses.nftVault as `0x${string}`;
  const { data: count } = useReadContract({ address: vault, abi: nftVaultAbi, functionName: 'getUserNFTCount', args: [address ?? '0x0000000000000000000000000000000000000000'], query: { enabled: !!address } });
  const { data: list } = useReadContract({ address: vault, abi: nftVaultAbi, functionName: 'getUserNFTs', args: [address ?? '0x0000000000000000000000000000000000000000'], query: { enabled: !!address } });
  const [tokenId, setTokenId] = useState('');
  const { data: owner } = useReadContract({ address: vault, abi: nftVaultAbi, functionName: 'getTokenOwner', args: [tokenId ? BigInt(tokenId) : 0n], query: { enabled: !!tokenId } });
  const { data: value } = useReadContract({ address: vault, abi: nftVaultAbi, functionName: 'getTokenValue', args: [tokenId ? BigInt(tokenId) : 0n], query: { enabled: !!tokenId } });

  return (
    <div style={{ border: '1px solid #ddd', padding: 12, borderRadius: 8 }}>
      <h4>NFT Vault</h4>
      <div>Count: {String(count ?? 0)}</div>
      <div style={{ marginTop: 8 }}>
        <h5>Your NFTs in Vault</h5>
        {Array.isArray(list) && list.length > 0 ? (
          <ul>
            {list.map((n: any, i: number) => (
              <li key={i}>
                Token #{String(n.tokenId)} — Value: {String(n.value)} — Owner: {n.owner}
              </li>
            ))}
          </ul>
        ) : <small>None</small>}
      </div>
      <div style={{ marginTop: 8 }}>
        <h5>Lookup</h5>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          <input placeholder="Token ID" value={tokenId} onChange={e => setTokenId(e.target.value)} />
          <div>Owner: {owner as string}</div>
          <div>Value: {String(value ?? 0n)}</div>
        </div>
      </div>
    </div>
  );
}
