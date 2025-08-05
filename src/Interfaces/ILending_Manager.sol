// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ILendingManager
 * @dev Interface for the LendingManager contract.
 * Defines the external functions, events, and errors that other contracts can interact with.
 */
interface ILendingManager {
    // --- Structs ---
    struct LendingInfo {
        uint256 amount;
        uint8 interest; //max 30%
        uint256 minBorrow; //in units of coin
        uint256 returnPeriod;
    }

    struct BorrowingInfo {
        uint256 amount;
        uint256 tokenIdNFT;
        address lender;
        uint256 assetId;
        uint256 borrowTime; // timestamp when the coin was borrowed
        uint256 returnTime; // timestamp when the coin is expected to be returned
        bool isReturned; // flag to check if the coin is returned
    }

    // --- Errors ---
    error LendingManager__NotZeroAmount();
    error LendingManager__InvalidAddress();
    error LendingManager__InvalidToken();
    error LendingManager__ExpectedMinimumAmount();
    error LendingManager__InsufficientBalance();
    error LendingManager__NFTValueIsLowerThanAmount();
    error LendingManager__MoreThanAllowedInterest();
    error LendingManager__MinBorrowCantBeZero();
    error LendingManager__MinReturnPeriodNotSufficient();
    error LendingManager__InsufficientReturnBalance();

    // --- Events ---
    event coinDeposited(
        address indexed user,
        uint256 indexed amount,
        uint8 interest,
        uint8 minBorrow
    );

    event coinReturned(
        address indexed user,
        uint256 indexed amount,
        address indexed lender
    );

    // --- Configuration Functions ---

    /**
     * @notice Sets the minimum return period for loans.
     * Only callable by owner.
     * @param _minReturnPeriod The new minimum return period in seconds.
     */
    function setMinReturnPeriod(uint256 _minReturnPeriod) external;

    /**
     * @notice Sets the auction house address for liquidations.
     * Only callable by owner.
     * @param _auctionHouse The auction house contract address.
     */
    function setAddressAuctionHouse(address _auctionHouse) external;

    // --- Core Lending Functions ---

    /**
     * @notice Deposit coins into the lending pool to lend to borrowers.
     * @param _amount Amount of coins to deposit.
     * @param _interest Interest rate (max 30%).
     * @param minBorrow Minimum borrowable amount per loan.
     * @param _returnPeriod Return period in seconds.
     */
    function depositCoinToLend(
        uint256 _amount,
        uint8 _interest,
        uint8 minBorrow,
        uint256 _returnPeriod
    ) external;

    /**
     * @notice Borrow coins by providing an NFT as collateral.
     * @param _amount Amount to borrow.
     * @param _tokenIdNFT NFT token ID used as collateral.
     * @param _lender Lender address.
     * @param _assetId Asset ID from the RWA manager.
     */
    function borrowCoin(
        uint256 _amount,
        uint256 _tokenIdNFT,
        address _lender,
        uint256 _assetId
    ) external;

    /**
     * @notice Return borrowed coins to the lender, triggering NFT return on full repayment.
     * @param _lender Lender address.
     * @param _amount Amount returned.
     * @param _tokenIdNFT NFT token ID used as collateral for the loan.
     */
    function returnCoinToLender(
        address _lender,
        uint256 _amount,
        uint256 _tokenIdNFT
    ) external;

    /**
     * @notice Withdraw partial amount of lended coins.
     * @param _amount Amount to withdraw.
     */
    function withdrawPartialLendedCoin(uint256 _amount) external;

    /**
     * @notice Withdraw total lended coins and remove from lenders array.
     * @param _amount Amount to withdraw.
     */
    function withdrawtotalLendedCoin(uint256 _amount) external;

    // --- Automation Functions ---

    /**
     * @notice Called by Chainlink automation to check and handle liquidations of undercollateralized loans.
     */
    function performUpkeep() external;

    // --- View Functions ---

    /**
     * @notice Get lending information for a specific lender.
     * @param _lender The address of the lender.
     * @return LendingInfo struct containing lending details.
     */
    function getLendingInfo(address _lender) external view returns (LendingInfo memory);

    /**
     * @notice Get complete lending pool information for all lenders.
     * @return Array of LendingInfo structs.
     */
    function getCompleteLendingPool() external view returns (LendingInfo[] memory);

    /**
     * @notice Get borrowing information for a specific borrower.
     * @param _borrower The address of the borrower.
     * @return Array of BorrowingInfo structs.
     */
    function getborrowingInfo(address _borrower) external view returns (BorrowingInfo[] memory);

    /**
     * @notice Get the minimum return period.
     * @return The minimum return period in seconds.
     */
    function getMinReturnPeriod() external view returns (uint256);
}