// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStakingCoin {
    // Control functions
    function pause() external;
    function unpause() external;
    function setRewardRate(uint256 newRate) external;
    function setLockPeriod(uint256 newPeriod) external;
    function setMinFine(uint256 _minFine) external;

    // Staking functions
    function stakeCoin(address _tokenAddress, uint256 _amount) external;
    function withdrawCoin(uint256 _amount) external;
    function claimPartialReward(uint256 _amount) external;
    function claimFullReward() external;

    // View functions
    function getRewardRate() external view returns (uint256);
    function getStakedAmount() external view returns (uint256);
    function getRewardDebt() external view returns (uint256);
    function getLastUpdated() external view returns (uint256);
    function getRWA_CoinsAddress() external view returns (address);
    function gettotalCoinStakedInContract() external view returns (uint256);
    function getMinFine() external view returns (uint256);
    function getCurrentAPY() external view returns (uint256);
    function getIfIWillBeFined() external view returns (bool);
}
