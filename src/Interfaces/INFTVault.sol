// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title INFTVault
 * @dev Interface for the NFTVault contract.
 * Defines the external functions, events, and errors that other contracts can interact with.
 */
interface INFTVault {
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
     */
    function depositNFT(uint256 tokenId, address _borrower) external;

    /**
     * @dev Transfers an NFT from the vault back to the borrower.
     * Only callable by the owner (LendingManager) and when not paused.
     * @param tokenId The ID of the NFT to transfer.
     * @param _borrower The address of the borrower to receive the NFT.
     */
    function tokenTransferToBorrower(uint256 tokenId, address _borrower) external;

    /**
     * @dev Transfers an NFT from the vault to an auction house during liquidation.
     * Only callable by the owner (LendingManager) and when not paused.
     * @param tokenId The ID of the NFT to transfer.
     * @param _auctionHouse The address of the auction house to receive the NFT.
     */
    function tokenTransferToAuctionHouseOnLiquidation(uint256 tokenId, address _auctionHouse) external;

    /**
     * @dev Returns the owner of the contract.
     */
    function owner() external view returns (address);

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view returns (bool);
}
