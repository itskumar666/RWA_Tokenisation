#!/bin/bash

# Set environment variables
export SEPOLIA_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/wtwRDsMyNnq_hpPJLrFR4"
export BACKEND_PRIVATE_KEY="0x6a8f095cc171ef2371d06af1f18663051b1e4847d3c83107664946e481ddd402"

# Contract addresses
RWA_VERIFIED_ASSETS="0x21763032B2170d995c866E249fc85Da49E02aF4c"
NEW_RWA_NFT="0x8a6C86c56EE1F2a71E7cE4371F380BfF0ac496ed"
NEW_RWA_COINS="0xD3834ee45eE0D76B828Ff02B11eFc19f259B67Eb"

echo "Deploying RWA_Manager with correct contract addresses..."
echo "RWA_VerifiedAssets: $RWA_VERIFIED_ASSETS"
echo "RWA_NFT: $NEW_RWA_NFT"
echo "RWA_Coins: $NEW_RWA_COINS"

forge create src/CoinMintingAndManaging/RWA_Manager.sol:RWA_Manager \
    --constructor-args "$RWA_VERIFIED_ASSETS" "$NEW_RWA_NFT" "$NEW_RWA_COINS" \
    --private-key $BACKEND_PRIVATE_KEY \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast
