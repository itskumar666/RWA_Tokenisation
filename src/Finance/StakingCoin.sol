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

// SPDX-License-Identifier: MIT
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

pragma solidity ^0.8.20;

/* @title StakingCoin
    @author Ashutosh Kumar
    @notice This contract is used to stake coins for a specific period and earn rewards. 
    @notice when deployed, its being 10^6(1mil) coin will be minted to the contract address for rewarding stake holders.
    @notice The contract allows users to stake coins, and it checks for valid addresses and non-zero amounts.
    @notice The contract is designed to be used with a specific token, which is passed during deployment.

    */

contract StakingCoin is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    error StakingCoin__NotZeroAmount();
    error StakingCoin__InvalidUserAddress();
    error StakingCoin__TokenNotAllowed();
    error StakingCoin__InsufficientBalance();
    error StakingCoin__InsufficientRewardBalance();

    struct stakeInfo {
        uint256 rewardDebt;
        uint256 amount;
        uint256 lastUpdated;
    }

    IERC20 public immutable rwaCoin;
    address private RWA_CoinsAddress;
    uint256 private rewardRate;
    uint256 private totalCoinStakedInContract;
    uint256 private lockPeriod;

    // Storing stake info against user address
    mapping(address => stakeInfo) private stakes;

    event CoinStaked(
        address indexed from,
        address indexed tokenAddress,
        uint256 amount
    );
    event CoinWithdrawen(address indexed by, uint256 indexed amount);
    event RewardClaimed(address indexed by, uint256 indexed amount);

    //Modifiers
    modifier isAllowed(address token, address user) {
        if (user == address(0)) {
            revert StakingCoin__InvalidUserAddress();
        }
        if (token != RWA_CoinsAddress) {
            revert StakingCoin__TokenNotAllowed();
        }

        _;
    }
    modifier notZeroAmount(uint256 _amount) {
        if (_amount <= 0) {
            revert StakingCoin__NotZeroAmount();
        }
        _;
    }

    // only RWA_Coin minted token can be staked on this
    constructor(
        address _rwaCoinToken,
        uint256 _totalCoinStakedInContract,
        uint256 _rewardReward,
        uint256 _lockPeriod
    ) Ownable(msg.sender) {
        RWA_CoinsAddress = _rwaCoinToken;
        rwaCoin = IERC20(_rwaCoinToken);
        totalCoinStakedInContract = _totalCoinStakedInContract;
        rewardRate = _rewardReward;
        lockPeriod = _lockPeriod;
    }
    function setRewardRate(uint256 newRate) external onlyOwner {
        rewardRate = newRate;
    }

    function setLockPeriod(uint256 newPeriod) external onlyOwner {
        lockPeriod = newPeriod;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /*
     * @params _tokenAddress RWA_Coin token address
     * @params _amount  Amount of coin to be staked
     * @Notice takes an address and amount of the token to be staked
     * and checks if it is valid token address and amount is not zero
     * then update the rewards of the user and emit an event
     */

    function stakeCoin(
        address _tokenAddress,
        uint256 _amount
    )
        external
        isAllowed(_tokenAddress, msg.sender)
        notZeroAmount(_amount)
        nonReentrant
        whenNotPaused
    {
        rwaCoin.safeTransferFrom(msg.sender, address(this), _amount);
        // Emit an event for staking
        emit CoinStaked(msg.sender, _tokenAddress, _amount);
        _updateReward();
        stakes[msg.sender].amount = stakes[msg.sender].amount + _amount;
        totalCoinStakedInContract += _amount;
    }
    function withdrawCoin(uint256 _amount) external nonReentrant whenNotPaused {
        if (_amount > stakes[msg.sender].amount) {
            revert StakingCoin__InsufficientBalance();
        }
        emit CoinWithdrawen(msg.sender, _amount);
        _updateReward();
        stakes[msg.sender].amount = stakes[msg.sender].amount - _amount;

        totalCoinStakedInContract -= _amount;
    }

    function claimPartialReward(
        uint256 _amount
    ) external nonReentrant whenNotPaused {
        _claimReward(_amount);
        emit RewardClaimed(msg.sender, _amount);
    }
    function claimFullReward() external nonReentrant whenNotPaused {
        uint256 amount = stakes[msg.sender].rewardDebt;
        _claimReward(amount);
        emit RewardClaimed(msg.sender, amount);
    }

    //It takes last rewardDebt and add
    function _updateReward() private {
        if (stakes[msg.sender].lastUpdated == 0) {
            stakes[msg.sender].lastUpdated = block.timestamp;
            return; // No previous stake, no reward to update
        }
        uint256 duration = block.timestamp - stakes[msg.sender].lastUpdated;
        uint256 reward = (duration * rewardRate * stakes[msg.sender].amount) /
            1e18;

        stakes[msg.sender].lastUpdated = block.timestamp;
        stakes[msg.sender].rewardDebt += reward;
    }
    function _claimReward(uint256 _amount) private {
        if (stakes[msg.sender].rewardDebt == 0) {
            return; // No reward to claim
        }
        if (stakes[msg.sender].rewardDebt < _amount) {
            revert StakingCoin__InsufficientRewardBalance();
        }
        rwaCoin.safeTransfer(msg.sender, _amount);
        stakes[msg.sender].rewardDebt = stakes[msg.sender].rewardDebt - _amount;
        totalCoinStakedInContract -= _amount;
    }
    ///////////////////////////////
    ///  External View Functions //
    ///////////////////////////////

    function getRewardRate() external view returns (uint256) {
        return rewardRate;
    }
    function getStakedAmount() external view returns (uint256) {
        return stakes[msg.sender].amount;
    }
    function getRewardDebt() external view returns (uint256) {
        return stakes[msg.sender].rewardDebt;
    }
    function getLastUpdated() external view returns (uint256) {
        return stakes[msg.sender].lastUpdated;
    }
    function getRWA_CoinsAddress() external view returns (address) {
        return RWA_CoinsAddress;
    }
    function gettotalCoinStakedInContract() external view returns (uint256) {
        return totalCoinStakedInContract;
    }
    function getCurrentAPY() external view returns (uint256) {
    uint256 secondsInYear = 31536000;
    uint256 apy = (rewardRate * secondsInYear * 100) / 1e18;
    return apy; // returns APY as a % with 0 decimals
}

}
