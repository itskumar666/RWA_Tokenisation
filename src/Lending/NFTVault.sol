// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
 contract NFTVault is Pausable, Ownable, ReentrancyGuard {
    error NFTVault__NotZeroAddress();
    error NFTVault__TokenDoesNotExist();
    
    IERC721 private immutable i_rwaNFT;
    mapping(uint256 tokenId => address owner) private s_tokenOwners;
    mapping(address user => uint256[] tokenIds) private s_userNFTs;

    event NFTDeposited(address indexed user, uint256 indexed tokenId);
    event NFTWithdrawn(address indexed user, uint256 indexed tokenId);
    event NFTTransferToAuctionHouse(address indexed user, uint256 indexed tokenId);

    constructor(address rwaNFT,address LendingManager) Ownable(LendingManager) {
        
        i_rwaNFT = IERC721(rwaNFT);

    }  
    
    
    
    
    
    
    
    
    
    function depositNFT(uint256 tokenId,address _borrower) external nonReentrant whenNotPaused onlyOwner{
        if (address(0) == msg.sender) {
            revert NFTVault__NotZeroAddress();
        }
        //will be already checked by lending manager contract
        // if (!i_rwaNFT.exists(tokenId)) {
        //     revert NFTVault__TokenDoesNotExist();
        // }
        
        // i_rwaNFT.safeTransferFrom(_borrower, address(this), tokenId);
        s_tokenOwners[tokenId] = _borrower;
        s_userNFTs[_borrower].push(tokenId);
        
        emit NFTDeposited(msg.sender, tokenId);
    }
    function tokenTransferToBorrower(uint256 tokenId,address _borrower) external nonReentrant whenNotPaused onlyOwner {
        if (address(0) == _borrower) {
            revert NFTVault__NotZeroAddress();
        }
        if (s_tokenOwners[tokenId] != _borrower) {
            revert NFTVault__TokenDoesNotExist();
        }
        
        i_rwaNFT.safeTransferFrom(address(this), _borrower, tokenId);
        delete s_tokenOwners[tokenId];
        
        // Remove tokenId from user's list
        uint256[] storage userTokens = s_userNFTs[_borrower];
        for (uint256 i = 0; i < userTokens.length; i++) {
            if (userTokens[i] == tokenId) {
                userTokens[i] = userTokens[userTokens.length - 1];
                userTokens.pop();
                break;
            }
        }
        
        emit NFTWithdrawn(_borrower, tokenId);
    
    }
    function tokenTransferToAuctionHouseOnLiquidation(uint256 tokenId,address _auctionHouse) external nonReentrant whenNotPaused onlyOwner {
        if (address(0) == _auctionHouse) {
            revert NFTVault__NotZeroAddress();
        }
        if (s_tokenOwners[tokenId] == address(0)) {
            revert NFTVault__TokenDoesNotExist();
        }
        
        i_rwaNFT.safeTransferFrom(address(this), _auctionHouse, tokenId);
        delete s_tokenOwners[tokenId];
        
        // Remove tokenId from user's list
        uint256[] storage userTokens = s_userNFTs[s_tokenOwners[tokenId]];
        for (uint256 i = 0; i < userTokens.length; i++) {
            if (userTokens[i] == tokenId) {
                userTokens[i] = userTokens[userTokens.length - 1];
                userTokens.pop();
                break;
            }
        }
        
        emit NFTTransferToAuctionHouse(s_tokenOwners[tokenId], tokenId);
    }}