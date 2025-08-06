// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.20;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AuctionHouse is IERC721Receiver, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    IERC721 private immutable i_rwaNFT;

    error AuctionHouse__NotZeroAddress();
    error AuctionHouse__TokenDoesNotExist();
    error AuctionHouse__InvalidAuction();
    error AuctionHouse__NotZeroAmount();
    error AuctionHouse__BidTooLow();
    error AuctionHouse__AuctionStillGoingOn();
    error AuctionHouse__AuctionAlreadyExists();
    error AuctionHouse__AuctionNotFound();
    struct Auction {
        uint256 tokenId;
        uint256 startingPrice;
        uint256 endTime;
        uint256 highestBid;
        address highestBidder;
    }
    // Mapping from tokenId to Auction
    mapping(uint256 tokenId => Auction) private auctions;

    uint256[] private tokenIdsArray;
    IERC20 private immutable i_rwaCoin;
    uint256 defaultPrice; // default price for auction if not specified
    uint256 private auctionDuration; // auction duration in seconds

    event NFTReceived(
        address indexed operator,
        address indexed from,
        uint256 indexed tokenId,
        bytes data
    );
    event BidPlaced(
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 bidAmount
    );
    event AuctionCreated(
        uint256 indexed tokenId,
        uint256 startingPrice,
        uint256 endTime
    );
    event AuctionEnded(
        uint256 indexed tokenId,
        address indexed winner,
        uint256 winningBid
    );
    event AuctionCancelled(uint256 indexed tokenId);
    event EmergencyWithdraw(address indexed token, uint256 amount);

    constructor(
        address rwaNFT,
        address rwaCoin,
        uint256 _duration,
        address owner,
        uint256 _defaultPrice
    ) Ownable(owner) {
        if (rwaNFT == address(0)) {
            revert AuctionHouse__NotZeroAddress();
        }
        if (rwaCoin == address(0)) {
            revert AuctionHouse__NotZeroAddress();
        }
        if (_duration == 0) {
            revert AuctionHouse__NotZeroAmount();
        }
        if (_defaultPrice == 0) {
            revert AuctionHouse__NotZeroAmount();
        }
        i_rwaCoin = IERC20(rwaCoin);
        i_rwaNFT = IERC721(rwaNFT);
        auctionDuration = _duration;
        defaultPrice = _defaultPrice;
    }

    modifier notZeroAmount(uint256 amount) {
        if (amount == 0) {
            revert AuctionHouse__NotZeroAmount();
        }
        _;
    }
    modifier notZeroAddress(address addr) {
        if (addr == address(0)) {
            revert AuctionHouse__NotZeroAddress();
        }
        _;
    }
    function setAuctionDuration(
        uint256 duration
    ) external onlyOwner notZeroAmount(duration) {
        auctionDuration = duration;
    }
    function setDefaultPrice(
        uint256 price
    ) external onlyOwner notZeroAmount(price) {
        defaultPrice = price;
    }

    function bidOnNFT(
        uint256 tokenId,
        uint256 bidAmount
    )
        external
        notZeroAmount(bidAmount)
        notZeroAddress(msg.sender)
        nonReentrant
    {
        Auction storage auction = auctions[tokenId];
        
        // Check if auction exists
        if (auction.tokenId == 0) {
            revert AuctionHouse__AuctionNotFound();
        }
        
        // Check if auction is still active
        if (block.timestamp > auction.endTime) {
            revert AuctionHouse__InvalidAuction();
        }

        // Fixed: Correct bid validation logic
        if (bidAmount <= auction.highestBid) {
            revert AuctionHouse__BidTooLow();
        }

        address previousBidder = auction.highestBidder;
        uint256 previousBid = auction.highestBid;

        auction.highestBid = bidAmount;
        auction.highestBidder = msg.sender;

        // INTERACTIONS (external calls last)
        // Transfer the bid amount from the bidder first
        i_rwaCoin.safeTransferFrom(msg.sender, address(this), bidAmount);

        // Refund the previous highest bidder (excluding contract itself)
        if (previousBidder != address(0) && previousBidder != address(this)) {
            i_rwaCoin.safeTransfer(previousBidder, previousBid);
        }
        emit BidPlaced(tokenId, msg.sender, bidAmount);
    }
    //function to declare. winner of auction can be checked manually or it will be called by chainlink automation

    function endAuction(uint256 tokenId) external nonReentrant {
        Auction storage auction = auctions[tokenId];
        
        // Check if auction exists
        if (auction.tokenId == 0) {
            revert AuctionHouse__AuctionNotFound();
        }

        // Check if auction has ended
        if (block.timestamp < auction.endTime) {
            revert AuctionHouse__AuctionStillGoingOn();
        }

        address winner = auction.highestBidder;
        uint256 winningBid = auction.highestBid;

        // Clean up auction data
        delete auctions[tokenId];
        _removeTokenFromArray(tokenId);

        // Transfer NFT to winner
        if (winner != address(0) && winner != address(this)) {
            i_rwaNFT.safeTransferFrom(address(this), winner, tokenId);
            emit AuctionEnded(tokenId, winner, winningBid);
        } else {
            // No valid bids, keep NFT in contract or handle as needed
            // For now, we'll keep it in the contract
            emit AuctionEnded(tokenId, address(this), 0);
        }
    }

    function _createAuction(
        uint256 tokenId,
        uint256 startingPrice
    ) internal notZeroAmount(startingPrice) {
        // Check if auction already exists
        if (auctions[tokenId].tokenId != 0) {
            revert AuctionHouse__AuctionAlreadyExists();
        }
        
        auctions[tokenId] = Auction({
            tokenId: tokenId,
            startingPrice: startingPrice,
            endTime: block.timestamp + auctionDuration,
            highestBid: startingPrice,
            highestBidder: address(this)
        });
        
        emit AuctionCreated(
            tokenId,
            startingPrice,
            block.timestamp + auctionDuration
        );
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        uint256 startingPrice;
        
        if (data.length > 0) {
            // If data is provided, decode the starting price
            startingPrice = abi.decode(data, (uint256));
        } else {
            // Use default price if no data provided
            startingPrice = defaultPrice;
        }
        
        _createAuction(tokenId, startingPrice);
        tokenIdsArray.push(tokenId);
        emit NFTReceived(operator, from, tokenId, data);

        return IERC721Receiver.onERC721Received.selector;
    }
    
    // ========================================
    // INTERNAL HELPER FUNCTIONS
    // ========================================
    
    function _removeTokenFromArray(uint256 tokenId) internal {
        for (uint256 i = 0; i < tokenIdsArray.length; i++) {
            if (tokenIdsArray[i] == tokenId) {
                tokenIdsArray[i] = tokenIdsArray[tokenIdsArray.length - 1];
                tokenIdsArray.pop();
                break;
            }
        }
    }
    
    // ========================================
    // VIEW FUNCTIONS
    // ========================================
    
    function getAuction(uint256 tokenId) external view returns (Auction memory) {
        return auctions[tokenId];
    }
    
    function getActiveAuctions() external view returns (uint256[] memory) {
        uint256[] memory activeTokens = new uint256[](tokenIdsArray.length);
        uint256 count = 0;
        
        for (uint256 i = 0; i < tokenIdsArray.length; i++) {
            uint256 tokenId = tokenIdsArray[i];
            if (auctions[tokenId].tokenId != 0 && auctions[tokenId].endTime > block.timestamp) {
                activeTokens[count] = tokenId;
                count++;
            }
        }
        
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = activeTokens[i];
        }
        
        return result;
    }
    
    function getExpiredAuctions() external view returns (uint256[] memory) {
        uint256[] memory expiredTokens = new uint256[](tokenIdsArray.length);
        uint256 count = 0;
        
        for (uint256 i = 0; i < tokenIdsArray.length; i++) {
            uint256 tokenId = tokenIdsArray[i];
            if (auctions[tokenId].tokenId != 0 && auctions[tokenId].endTime <= block.timestamp) {
                expiredTokens[count] = tokenId;
                count++;
            }
        }
        
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = expiredTokens[i];
        }
        
        return result;
    }
    
    function getAuctionDuration() external view returns (uint256) {
        return auctionDuration;
    }
    
    function getDefaultPrice() external view returns (uint256) {
        return defaultPrice;
    }
    
    function getAllTokenIds() external view returns (uint256[] memory) {
        return tokenIdsArray;
    }
    
    function isAuctionActive(uint256 tokenId) external view returns (bool) {
        Auction memory auction = auctions[tokenId];
        return auction.tokenId != 0 && auction.endTime > block.timestamp;
    }
    
    // ========================================
    // EMERGENCY FUNCTIONS
    // ========================================
    
    function cancelAuction(uint256 tokenId) external onlyOwner nonReentrant {
        Auction storage auction = auctions[tokenId];
        
        if (auction.tokenId == 0) {
            revert AuctionHouse__AuctionNotFound();
        }
        
        address bidder = auction.highestBidder;
        uint256 bidAmount = auction.highestBid;
        
        // Clean up auction
        delete auctions[tokenId];
        _removeTokenFromArray(tokenId);
        
        // Refund highest bidder if not the contract
        if (bidder != address(0) && bidder != address(this)) {
            i_rwaCoin.safeTransfer(bidder, bidAmount);
        }
        
        // Return NFT to owner (contract owner in emergency)
        i_rwaNFT.safeTransferFrom(address(this), owner(), tokenId);
        
        emit AuctionCancelled(tokenId);
    }
    
    function emergencyWithdrawERC20(address token) external onlyOwner {
        IERC20 tokenContract = IERC20(token);
        uint256 balance = tokenContract.balanceOf(address(this));
        tokenContract.safeTransfer(owner(), balance);
        emit EmergencyWithdraw(token, balance);
    }
    
    function emergencyWithdrawNFT(uint256 tokenId) external onlyOwner {
        i_rwaNFT.safeTransferFrom(address(this), owner(), tokenId);
    }
}
