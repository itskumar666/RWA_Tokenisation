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
pragma solidity ^0.8.20;
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {INFTVault} from "../Interfaces/INFTVault.sol";
import {IRWA_Manager} from "../Interfaces/IRWA_Manager.sol";
import {RWA_Types} from "../CoinMintingAndManaging/RWA_Types.sol";
import {InterestAndHealthFactor} from "../Library/InterestAndHealthFactor.sol";

/* 
    @title Lending Manager
    @author Ashutosh Kumar
    @notice This contract is used to lend coins to users, it allows users to deposit coins, borrow coins, withdraw coins and return borrowed coins.
    @Notice this contract also accept nft as collateral for borrowing coins, it checks if the nft is valid and then transfers the coin to the user.
    @notice The contract is designed to be used with a specific token, which is passed during deployment.
    @dev This contract is pausable and can be paused by the owner.
    @dev This contract is protected by OpenZeppelin's ReentrancyGuard to prevent reentrancy attacks.
    @dev This contract will control Lending vault contract to receive and update coins.
    @dev it will also check for liquidity and borrowing limits.
    @dev this will also check user collateral health and auction them for sale for undercollateralized loans. 
*/
contract LendingManager is ReentrancyGuard, Pausable, Ownable {
    using SafeERC20 for IERC20;
    using RWA_Types for RWA_Types.RWA_Info;

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
    IRWA_Manager private immutable i_rwaManager;
    IERC20 private immutable i_rwaCoin;
    IERC721 private immutable i_rwaNft;
    INFTVault private immutable i_nftVault;
    uint16 constant MAX_ITERATIONS_PER_CALL = 200;
    uint256 private lastProcessedBorrowerIndex = 0;
    address[] private borroweraddressArray; // array of borrower addresses
    address private auctionHouse; // address of the auction house for liquidating NFTs
    uint256 private minReturnPeriod; // minimum return period in seconds
    address[] private lendersArray;

    mapping(address user => LendingInfo lendingInfo) private i_lendingPool;
    mapping(address user => BorrowingInfo[]) private i_borrowingPoolArray;
    mapping(uint256 tokenId => address lender) private i_tokenLender;

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
    
    event LiquidationCycleCompleted(
        uint256 liquidationsProcessed,
        uint256 iterationsCompleted,
        uint256 lastProcessedBorrowerIndex
    );

    modifier onlyValidAddress(address user) {
        if (user == address(0)) {
            revert LendingManager__InvalidAddress();
        }
        _;
    }
    modifier onlyValidAmount(uint256 amount) {
        if (amount <= 0) {
            revert LendingManager__NotZeroAmount();
        }
        _;
    }

    constructor(
        address rwaCoin,
        address rwaNft,
        address nftVault,
        address RWA_Manager,
        uint256 _minReturnPeriod,
        address _auctionHouse
    ) Ownable(msg.sender) {
        if (
            rwaCoin == address(0) ||
            rwaNft == address(0) ||
            nftVault == address(0) ||
            RWA_Manager == address(0)
        ) {
            revert LendingManager__InvalidAddress();
        }
        if (_minReturnPeriod <= 0) {
            revert LendingManager__MinReturnPeriodNotSufficient();
        }
        auctionHouse = _auctionHouse;
        i_rwaCoin = IERC20(rwaCoin);
        i_rwaNft = IERC721(rwaNft);
        i_nftVault = INFTVault(nftVault);
        i_rwaManager = IRWA_Manager(RWA_Manager);
        minReturnPeriod = _minReturnPeriod; // minimum return period in seconds
    }

    function setMinReturnPeriod(uint256 _minReturnPeriod) external onlyOwner {
        minReturnPeriod = _minReturnPeriod;
    }
    function setAddressAuctionHouse(address _auctionHouse) external onlyOwner {
        if (_auctionHouse == address(0)) {
            revert LendingManager__InvalidAddress();
        }
        auctionHouse = _auctionHouse;
    }

    function depositCoinToLend(
        uint256 _amount,
        uint8 _interest,
        uint8 minBorrow,
        uint256 _returnPeriod
    )
        external
        nonReentrant
        whenNotPaused
        onlyValidAddress(msg.sender)
        onlyValidAmount(_amount)
    {
        if (_amount <= 0) {
            revert LendingManager__NotZeroAmount();
        }
        if (_interest > 30) {
            revert LendingManager__MoreThanAllowedInterest();
        }
        if (minBorrow <= 0) {
            revert LendingManager__MinBorrowCantBeZero();
        }
        if (_returnPeriod <= minReturnPeriod) {
            revert LendingManager__MinReturnPeriodNotSufficient();
        }
        lendersArray.push(msg.sender);

        i_rwaCoin.safeTransferFrom(msg.sender, address(this), _amount);
        _depositCoin(_amount, _interest, minBorrow, _returnPeriod);
        emit coinDeposited(msg.sender, _amount, _interest, minBorrow);
    }
    function borrowCoin(
        uint256 _amount,
        uint256 _tokenIdNFT,
        address _lender,
        uint256 _assetId
    )
        external
        nonReentrant
        whenNotPaused
        onlyValidAmount(_amount)
        onlyValidAddress(msg.sender)
    {
        LendingInfo storage lendingInfo = i_lendingPool[_lender];

        // Get the RWA info as a struct instead of destructuring
        RWA_Types.RWA_Info memory rwaInfo = i_rwaManager
            .getUserRWAInfoagainstRequestId(_assetId);

        if (rwaInfo.owner != msg.sender) {
            revert LendingManager__InvalidToken();
        }
        if (_amount < lendingInfo.minBorrow) {
            revert LendingManager__ExpectedMinimumAmount();
        }
        if (_amount > lendingInfo.amount) {
            revert LendingManager__InsufficientBalance();
        }
        uint256 interestAmount = _calculateInterest(
            _amount,
            lendingInfo.interest,
            lendingInfo.returnPeriod
        );

        if (rwaInfo.valueInUSD < _amount + interestAmount) {
            revert LendingManager__NFTValueIsLowerThanAmount();
        }
        uint256 NFTValue = _amount + interestAmount;
        i_rwaNft.safeTransferFrom(msg.sender, address(i_nftVault), _tokenIdNFT);
        i_rwaCoin.safeTransfer(msg.sender, _amount);
        _borrowCoin(_amount, _tokenIdNFT, _lender, _assetId);
        i_nftVault.depositNFT(_tokenIdNFT, msg.sender, NFTValue);
    }
    function returnCoinToLender(
        address _lender,
        uint256 _amount,
        uint _tokenIdNFT
    ) external nonReentrant whenNotPaused {
        if (_amount <= 0) {
            revert LendingManager__NotZeroAmount();
        }
        if (_lender == address(0)) {
            revert LendingManager__InvalidAddress();
        }

        // Update the borrowing info
        BorrowingInfo[] storage borrowings = i_borrowingPoolArray[msg.sender];
        for (uint256 i = 0; i < borrowings.length; i++) {
            if (
                borrowings[i].tokenIdNFT == _tokenIdNFT &&
                !borrowings[i].isReturned
            ) {
                borrowings[i].returnTime = block.timestamp;
                uint256 interestAmount = _calculateInterest(
                    _amount,
                    i_lendingPool[_lender].interest,
                    block.timestamp - borrowings[i].borrowTime
                );
                if (interestAmount + borrowings[i].amount > _amount) {
                    revert LendingManager__InsufficientReturnBalance();
                }
                borrowings[i].isReturned = true;
                 i_lendingPool[_lender].amount += _amount + interestAmount;
                borrowings[i].amount = 0; // Reset the amount to zero after return
                i_tokenLender[_tokenIdNFT] = address(0); // Clear the lender for the NFT
                 i_rwaCoin.safeTransferFrom(msg.sender, address(this), _amount);
                // i_rwaCoin.safeTransfer(_lender, _amount + interestAmount);
                i_nftVault.tokenTransferToBorrower(_tokenIdNFT, msg.sender);
              
                break;
            }
        }
        // Check if all borrowings are now returned, then clear storage
        bool allReturned = true;
        for (uint256 j = 0; j < borrowings.length; j++) {
            if (!borrowings[j].isReturned) {
                allReturned = false;
                break;
            }
        }
        if (allReturned) {
            delete i_borrowingPoolArray[msg.sender];
        }
        emit coinReturned(msg.sender, _amount, _lender);
    }
    function withdrawPartialLendedCoin(uint256 _amount) external {
        _withdrawLendedCoin(_amount, msg.sender);
    }
    function withdrawtotalLendedCoin(uint256 _amount) external {
        _withdrawLendedCoin(_amount, msg.sender);
        for (uint256 i = 0; i < lendersArray.length; i++) {
            if (lendersArray[i] == msg.sender) {
                lendersArray[i] = lendersArray[lendersArray.length - 1];
                lendersArray.pop();
                break;
            }
        }
    }

    // function changeMinBorrowCapacity(
    //     address _lender,
    //     uint256 _newCapacity
    // ) external onlyOwner {
    //     if (_newCapacity <= 0) {
    //         revert LendingManager__MinBorrowCantBeZero();
    //     }
    //      i_nftVault.changeMinBorrowCapacity(_lender, _newCapacity);
    //     i_lendingPool[_lender].minBorrow = _newCapacity;
    // }

    // this function will be called by chainlink automation on fixed interval

    function performUpkeep() external nonReentrant {
        uint256 borrowersLength = borroweraddressArray.length;
        
        // Exit early if no borrowers
        if (borrowersLength == 0) {
            return;
        }
        
        uint256 iterationCount = 0;
        uint256 liquidationCount = 0;
        uint256 startBorrowerIndex = lastProcessedBorrowerIndex;
        uint256 currentBorrowerIndex = startBorrowerIndex;
        
        // Process borrowers in a round-robin fashion
        do {
            address borrower = borroweraddressArray[currentBorrowerIndex];
            uint256 loansLength = i_borrowingPoolArray[borrower].length;
            
            // Process all loans for current borrower (reverse iteration for safe array modification)
            for (uint256 i = loansLength; i > 0; i--) {
                uint256 index = i - 1;
                BorrowingInfo storage borrowing = i_borrowingPoolArray[borrower][index];
                
                iterationCount++;
                
                // Check if loan is overdue and needs liquidation
                if (!borrowing.isReturned && borrowing.returnTime < block.timestamp) {
                    // LIQUIDATION PROCESS
                    
                    // 1. Transfer NFT to auction house
                    i_nftVault.tokenTransferToAuctionHouseOnLiquidation(
                        borrowing.tokenIdNFT,
                        auctionHouse
                    );
                    
                    // 2. Repay lender from contract balance
                    i_rwaCoin.safeTransfer(
                        i_tokenLender[borrowing.tokenIdNFT],
                        borrowing.amount
                    );
                    
                    // 3. Update borrowing state
                    borrowing.isReturned = true;
                    
                    // 4. Remove borrowing from array (safe removal during reverse iteration)
                    if (index != loansLength - 1) {
                        i_borrowingPoolArray[borrower][index] = i_borrowingPoolArray[borrower][loansLength - 1];
                    }
                    i_borrowingPoolArray[borrower].pop();
                    
                    // 5. Clear lender mapping
                    i_tokenLender[borrowing.tokenIdNFT] = address(0);
                    
                    liquidationCount++;
                    
                    // Update loansLength after removal
                    loansLength = i_borrowingPoolArray[borrower].length;
                }
                
                // Exit if we've reached max iterations for this call
                if (iterationCount >= MAX_ITERATIONS_PER_CALL) {
                    lastProcessedBorrowerIndex = currentBorrowerIndex;
                    return;
                }
            }
            
            // Move to next borrower (circular)
            currentBorrowerIndex = (currentBorrowerIndex + 1) % borrowersLength;
            
            // Continue until we complete full cycle or reach iteration limit
        } while (currentBorrowerIndex != startBorrowerIndex && iterationCount < MAX_ITERATIONS_PER_CALL);
        
        // If we completed a full cycle, reset to start from beginning next time
        if (currentBorrowerIndex == startBorrowerIndex) {
            lastProcessedBorrowerIndex = 0;
        } else {
            lastProcessedBorrowerIndex = currentBorrowerIndex;
        }
        
        // Emit event for monitoring (optional)
        emit LiquidationCycleCompleted(liquidationCount, iterationCount, lastProcessedBorrowerIndex);
    }

    function _depositCoin(
        uint256 _amount,
        uint8 _interest,
        uint8 minBorrow,
        uint256 _returnPeriod
    ) internal {
        i_lendingPool[msg.sender].amount += _amount;
        i_lendingPool[msg.sender].interest = _interest;
        i_lendingPool[msg.sender].minBorrow = minBorrow;
        i_lendingPool[msg.sender].returnPeriod = _returnPeriod;
    }
    function _borrowCoin(
        uint256 _amount,
        uint256 _tokenIdNFT,
        address _lender,
        uint256 _assetId
    ) internal {
        BorrowingInfo memory newBorrowing = BorrowingInfo({
            amount: _amount,
            tokenIdNFT: _tokenIdNFT,
            lender: _lender,
            assetId: _assetId,
            borrowTime: block.timestamp,
            returnTime: block.timestamp + i_lendingPool[_lender].returnPeriod,
            isReturned: false
        });

        // Push to the user's borrow history array
        i_borrowingPoolArray[msg.sender].push(newBorrowing);
        i_tokenLender[_tokenIdNFT] = _lender; // Store the lender for the NFT

        i_lendingPool[_lender].amount -= _amount;
        // Add the borrower address to the array if not already present
        bool exists = false;
        for (uint256 i = 0; i < borroweraddressArray.length; ) {
            if (borroweraddressArray[i] == msg.sender) {
                exists = true;
                break;
            }
            unchecked {
                i++;
            }
        }
        if (!exists) {
            borroweraddressArray.push(msg.sender);
        }
    }

    function _withdrawLendedCoin(
        uint256 _amount,
        address _lender
    ) private nonReentrant whenNotPaused onlyValidAddress(msg.sender) {
        if (_amount <= 0) {
            revert LendingManager__NotZeroAmount();
        }
        if (_lender == address(0)) {
            revert LendingManager__InvalidAddress();
        }
        if (i_lendingPool[_lender].amount < _amount) {
            revert LendingManager__InsufficientBalance();
        }
        i_rwaCoin.safeTransfer(msg.sender, _amount);
        i_lendingPool[_lender].amount -= _amount;
    }
    function _calculateInterest(
        uint256 _amount,
        uint8 _interest,
        uint256 _returnPeriod
    ) internal pure returns (uint256) {
        // Calculate interest using InterestAndHealthFactor library
        uint256 interestAmount = InterestAndHealthFactor
            .calculateSimpleInterest(
                _amount,
                _interest * 1e16, // Convert percentage to fixed-point format
                _returnPeriod
            );
        // Update the borrowing info with the calculated interest
        // i_borrowingPool[msg.sender].amount += interestAmount;
        return interestAmount;
    }
    function getLendingInfo(
        address _lender
    ) external view returns (LendingInfo memory) {
        return i_lendingPool[_lender];
    }

    function getCompleteLendingPool()
        external
        view
        returns (LendingInfo[] memory)
    {
        LendingInfo[] memory lendingInfos = new LendingInfo[](
            lendersArray.length
        );

        for (uint256 i = 0; i < lendersArray.length; i++) {
            lendingInfos[i] = i_lendingPool[lendersArray[i]];
        }

        return lendingInfos;
    }
    function getborrowingInfo(
        address _borrower
    ) external view returns (BorrowingInfo[] memory) {
        return i_borrowingPoolArray[_borrower];
    }
    function getMinReturnPeriod() external view returns (uint256) {
        return minReturnPeriod;
    }
    
    function getProcessingState() external view returns (uint256 lastProcessedIndex, uint256 totalBorrowers) {
        return (lastProcessedBorrowerIndex, borroweraddressArray.length);
    }
    
    function resetProcessingState() external onlyOwner {
        lastProcessedBorrowerIndex = 0;
    }
}
