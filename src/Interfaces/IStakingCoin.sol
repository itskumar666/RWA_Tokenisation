// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IStakingCoin
 * @dev Interface for the StakingCoin contract.
 * Defines the external functions, events, and errors that other contracts can interact with.
 */
interface IStakingCoin {
    // --- Structs ---
    struct stakeInfo {
        uint256 rewardDebt;
        uint256 amount;
        uint256 lastUpdated;
    }

    // --- Errors ---
    error StakingCoin__NotZeroAmount();
    error StakingCoin__InvalidUserAddress();
    error StakingCoin__TokenNotAllowed();
    error StakingCoin__InsufficientBalance();
    error StakingCoin__InsufficientRewardBalance();
    error StakingCoin__UnderLockPeriod();

    // --- Events ---
    event CoinStaked(
        address indexed from,
        address indexed tokenAddress,
        uint256 amount
    );
    event CoinWithdrawn(address indexed by, uint256 indexed amount);
    event RewardClaimed(address indexed by, uint256 indexed amount);

    // --- Configuration Functions ---

    /**
     * @notice Sets the reward rate for staking.
     * Only callable by owner.
     * @param newRate The new reward rate.
     */
    function setRewardRate(uint256 newRate) external;

    /**
     * @notice Sets the lock period for staking.
     * Only callable by owner.
     * @param newPeriod The new lock period in seconds.
     */
    function setLockPeriod(uint256 newPeriod) external;

    /**
     * @notice Pauses the contract operations.
     * Only callable by owner.
     */
    function pause() external;

    /**
     * @notice Unpauses the contract operations.
     * Only callable by owner.
     */
    function unpause() external;

    /**
     * @notice Sets the minimum fine amount.
     * Only callable by owner.
     * @param _minFine The new minimum fine amount.
     */
    function setMinFine(uint16 _minFine) external;

    // --- Core Staking Functions ---

    /**
     * @notice Stakes coins for a specific period to earn rewards.
     * @param _tokenAddress The address of the token to stake (must be RWA_Coins).
     * @param _amount The amount of coins to stake.
     */
    function stakeCoin(address _tokenAddress, uint256 _amount) external;

    /**
     * @notice Withdraws staked coins. May incur a fine if withdrawn before lock period.
     * @param _amount The amount of coins to withdraw.
     */
    function withdrawCoin(uint256 _amount) external;

    /**
     * @notice Claims a partial amount of earned rewards.
     * @param _amount The amount of rewards to claim.
     */
    function claimPartialReward(uint256 _amount) external;

    /**
     * @notice Claims all earned rewards.
     */
    function claimFullReward() external;

    // --- View Functions ---

    /**
     * @notice Gets the current reward rate.
     * @return The reward rate.
     */
    function getRewardRate() external view returns (uint256);

    /**
     * @notice Gets the staked amount for the caller.
     * @return The amount of coins staked by the caller.
     */
    function getStakedAmount() external view returns (uint256);

    /**
     * @notice Gets the reward debt for the caller.
     * @return The amount of rewards earned by the caller.
     */
    function getRewardDebt() external view returns (uint256);

    /**
     * @notice Gets the last updated timestamp for the caller's stake.
     * @return The timestamp when the caller's stake was last updated.
     */
    function getLastUpdated() external view returns (uint256);

    /**
     * @notice Gets the RWA Coins contract address.
     * @return The address of the RWA Coins contract.
     */
    function getRWA_CoinsAddress() external view returns (address);

    /**
     * @notice Gets the total amount of coins staked in the contract.
     * @return The total staked amount in the contract.
     */
    function gettotalCoinStakedInContract() external view returns (uint256);

    /**
     * @notice Gets the minimum fine amount.
     * @return The minimum fine amount.
     */
    function getMinFine() external view returns (uint256);

    /**
     * @notice Calculates the current APY (Annual Percentage Yield).
     * @return The current APY as a percentage.
     */
    function getCurrentAPY() external view returns (uint256);

    /**
     * @notice Checks if the caller will be fined for withdrawing now.
     * @return Boolean indicating if withdrawal will incur a fine.
     */
    function getIfIWillBeFined() external view returns (bool);

    /**
     * @notice Gets the RWA Coin token contract interface.
     * @return The IERC20 interface of the RWA Coin token.
     */
    function rwaCoin() external view returns (address);
}