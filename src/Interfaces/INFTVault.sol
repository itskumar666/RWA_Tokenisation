// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title INFTVault
 * @dev Interface for the NFTVault contract.
 * Defines the external functions, events, and errors that other contracts can interact with.
 */
interface INFTVault {
    // --- Structs ---
    struct NFTInfo {
        uint256 tokenId;
        address owner;
        uint256 value; // Value of the NFT in terms of borrowed amount
    }

    // --- Errors ---
    error NFTVault__NotZeroAddress();
    error NFTVault__TokenDoesNotExist();

    // --- Events ---
    event NFTDeposited(address indexed user, uint256 indexed tokenId);
    event NFTWithdrawn(address indexed user, uint256 indexed tokenId);
    event NFTTransferToAuctionHouse(address indexed user, uint256 indexed tokenId);

    // --- Functions ---

    /**
     * @dev Deposits an NFT into the vault.
     * Only callable by the owner (LendingManager) and when not paused.
     * The actual NFT transfer from the borrower to this contract is expected to be handled
     * by the calling contract (LendingManager) before this function is called,
     * or this function assumes the NFT is already transferred.
     * @param tokenId The ID of the NFT to deposit.
     * @param _borrower The address of the user who is depositing the NFT.
     * @param _NFTValue The value of the NFT in terms of borrowed amount.
     */
    function depositNFT(uint256 tokenId, address _borrower, uint256 _NFTValue) external;

    /**
     * @dev Transfers an NFT from the vault back to the borrower.
     * Only callable by the owner (LendingManager) and when not paused.
     * @param tokenId The ID of the NFT to transfer.
     * @param _borrower The address of the borrower to receive the NFT.
     */
    function tokenTransferToBorrower(uint256 tokenId, address _borrower) external;

    /**
     * @dev Transfers an NFT from the vault to a lender.
     * Only callable by the owner (LendingManager) and when not paused.
     * @param tokenId The ID of the NFT to transfer.
     * @param _lender The address of the lender to receive the NFT.
     * @param _borrower The address of the borrower who originally deposited the NFT.
     */
    function tokenTransferToLender(uint256 tokenId, address _lender, address _borrower) external;

    /**
     * @dev Transfers an NFT from the vault to an auction house during liquidation.
     * Only callable by the owner (LendingManager) and when not paused.
     * @param tokenId The ID of the NFT to transfer.
     * @param _auctionHouse The address of the auction house to receive the NFT.
     */
    function tokenTransferToAuctionHouseOnLiquidation(uint256 tokenId, address _auctionHouse) external;

    /**
     * @dev Handles the receipt of an NFT.
     * @param operator The address which called `safeTransferFrom` function.
     * @param from The address which previously owned the token.
     * @param tokenId The NFT identifier which is being transferred.
     * @param data Additional data with no specified format.
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4);
}