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

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AuctionHouse is IERC721Receiver,Ownable{
    using SafeERC20 for IERC20;
    IERC721 private immutable i_rwaNFT;


    error AuctionHouse__NotZeroAddress();
    error AuctionHouse__TokenDoesNotExist();
    error AuctionHouse__InvalidAuction();
    error AuctionHouse__NotZeroAmount();
    error AuctionHouse__BidHigherThanCurrentHighest();
    error AuctionHouse__AuctionStillGoingOn();
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
    event auctionCreated(
        uint256 indexed tokenId,
        uint256 startingPrice,
        uint256 endTime
    );
    event AuctionHouse__AuctionEndedWinnerAnnounced(
        uint256 indexed tokenId,
        address indexed winner,
        uint256 winningBid
    );

    constructor(address rwaNFT,address rwaCoin,uint256 _duration,address owner,uint256 _defaultPrice) Ownable(owner) {
        if (rwaCoin == address(0)) {
            revert AuctionHouse__NotZeroAddress();
        }
        if( _duration == 0) {
            revert AuctionHouse__NotZeroAmount();
        }
        if (defaultPrice == 0) {
            revert AuctionHouse__NotZeroAmount();
        }
        i_rwaCoin = IERC20(rwaCoin);
        i_rwaNFT = IERC721(rwaNFT);
        auctionDuration = _duration;
        defaultPrice = _defaultPrice;

    }

    modifier notZeroAmount(uint256 amount) {
       if(amount == 0) {
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
    function setAuctionDuration(uint256 duration) external onlyOwner notZeroAmount(duration) {
        auctionDuration = duration;
    }   
    function setDefaultPrice(uint256 price) external onlyOwner notZeroAmount(price) {
        defaultPrice = price;
    }


    function bidOnNFT(uint256 tokenId, uint256 bidAmount) external notZeroAmount(bidAmount) notZeroAddress(msg.sender) {
        Auction storage auction = auctions[tokenId];
     
        if (bidAmount <= auction.highestBid && bidAmount < auction.startingPrice) {
            revert AuctionHouse__BidHigherThanCurrentHighest();
        }
        if (block.timestamp > auction.endTime) {
            revert AuctionHouse__InvalidAuction();
        }

        // Refund the previous highest bidder
        if (auction.highestBidder != address(0)) {
            i_rwaCoin.safeTransfer(auction.highestBidder, auction.highestBid);
  
        }
        // Transfer the bid amount from the bidder to the auction house
        i_rwaCoin.safeTransferFrom(msg.sender, address(this), bidAmount);

        auction.highestBid = bidAmount;
        auction.highestBidder = msg.sender;
        emit BidPlaced(tokenId, msg.sender, bidAmount);
       
    }
        //function to declare. winner of auction can be checked manually or it will be called by chainlink automation


    function endAuction(uint256 tokenId) external  {
        Auction storage auction = auctions[tokenId];
      
        if (block.timestamp < auction.endTime) {
            revert AuctionHouse__AuctionStillGoingOn();
        }

        // Transfer the NFT to the highest bidder
        if (auction.highestBidder != address(0)) {
            i_rwaNFT.safeTransferFrom(address(this), auction.highestBidder, tokenId);
            delete auctions[tokenId];
            emit AuctionHouse__AuctionEndedWinnerAnnounced(
                tokenId,
                auction.highestBidder,
                auction.highestBid
            );
        } else {
            if(auction.highestBid == auction.startingPrice) {
               delete auctions[tokenId];  
               emit AuctionHouse__AuctionEndedWinnerAnnounced(
                    tokenId,
                    address(this),
                    auction.startingPrice
                );}
            
        }
    }

    function _createAuction(
        uint256 tokenId,
        uint256 startingPrice
    ) internal notZeroAmount(startingPrice) notZeroAddress(msg.sender) {
      
        auctions[tokenId] = Auction({
            tokenId: tokenId,
            startingPrice: startingPrice,
            endTime: block.timestamp + auctionDuration,
            highestBid: startingPrice,
            highestBidder: address(this)
        });
        emit auctionCreated(
            tokenId,
            startingPrice,
            block.timestamp + auctionDuration
        );
        emit NFTReceived(msg.sender, msg.sender, tokenId, "");
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
      
        if (data.length > 0) {
            // If data is provided, it can be used to set the starting price or other auction parameters
            uint256 startingPrice = abi.decode(data, (uint256));
            _createAuction(tokenId, startingPrice);
        } else {
            // If no data is provided, create a default auction with a starting price of 0
            _createAuction(tokenId, 100); // Default starting price
        }
        tokenIdsArray.push(tokenId);
        emit NFTReceived(operator, from, tokenId, data);

        return IERC721Receiver.onERC721Received.selector;
    }
}
