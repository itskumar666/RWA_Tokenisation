// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAuctionHouse {
    // --- Events ---
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

    // --- Functions ---

    /**
     * @notice Allows a user to bid on an NFT currently under auction.
     * @param tokenId The ID of the NFT being bid on.
     * @param bidAmount The amount of ERC20 tokens being bid.
     */
    function bidOnNFT(uint256 tokenId, uint256 bidAmount) external;

    /**
     * @notice Ends the auction for a given NFT, transferring it to the winner.
     * Can be called manually or via automation.
     * @param tokenId The ID of the NFT whose auction is to be ended.
     */
    function endAuction(uint256 tokenId) external;

    /**
     * @notice Sets the auction duration for future auctions.
     * @param duration Duration in seconds.
     */
    function setAuctionDuration(uint256 duration) external;

    /**
     * @notice Sets the default starting price for auctions if not provided.
     * @param price Price in ERC20 units.
     */
    function setDefaultPrice(uint256 price) external;
}
