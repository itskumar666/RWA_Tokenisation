export const lendingManagerAbi = [
  { "inputs": [], "name": "performUpkeep", "outputs": [], "stateMutability": "nonpayable", "type": "function" },
  { "inputs": [ { "internalType": "uint256", "name": "_minReturnPeriod", "type": "uint256" } ], "name": "setMinReturnPeriod", "outputs": [], "stateMutability": "nonpayable", "type": "function" },
  { "inputs": [ { "internalType": "address", "name": "_auctionHouse", "type": "address" } ], "name": "setAddressAuctionHouse", "outputs": [], "stateMutability": "nonpayable", "type": "function" },
  {
    "inputs": [{ "internalType": "address", "name": "_borrower", "type": "address" }],
    "name": "getborrowingInfo",
    "outputs": [
      {
        "components": [
          { "internalType": "uint256", "name": "amount", "type": "uint256" },
          { "internalType": "uint256", "name": "tokenIdNFT", "type": "uint256" },
          { "internalType": "address", "name": "lender", "type": "address" },
          { "internalType": "uint256", "name": "assetId", "type": "uint256" },
          { "internalType": "uint256", "name": "borrowTime", "type": "uint256" },
          { "internalType": "uint256", "name": "returnTime", "type": "uint256" },
          { "internalType": "bool", "name": "isReturned", "type": "bool" }
        ],
        "internalType": "struct LendingManager.BorrowingInfo[]",
        "name": "",
        "type": "tuple[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      { "internalType": "uint256", "name": "_amount", "type": "uint256" },
      { "internalType": "uint8", "name": "_interest", "type": "uint8" },
      { "internalType": "uint8", "name": "minBorrow", "type": "uint8" },
      { "internalType": "uint256", "name": "_returnPeriod", "type": "uint256" }
    ],
    "name": "depositCoinToLend",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      { "internalType": "uint256", "name": "_amount", "type": "uint256" },
      { "internalType": "uint256", "name": "_tokenIdNFT", "type": "uint256" },
      { "internalType": "address", "name": "_lender", "type": "address" },
      { "internalType": "uint256", "name": "_assetId", "type": "uint256" }
    ],
    "name": "borrowCoin",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      { "internalType": "address", "name": "_lender", "type": "address" },
      { "internalType": "uint256", "name": "_amount", "type": "uint256" },
      { "internalType": "uint256", "name": "_tokenIdNFT", "type": "uint256" }
    ],
    "name": "returnCoinToLender",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{ "internalType": "uint256", "name": "_amount", "type": "uint256" }],
    "name": "withdrawPartialLendedCoin",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{ "internalType": "uint256", "name": "_amount", "type": "uint256" }],
    "name": "withdrawtotalLendedCoin",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  { "inputs": [ { "internalType": "address", "name": "_lender", "type": "address" } ], "name": "getLendingInfo", "outputs": [ { "components": [ { "internalType": "uint256", "name": "amount", "type": "uint256" }, { "internalType": "uint8", "name": "interest", "type": "uint8" }, { "internalType": "uint8", "name": "minBorrow", "type": "uint8" }, { "internalType": "uint256", "name": "returnPeriod", "type": "uint256" } ], "internalType": "struct LendingManager.LendingInfo", "name": "", "type": "tuple" } ], "stateMutability": "view", "type": "function" },
  { "inputs": [], "name": "getCompleteLendingPool", "outputs": [ { "components": [ { "internalType": "uint256", "name": "amount", "type": "uint256" }, { "internalType": "uint8", "name": "interest", "type": "uint8" }, { "internalType": "uint8", "name": "minBorrow", "type": "uint8" }, { "internalType": "uint256", "name": "returnPeriod", "type": "uint256" } ], "internalType": "struct LendingManager.LendingInfo[]", "name": "", "type": "tuple[]" } ], "stateMutability": "view", "type": "function" },
  { "inputs": [], "name": "getMinReturnPeriod", "outputs": [ { "internalType": "uint256", "name": "", "type": "uint256" } ], "stateMutability": "view", "type": "function" },
  { "inputs": [], "name": "getProcessingState", "outputs": [ { "internalType": "uint256", "name": "lastProcessedIndex", "type": "uint256" }, { "internalType": "uint256", "name": "totalBorrowers", "type": "uint256" } ], "stateMutability": "view", "type": "function" },
  { "inputs": [], "name": "resetProcessingState", "outputs": [], "stateMutability": "nonpayable", "type": "function" }
] as const;
