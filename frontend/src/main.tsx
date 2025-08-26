import React from 'react';
import { createRoot } from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { RainbowKitProvider, getDefaultConfig, darkTheme } from '@rainbow-me/rainbowkit';
import '@rainbow-me/rainbowkit/styles.css';
import './styles.css';
import { WagmiProvider, http } from 'wagmi';
import { sepolia } from 'viem/chains';
import App from './App';

const queryClient = new QueryClient();

const rpcUrl = import.meta.env.VITE_RPC_URL as string | undefined;
const wcProjectId = (import.meta as any).env?.VITE_WC_PROJECT_ID || 'demo';

const config = getDefaultConfig({
  appName: 'Zenith DApp',
  projectId: wcProjectId,
  chains: [sepolia],
  transports: {
    [sepolia.id]: http(rpcUrl ?? 'https://rpc.sepolia.org'),
  },
});

createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
  <RainbowKitProvider theme={darkTheme({ accentColor: '#6ea8ff' })}>
          <App />
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  </React.StrictMode>
);
