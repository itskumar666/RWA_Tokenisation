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
import {RWA_Coins} from "../CoinMintingAndManaging/RWA_Coins.sol";

pragma solidity ^0.8.20;

/* @title StakingCoin
    @author Ashutosh Kumar
    @notice This contract is used to stake coins for a specific period and earn rewards. 
    @notice when deployed, its being 10^6(1mil) coin will be minted to the contract address for rewarding stake holders.
    @notice The contract allows users to stake coins, and it checks for valid addresses and non-zero amounts.
    @notice The contract is designed to be used with a specific token, which is passed during deployment.
    @Important: Add contract address of RWA_Coins in constructor to mint coins to this contract address as a Minter.
    @Improvement uppdate stalePeriod Logic so that user dont get charge for withdrawing coins they staked before lock period.

    */

contract StakingCoin is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    error StakingCoin__NotZeroAmount();
    error StakingCoin__InvalidUserAddress();
    error StakingCoin__TokenNotAllowed();
    error StakingCoin__InsufficientBalance();
    error StakingCoin__InsufficientRewardBalance();
    error StakingCoin__UnderLockPeriod();
    error StakingCoin__NotZeroAddress();
    error StakingCoin__InsufficientContractBalance();
    error StakingCoin__InvalidRewardRate();
    error StakingCoin__InvalidLockPeriod();

    struct stakeInfo {
        uint256 rewardDebt;
        uint256 amount;
        uint256 lastUpdated;
    }

    IERC20 public immutable rwaCoin;
    address private RWA_CoinsAddress;
    uint256 private rewardRate;
    uint256 private totalCoinStakedInContract;
    // user should not withdraw coin before lock period else he will be fined
    uint256 private lockPeriod; 
    uint256 private minFine;

    // Storing stake info against user address
    mapping(address => stakeInfo) private stakes;

    event CoinStaked(
        address indexed from,
        address indexed tokenAddress,
        uint256 amount
    );
    event CoinWithdrawn(address indexed by, uint256 indexed amount);
    event RewardClaimed(address indexed by, uint256 indexed amount);
    event RewardUpdated(address indexed user, uint256 newRewardDebt);
    event FineApplied(address indexed user, uint256 fineAmount);
    event RewardRateChanged(uint256 oldRate, uint256 newRate);
    event LockPeriodChanged(uint256 oldPeriod, uint256 newPeriod);
    event MinFineChanged(uint256 oldFine, uint256 newFine);

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
        uint256 _rewardRate,
        uint256 _lockPeriod,
        uint256 _minFine
    ) Ownable(msg.sender) {
        if (_rwaCoinToken == address(0)) {
            revert StakingCoin__NotZeroAddress();
        }
        if (_totalCoinStakedInContract == 0) {
            revert StakingCoin__NotZeroAmount();
        }
        if (_rewardRate == 0) {
            revert StakingCoin__InvalidRewardRate();
        }
        if (_lockPeriod == 0) {
            revert StakingCoin__InvalidLockPeriod();
        }
        
        RWA_CoinsAddress = _rwaCoinToken;
        rwaCoin = IERC20(_rwaCoinToken);
        totalCoinStakedInContract = 0; // Initially no coins staked by users
        rewardRate = _rewardRate;
        lockPeriod = _lockPeriod;
        minFine = _minFine;
        
        // Minting initial coins to the contract address for rewards
        // RWA_Coins(RWA_CoinsAddress).mint(address(this), _totalCoinStakedInContract);
        // Note: This line is commented out for testing. In production, ensure the RWA_Coins contract
        // has already granted minter role to this contract before deployment.
    }
    function setRewardRate(uint256 newRate) external onlyOwner {
        if (newRate == 0) {
            revert StakingCoin__InvalidRewardRate();
        }
        uint256 oldRate = rewardRate;
        rewardRate = newRate;
        emit RewardRateChanged(oldRate, newRate);
    }

    function setLockPeriod(uint256 newPeriod) external onlyOwner {
        if (newPeriod == 0) {
            revert StakingCoin__InvalidLockPeriod();
        }
        uint256 oldPeriod = lockPeriod;
        lockPeriod = newPeriod;
        emit LockPeriodChanged(oldPeriod, newPeriod);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
    function setMinFine(uint256 _minFine) external onlyOwner {
        uint256 oldFine = minFine;
        minFine = _minFine;
        emit MinFineChanged(oldFine, _minFine);
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
        if (_amount == 0) {
            revert StakingCoin__NotZeroAmount();
        }
        if (_amount > stakes[msg.sender].amount) {
            revert StakingCoin__InsufficientBalance();
        }
        
        // Check stale period BEFORE updating rewards (which changes lastUpdated)
        bool shouldFine = _stalePeriod();
        
        _updateReward();
        
        uint256 actualWithdrawAmount = _amount;
        uint256 fineAmount = 0;

        if (shouldFine) {
            uint256 temp = _amount / 100; // 1% fine
            if (temp < minFine) {
                fineAmount = minFine;
            } else {
                fineAmount = temp;
            }
            
            // Ensure fine doesn't exceed withdrawal amount
            if (fineAmount > _amount) {
                fineAmount = _amount; // Fine can't be more than withdrawal amount
            }
            
            actualWithdrawAmount = _amount - fineAmount;
            
            // Ensure user has enough staked to cover the withdrawal
            if (stakes[msg.sender].amount < _amount) {
                revert StakingCoin__InsufficientBalance();
            }
            
            emit FineApplied(msg.sender, fineAmount);
        }

        // Transfer the actual amount user should receive (after fine deduction)
        rwaCoin.safeTransfer(msg.sender, actualWithdrawAmount);

        emit CoinWithdrawn(msg.sender, actualWithdrawAmount);

        // Deduct the full requested amount from user's stake
        stakes[msg.sender].amount -= _amount;
        
        // Update total staked (remove full amount including fine)
        totalCoinStakedInContract -= _amount;
        
        // Fine remains in contract as penalty
    }

    function claimPartialReward(
        uint256 _amount
    ) external nonReentrant whenNotPaused {
        if (_amount == 0) {
            revert StakingCoin__NotZeroAmount();
        }
        
        _updateReward();
        _claimReward(_amount);
        emit RewardClaimed(msg.sender, _amount);
    }

    function claimFullReward() external nonReentrant whenNotPaused {
        _updateReward();
        uint256 amount = stakes[msg.sender].rewardDebt;
        if (amount == 0) {
            return; // No reward to claim
        }
        _claimReward(amount);
        emit RewardClaimed(msg.sender, amount);
    }

    //////////////////////////////////
    // Internal & Private Functions //
    //////////////////////////////////

    function _updateReward() private {
        if (stakes[msg.sender].lastUpdated == 0) {
            stakes[msg.sender].lastUpdated = block.timestamp;
            return; // No previous stake, no reward to update
        }
        
        uint256 duration = block.timestamp - stakes[msg.sender].lastUpdated;
        if (duration == 0) {
            return; // No time passed
        }
        
        uint256 reward = (duration * rewardRate * stakes[msg.sender].amount) / 1e18;

        stakes[msg.sender].lastUpdated = block.timestamp;
        stakes[msg.sender].rewardDebt += reward;
        
        if (reward > 0) {
            emit RewardUpdated(msg.sender, stakes[msg.sender].rewardDebt);
        }
    }
    function _claimReward(uint256 _amount) private {
        // Allow reward claiming regardless of lock period - only withdrawals are fined
        
        if (stakes[msg.sender].rewardDebt == 0) {
            revert StakingCoin__InsufficientRewardBalance();
        }
        if (stakes[msg.sender].rewardDebt < _amount) {
            revert StakingCoin__InsufficientRewardBalance();
        }
        
        // Check contract has enough balance for rewards
        uint256 contractBalance = rwaCoin.balanceOf(address(this));
        uint256 availableForRewards = contractBalance - totalCoinStakedInContract;
        if (availableForRewards < _amount) {
            revert StakingCoin__InsufficientContractBalance();
        }
        
        rwaCoin.safeTransfer(msg.sender, _amount);
        stakes[msg.sender].rewardDebt -= _amount;
        
        // Note: Don't subtract from totalCoinStakedInContract as rewards come from separate pool
    }
    function _stalePeriod() private view returns (bool) {
        uint256 lastStakeTimeStamp = block.timestamp -
            stakes[msg.sender].lastUpdated;

        if (lastStakeTimeStamp < lockPeriod) {
            return true;
        } else {
            return false;
        }
    }
    function _stalePeriodError() private view  {
        uint256 lastStakeTimeStamp = block.timestamp -
            stakes[msg.sender].lastUpdated;

        if (lastStakeTimeStamp < lockPeriod) {
            revert StakingCoin__UnderLockPeriod();
        } 
    }
    ///////////////////////////////
    ///  External View Functions //
    ///////////////////////////////

    function getRewardRate() external view returns (uint256) {
        return rewardRate;
    }
    
    function getLockPeriod() external view returns (uint256) {
        return lockPeriod;
    }
    
    function getStakedAmount() external view returns (uint256) {
        return stakes[msg.sender].amount;
    }
    
    function getStakedAmountOf(address user) external view returns (uint256) {
        return stakes[user].amount;
    }
    
    function getRewardDebt() external view returns (uint256) {
        return stakes[msg.sender].rewardDebt;
    }
    
    function getRewardDebtOf(address user) external view returns (uint256) {
        return stakes[user].rewardDebt;
    }
    
    function getLastUpdated() external view returns (uint256) {
        return stakes[msg.sender].lastUpdated;
    }
    
    function getLastUpdatedOf(address user) external view returns (uint256) {
        return stakes[user].lastUpdated;
    }
    
    function getRWA_CoinsAddress() external view returns (address) {
        return RWA_CoinsAddress;
    }
    
    function getTotalCoinStakedInContract() external view returns (uint256) {
        return totalCoinStakedInContract;
    }
    
    function getMinFine() external view returns (uint256) {
        return minFine;
    }
    
    function getCurrentAPY() external view returns (uint256) {
        uint256 secondsInYear = 31536000;
        uint256 apy = (rewardRate * secondsInYear * 100) / 1e18;
        return apy; // returns APY as a % with 0 decimals
    }
    
    function getIfIWillBeFined() external view returns (bool) {
        return _stalePeriod();
    }
    
    function getIfUserWillBeFined(address user) external view returns (bool) {
        if (stakes[user].lastUpdated == 0) {
            return false; // No stake yet
        }
        uint256 lastStakeTimeStamp = block.timestamp - stakes[user].lastUpdated;
        return lastStakeTimeStamp < lockPeriod;
    }
    
    function getTimeUntilUnlock() external view returns (uint256) {
        if (stakes[msg.sender].lastUpdated == 0) {
            return 0; // No stake yet
        }
        uint256 elapsed = block.timestamp - stakes[msg.sender].lastUpdated;
        if (elapsed >= lockPeriod) {
            return 0; // Already unlocked
        }
        return lockPeriod - elapsed;
    }
    
    function getTimeUntilUnlockFor(address user) external view returns (uint256) {
        if (stakes[user].lastUpdated == 0) {
            return 0; // No stake yet
        }
        uint256 elapsed = block.timestamp - stakes[user].lastUpdated;
        if (elapsed >= lockPeriod) {
            return 0; // Already unlocked
        }
        return lockPeriod - elapsed;
    }
    
    function getCurrentReward() external view returns (uint256) {
        if (stakes[msg.sender].lastUpdated == 0 || stakes[msg.sender].amount == 0) {
            return stakes[msg.sender].rewardDebt;
        }
        
        uint256 duration = block.timestamp - stakes[msg.sender].lastUpdated;
        uint256 newReward = (duration * rewardRate * stakes[msg.sender].amount) / 1e18;
        
        return stakes[msg.sender].rewardDebt + newReward;
    }
    
    function getCurrentRewardOf(address user) external view returns (uint256) {
        if (stakes[user].lastUpdated == 0 || stakes[user].amount == 0) {
            return stakes[user].rewardDebt;
        }
        
        uint256 duration = block.timestamp - stakes[user].lastUpdated;
        uint256 newReward = (duration * rewardRate * stakes[user].amount) / 1e18;
        
        return stakes[user].rewardDebt + newReward;
    }
    
    function getAvailableRewardPool() external view returns (uint256) {
        uint256 contractBalance = rwaCoin.balanceOf(address(this));
        if (contractBalance <= totalCoinStakedInContract) {
            return 0;
        }
        return contractBalance - totalCoinStakedInContract;
    }
}
