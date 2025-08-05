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



/* 
@title NFTVault
@author Ashutosh Kumar
@notice This contract is used to manage NFTs (ERC-721) as collateral for lending. It allows the owner (LendingManager) to deposit NFTs, return them to borrowers when full coins are returned which were borrowed against nft, and also transfer them to auction houses in case of liquidation.
@dev The contract is pausable and can be paused by the owner.
@dev The contract uses OpenZeppelin's Pausable, Ownable, and ReentrancyGuard for security and access control.
@dev The contract assumes that the NFT contract implements the ERC721 standard and that the LendingManager contract handles the actual transfer of NFTs to this contract.
*/

pragma solidity ^0.8.20;
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

 contract NFTVault is Pausable, Ownable, ReentrancyGuard,IERC721Receiver{
    error NFTVault__NotZeroAddress();
    error NFTVault__TokenDoesNotExist();
    struct NFTInfo {
        uint256 tokenId;
        address owner;
        uint256 value; // Value of the NFT in terms of borrowed amount
    }
    
    IERC721 private immutable i_rwaNFT;
    mapping(uint256 tokenId => address owner) private s_tokenOwners;
    mapping(address user => NFTInfo[]) private s_userNFTs;
    mapping(uint256 tokenId => uint256 valueNFT) private s_tokenValue;

    event NFTDeposited(address indexed user, uint256 indexed tokenId);
    event NFTWithdrawn(address indexed user, uint256 indexed tokenId);
    event NFTTransferToAuctionHouse(address indexed user, uint256 indexed tokenId);

    constructor(address rwaNFT,address LendingManager) Ownable(LendingManager) {
        
        i_rwaNFT = IERC721(rwaNFT);

    }  
    
    
    function depositNFT(uint256 tokenId,address _borrower,uint256 _NFTValue) external nonReentrant whenNotPaused onlyOwner{
        if (address(0) == msg.sender) {
            revert NFTVault__NotZeroAddress();
        }
        //will be already checked by lending manager contract
        // if (!i_rwaNFT.exists(tokenId)) {
        //     revert NFTVault__TokenDoesNotExist();
        // }
        
        // i_rwaNFT.safeTransferFrom(_borrower, address(this), tokenId);
        s_tokenOwners[tokenId] = _borrower;

        s_userNFTs[_borrower].push(NFTInfo({
            tokenId: tokenId,
            owner: _borrower,
            value: _NFTValue
        }));

        s_tokenValue[tokenId] = _NFTValue; // Store the value of the NFT
        
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
        NFTInfo[] storage userTokens = s_userNFTs[_borrower];
        for (uint256 i = 0; i < userTokens.length; i++) {
            if (userTokens[i].tokenId == tokenId) {
                userTokens[i] = userTokens[userTokens.length - 1];
                userTokens.pop();
                break;
            }
        }
        
        emit NFTWithdrawn(_borrower, tokenId);
    
    }

    function tokenTransferToLender(uint256 tokenId,address _lender,address _borrower) external nonReentrant whenNotPaused onlyOwner {
        if (address(0) == _lender) {
            revert NFTVault__NotZeroAddress();
        }
        

        i_rwaNFT.safeTransferFrom(address(this), _lender, tokenId);
        delete s_tokenOwners[tokenId];
        
        // Remove tokenId from user's list
        NFTInfo[] storage userTokens = s_userNFTs[_borrower];
        for (uint256 i = 0; i < userTokens.length; i++) {
            if (userTokens[i].tokenId == tokenId) {
                userTokens[i] = userTokens[userTokens.length - 1];
                userTokens.pop();
                break;
            }
        }
        s_tokenOwners[tokenId] = address(0); // Clear the owner mapping for the tokenId
        
        emit NFTWithdrawn(_lender, tokenId);
    
    }
    function tokenTransferToAuctionHouseOnLiquidation(uint256 tokenId,address _auctionHouse) external nonReentrant whenNotPaused onlyOwner {
        if (address(0) == _auctionHouse) {
            revert NFTVault__NotZeroAddress();
        }
        if (s_tokenOwners[tokenId] == address(0)) {
            revert NFTVault__TokenDoesNotExist();
        }
        bytes memory data = abi.encode(s_tokenValue[tokenId]); // Optional: you can pass additional data if needed
        i_rwaNFT.safeTransferFrom(address(this), _auctionHouse, tokenId,data);
        delete s_tokenOwners[tokenId];
        
        // Remove tokenId from user's list
        NFTInfo[] storage userTokens = s_userNFTs[s_tokenOwners[tokenId]];
        for (uint256 i = 0; i < userTokens.length; i++) {
            if (userTokens[i].tokenId == tokenId) {
                userTokens[i] = userTokens[userTokens.length - 1];
                userTokens.pop();
                break;
            }
        }
        s_tokenOwners[tokenId] = address(0); // Clear the owner mapping for the tokenId
        
        emit NFTTransferToAuctionHouse(s_tokenOwners[tokenId], tokenId);
    }
    
     function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override pure returns (bytes4) {
       
        return IERC721Receiver.onERC721Received.selector;
    }
    
    
    }