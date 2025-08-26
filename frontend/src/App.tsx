import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount } from 'wagmi';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { formatUnits } from 'viem';
import { useReadContract } from 'wagmi';
import { addresses } from './addresses';
import { rwaCoinsAbi } from './abi/rwaCoins';
import Dashboard from './pages/Dashboard';
import RwaManagerPage from './pages/RwaManagerPage';
import TransferPage from './pages/TransferPage';
import NftInspectorPage from './pages/NftInspectorPage';
import StakingPage from './pages/StakingPage';
import LendingHealthPage from './pages/LendingHealthPage';
import LendDepositPage from './pages/LendDepositPage';
import BorrowPage from './pages/BorrowPage';
import RepayPage from './pages/RepayPage';
import LendWithdrawPage from './pages/LendWithdrawPage';
import NftVaultPage from './pages/NftVaultPage';
import AuctionsPage from './pages/AuctionsPage';
import LendingAdminPage from './pages/LendingAdminPage';
import { Navbar } from './components/Navbar';
import AssetUploadPage from './pages/AssetUploadPage';
import ViewAssetsPage from './pages/ViewAssetsPage';

export default function App() {
  const { address } = useAccount();
  const { data: balance } = useReadContract({
    address: addresses.rwaCoins as `0x${string}`,
    abi: rwaCoinsAbi,
    functionName: 'balanceOf',
    args: [address ?? '0x0000000000000000000000000000000000000000'],
    query: { enabled: !!address },
  });

  return (
    <BrowserRouter>
      <div className="container">
        <div className="header">
          <h2 className="title">Zenith DApp <span className="subtle">(Sepolia)</span></h2>
          <ConnectButton />
        </div>
        <Navbar />
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/rwa-manager" element={<RwaManagerPage />} />
          <Route path="/transfer" element={<TransferPage />} />
          <Route path="/nft-inspector" element={<NftInspectorPage />} />
          <Route path="/staking" element={<StakingPage />} />
          <Route path="/lending-health" element={<LendingHealthPage />} />
          <Route path="/lend-deposit" element={<LendDepositPage />} />
          <Route path="/borrow" element={<BorrowPage />} />
          <Route path="/repay" element={<RepayPage />} />
          <Route path="/lend-withdraw" element={<LendWithdrawPage />} />
          <Route path="/asset-upload" element={<AssetUploadPage />} />
          <Route path="/view-assets" element={<ViewAssetsPage />} />
          <Route path="/nft-vault" element={<NftVaultPage />} />
          <Route path="/auctions" element={<AuctionsPage />} />
          <Route path="/lending-admin" element={<LendingAdminPage />} />
        </Routes>
      </div>
    </BrowserRouter>
  );
}
