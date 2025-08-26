import { Link, useLocation } from 'react-router-dom';

export function Navbar() {
  const { pathname } = useLocation();
  const links = [
    { to: '/', label: 'Dashboard' },
  { to: '/asset-upload', label: 'Asset Management' },
  { to: '/view-assets', label: 'View Assets' },
    { to: '/rwa-manager', label: 'RWA Manager' },
    { to: '/transfer', label: 'Transfer RWAC' },
    { to: '/nft-inspector', label: 'NFT Inspector' },
    { to: '/staking', label: 'Staking' },
    { to: '/lending-health', label: 'Lending Health' },
    { to: '/lend-deposit', label: 'Lend Deposit' },
    { to: '/borrow', label: 'Borrow' },
    { to: '/repay', label: 'Repay' },
    { to: '/lend-withdraw', label: 'Lend Withdraw' },
    { to: '/nft-vault', label: 'NFT Vault' },
    { to: '/auctions', label: 'Auction House' },
    { to: '/lending-admin', label: 'Lending Admin' },
  ];
  return (
    <nav className="nav">
      {links.map(({ to, label }) => (
        <Link key={to} to={to} className={`nav-link ${pathname === to ? 'active' : ''}`}>{label}</Link>
      ))}
    </nav>
  );
}