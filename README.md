<p align="center">
  <img src="https://raw.githubusercontent.com/itskumar666/RWA_Tokenisation/main/assets/banner.png" alt="Decentralized Bank on Ethereum" width="600"/>
</p>

<p align="center">
  <b>Decentralized Bank on Ethereum | Foundry + Solidity</b><br>
  Stake, lend, borrow, tokenize assets as NFTs, and auction them in a fully on-chain decentralized bank.
</p>

<p align="center">
  <a href="https://youtube.com/@Felinophile666/streams"><img src="https://img.shields.io/badge/YouTube-Live_Streams-red?logo=youtube&logoColor=white"></a>
  <img src="https://img.shields.io/badge/Built%20with-Foundry-blueviolet?logo=ethereum&logoColor=white">
  <img src="https://img.shields.io/badge/License-MIT-green">
</p>

---

# 🏦 Decentralized Bank on Ethereum

A **modular, audit-friendly decentralized bank** built using **Solidity + Foundry**, enabling:

✅ **Staking** – Earn rewards by staking tokens.  
✅ **Lending & Borrowing** – Supply/borrow assets with interest.  
✅ **NFT Tokenization** – Mint, stake, and collateralize NFTs.  
✅ **Auction House** – Decentralized NFT auctions.  
✅ **Proxy Upgradability** – Safe upgrades for contracts.  
✅ **Gas Optimization** – Efficient, scalable, audit-ready code.

---

## 🚀 Features

- **Stake to Earn**: Users stake tokens and earn rewards.
- **Lend & Borrow**: Supply and borrow assets with interest mechanisms.
- **NFT Collateral**: Use NFTs as collateral in lending/borrowing.
- **Auction NFTs**: List, bid, and settle NFT auctions fully on-chain.
- **Proxy Pattern**: Upgradable architecture with UUPS/Transparent proxy.
- **Tested with Foundry**: Includes unit, fuzz, and invariant tests.

---

## 🛠 Tech Stack

- **Solidity (0.8.x)**
- **Foundry (Forge, Anvil, Cast)**
- **OpenZeppelin Contracts**
- **Proxy Pattern (UUPS/Transparent)**
- **CI/CD Ready** (GitHub Actions)

---

## 📚 Documentation

- [📘 Foundry Book](https://book.getfoundry.sh/)
- [🔗 OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)

---

## 📂 Directory Structure

```
contracts/
    Staking/
    Lending/
    NFT/
    AuctionHouse/
    Proxy/
test/
script/
foundry.toml
```

- `contracts/` – All Solidity source files
- `test/` – Unit, fuzz, and invariant tests
- `script/` – Deployment and upgrade scripts
- `foundry.toml` – Project configuration

---

## 🧪 Quick Usage

### Build

```bash
forge build
```

### Test with detailed output

```bash
forge test -vvv
```

### Snapshot gas usage

```bash
forge snapshot
```

### Run local node

```bash
anvil
```

### Deploy

```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

### Interact

```bash
cast call <contract_address> <function_signature> [args...]
```

---

## 🗺 Roadmap

✅ Core staking and reward system  
✅ Lending & borrowing pools  
✅ NFT minting & collateral support  
✅ NFT auction house  
✅ Proxy-based upgradability  
🔜 Chainlink price feeds  
🔜 Frontend dApp (wagmi/viem)

---

## 🤝 Contributing

PRs and issues are welcome for:

- Gas optimizations
- Advanced collateral strategies
- Chainlink integrations
- Frontend contributions

---

## 🪪 License

This project is licensed under the [MIT License](LICENSE).

---

## 🧪 Testing & Best Practices

✅ Run `forge test -vvv` for detailed test outputs  
✅ Write fuzz tests for deposit/withdraw and borrow/repay flows  
✅ Use `forge snapshot` to monitor gas costs  
✅ Run **Slither** or **Mythril** for static analysis before deployment

---

## 👨‍💻 Author

**Ashutosh (Felinophile666)**

🎥 [YouTube Streams](https://youtube.com/@Felinophile666/streams)  
🐙 [GitHub Profile](https://github.com/itskumar666)

---

## ✨ Why This Project?

I am **mastering advanced Solidity development with Foundry**, using **rigorous testing, fuzzing, and gas optimization** to build production-grade decentralized finance protocols.

If you're working on DeFi, RWA tokenization, or advanced Web3 projects, feel free to fork, test, and extend this repository.

> **“Decentralization is the future of banking. Let’s build it.”**

---
