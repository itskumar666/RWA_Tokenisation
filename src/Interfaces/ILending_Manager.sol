// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILendingManager {
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

    // --- External Functions ---

    /**
     * @notice Sets the minimum return period for loans.
     * @param _minReturnPeriod The new minimum return period in seconds.
     */
    function setMinReturnPeriod(uint256 _minReturnPeriod) external;

    /**
     * @notice Sets the auction house address for liquidations.
     * @param _auctionHouse The auction house contract address.
     */
    function setAddressAuctionHouse(address _auctionHouse) external;

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
     * @notice Called by Chainlink automation to check and handle liquidations of undercollateralized loans.
     */
    function performUpkeep() external;
}
