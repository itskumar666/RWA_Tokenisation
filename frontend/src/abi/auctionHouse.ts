export const auctionHouseAbi = [
  { "inputs": [ { "internalType": "uint256", "name": "tokenId", "type": "uint256" }, { "internalType": "uint256", "name": "bidAmount", "type": "uint256" } ], "name": "bidOnNFT", "outputs": [], "stateMutability": "nonpayable", "type": "function" },
  { "inputs": [ { "internalType": "uint256", "name": "tokenId", "type": "uint256" } ], "name": "endAuction", "outputs": [], "stateMutability": "nonpayable", "type": "function" },
  { "inputs": [ { "internalType": "uint256", "name": "tokenId", "type": "uint256" } ], "name": "getAuction", "outputs": [ { "components": [ { "internalType": "uint256", "name": "tokenId", "type": "uint256" }, { "internalType": "uint256", "name": "startingPrice", "type": "uint256" }, { "internalType": "uint256", "name": "endTime", "type": "uint256" }, { "internalType": "uint256", "name": "highestBid", "type": "uint256" }, { "internalType": "address", "name": "highestBidder", "type": "address" } ], "internalType": "struct AuctionHouse.Auction", "name": "", "type": "tuple" } ], "stateMutability": "view", "type": "function" },
  { "inputs": [], "name": "getActiveAuctions", "outputs": [ { "internalType": "uint256[]", "name": "", "type": "uint256[]" } ], "stateMutability": "view", "type": "function" },
  { "inputs": [], "name": "getExpiredAuctions", "outputs": [ { "internalType": "uint256[]", "name": "", "type": "uint256[]" } ], "stateMutability": "view", "type": "function" },
  { "inputs": [], "name": "getAuctionDuration", "outputs": [ { "internalType": "uint256", "name": "", "type": "uint256" } ], "stateMutability": "view", "type": "function" },
  { "inputs": [], "name": "getDefaultPrice", "outputs": [ { "internalType": "uint256", "name": "", "type": "uint256" } ], "stateMutability": "view", "type": "function" },
  { "inputs": [], "name": "getAllTokenIds", "outputs": [ { "internalType": "uint256[]", "name": "", "type": "uint256[]" } ], "stateMutability": "view", "type": "function" },
  { "inputs": [ { "internalType": "uint256", "name": "tokenId", "type": "uint256" } ], "name": "isAuctionActive", "outputs": [ { "internalType": "bool", "name": "", "type": "bool" } ], "stateMutability": "view", "type": "function" },
  { "inputs": [ { "internalType": "uint256", "name": "tokenId", "type": "uint256" } ], "name": "cancelAuction", "outputs": [], "stateMutability": "nonpayable", "type": "function" },
  { "inputs": [ { "internalType": "address", "name": "token", "type": "address" } ], "name": "emergencyWithdrawERC20", "outputs": [], "stateMutability": "nonpayable", "type": "function" },
  { "inputs": [ { "internalType": "uint256", "name": "tokenId", "type": "uint256" } ], "name": "emergencyWithdrawNFT", "outputs": [], "stateMutability": "nonpayable", "type": "function" }
] as const;
