// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILendingVault {
    /////////////
    // Control //
    /////////////

    function pause() external;
    function unpause() external;
    function changeMinBorrowCapacity(uint256 _newCapacity) external;

    /////////////////////
    // State Modifiers //
    /////////////////////

    function depositCoin(address _user, uint256 _amount) external;
    function borrowCoin(address _user, uint256 _amount) external;
    function withdrawDepositedCoin(address _user, uint256 _amount) external;
    function returnWithdrawnCoin(address _user, uint256 _amount) external;

    ///////////////////////
    // State View Access //
    ///////////////////////

    function getUserBalances(address user) external view returns (uint256 credit, uint256 debt);
    function getTotalPoolState() external view returns (uint256 totalDeposited, uint256 totalBorrowed);
    function getMinBorrowCapacity() external view returns (uint256);
    function getRwaCoinAddress() external view returns (address);
    function getTotalCoinInPool() external view returns (uint256);
    function getUserCreditBalance(address user) external view returns (uint256);
    function getUserDebitBalance(address user) external view returns (uint256);
    function getTotalDepositedCoins() external view returns (uint256);
    function getTotalBorrowedCoins() external view returns (uint256);
}
