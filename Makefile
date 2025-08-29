# ---- CONFIG ----
RPC_URL ?= anvil
BROADCAST ?= --broadcast -vvvv

# ---- COMMANDS ----

.PHONY: all deploy_coin deploy_nft deploy_router deploy_verification deploy_manager deploy_all deploy_monolith deploy_all_sepolia clean

# Deploy RWA_Coins
deploy_coin:
	forge script script/CoinMintingAndManagingDeployment/Deploy_RWACoins.s.sol:DeployRWACoins --rpc-url $(RPC_URL) $(BROADCAST)

# Deploy RWA_NFT
deploy_nft:
	forge script script/CoinMintingAndManagingDeployment/Deploy_RWANFT.s.sol:DeployRWANFT --rpc-url $(RPC_URL) $(BROADCAST)

# Deploy FunctionsRouter
deploy_router:
	forge script script/CoinMintingAndManagingDeployment/Deploy_FunctionsRouter.s.sol:DeployFunctionsRouter --rpc-url $(RPC_URL) $(BROADCAST)

# Deploy RWA_Verification
deploy_verification:
	forge script script/CoinMintingAndManagingDeployment/Deploy_RWAVerification.s.sol:DeployRWAVerification --rpc-url $(RPC_URL) $(BROADCAST)

# Deploy RWA_Manager
deploy_manager:
	forge script script/CoinMintingAndManagingDeployment/Deploy_RWAManager.s.sol:DeployRWAManager --rpc-url $(RPC_URL) $(BROADCAST)

# Deploy all in order
deploy_all: deploy_coin deploy_nft deploy_router deploy_verification deploy_manager

# Single script deployment of all contracts
deploy_monolith:
	forge script script/Deploy_All.s.sol:Deploy_All --rpc-url $(RPC_URL) $(BROADCAST)

# Deploy all on Sepolia with verification
deploy_all_sepolia:
	forge script script/Deploy_All.s.sol:Deploy_All --rpc-url sepolia $(BROADCAST) --verify

# Clean build artifacts
clean:
	forge clean

.PHONY: frontend frontend-build frontend-preview
frontend:
	cd frontend && npm run dev

frontend-build:
	cd frontend && npm run build

frontend-preview:
	cd frontend && npm run preview
