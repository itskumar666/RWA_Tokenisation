import { useState } from 'react';
import { useReadContract } from 'wagmi';
import { addresses } from '../addresses';
import { rwaNftAbi } from '../abi/rwaNft';

export function NFTInspector() {
  const [tokenId, setTokenId] = useState('0');
  const idNum = Number(tokenId || '0');
  const { data } = useReadContract({
    address: addresses.rwaNft as `0x${string}`,
    abi: rwaNftAbi,
    functionName: 'getTokenMetadata',
    args: [BigInt(isNaN(idNum) ? 0 : idNum)],
  });

  const meta = data as any;
  return (
    <div>
      <h4>NFT Inspector</h4>
      <div className="row">
        <label>Token ID</label>
        <input value={tokenId} onChange={e => setTokenId(e.target.value)} style={{ maxWidth: 140 }} />
      </div>
      {meta && (
        <div className="mt-2">
          <p className="break"><b>Name:</b> {meta[0]}</p>
          <p className="break"><b>Description:</b> {meta[1]}</p>
          <p className="break mono"><b>IPFS URI:</b> {meta[3]}</p>
        </div>
      )}
    </div>
  );
}
