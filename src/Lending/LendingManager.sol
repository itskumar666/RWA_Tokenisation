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
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {INFTVault} from "../Interfaces/INFTVault.sol";
import {IRWA_Manager} from "../Interfaces/IRWA_Manager.sol";
import {RWA_Types} from "../CoinMintingAndManaging/RWA_Types.sol";
import {InterestAndHealthFactor} from "../Library/InterestAndHealthFactor.sol";

/* 
    @title LendingVault
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
    address[] private borroweraddressArray; // array of borrower addresses
    address private auctionHouse; // address of the auction house for liquidating NFTs
    uint256 private minReturnPeriod; // minimum return period in seconds

    mapping(address user => LendingInfo lendingInfo) private i_lendingPool;
    mapping(address user => BorrowingInfo[]) private i_borrowingPoolArray;

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
        uint256 _minReturnPeriod,address auctionHouse
    ) Ownable(msg.sender) {
        i_rwaCoin = IERC20(rwaCoin);
        i_rwaNft = IERC721(rwaNft);
        i_nftVault = INFTVault(nftVault);
        i_rwaManager = IRWA_Manager(RWA_Manager);
        minReturnPeriod = _minReturnPeriod; // minimum return period in seconds
        // assuming this contract is deployed by RWA_Manager
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
        (
            ,
            ,
            uint256 assetId_,
            ,
            ,
            uint256 valueInUSD_,
            address owner_,
            bool tradable_
        ) = i_rwaManager.s_userRWAInfoagainstRequestId(_assetId);
        if (_tokenIdNFT > 0) {
            if (i_rwaNft.ownerOf(_tokenIdNFT) != msg.sender) {
                revert LendingManager__InvalidToken();
            }
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

        if (valueInUSD_ < _amount + interestAmount) {
            revert LendingManager__NFTValueIsLowerThanAmount();
        }
        uint256 NFTValue = _amount + interestAmount;
        i_rwaNft.safeTransferFrom(msg.sender, address(i_nftVault), _tokenIdNFT );
        i_rwaCoin.safeTransfer(msg.sender, _amount);
        _borrowCoin(_amount, _tokenIdNFT, _lender, _assetId);
        i_nftVault.depositNFT(_tokenIdNFT,msg.sender,NFTValue);
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
                i_rwaCoin.safeTransferFrom(msg.sender, address(this), _amount);
                i_rwaCoin.safeTransfer(_lender, _amount + interestAmount);
                i_nftVault.tokenTransferToBorrower(_tokenIdNFT, msg.sender);
                i_lendingPool[_lender].amount += _amount + interestAmount;
                borrowings[i].amount = 0; // Reset the amount to zero after return

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
    // this function will be called by chainlink automation on fixed interval

    function performUpkeep() external {
        for(uint256 j=0; j<borroweraddressArray.length;j++){

         address k= borroweraddressArray[j];
        for(uint256 i = 0; i < i_borrowingPoolArray[k].length; i++) {
            BorrowingInfo storage borrowing = i_borrowingPoolArray[k][i];
            if (!borrowing.isReturned && borrowing.returnTime < block.timestamp) {
                // If the return time has passed and the coin is not returned, auction the NFT
                i_nftVault.tokenTransferToAuctionHouseOnLiquidation(borrowing.tokenIdNFT,auctionHouse);
                // ********** Transfer the borrowed amount back to the lender from this contract *******************
                // rwaCoin.safeTransfer(, borrowing.amount);
                borrowing.isReturned = true; 
                i_borrowingPoolArray[k][i] = i_borrowingPoolArray[k][i_borrowingPoolArray[k].length - 1];
                 i_borrowingPoolArray[k].pop();
             
            }
        }}

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

        // Deposit the NFT into the NFT vault
        i_lendingPool[_lender].amount -= _amount;
        // Add the borrower address to the array if not already present
        bool exists = false;
        for (uint256 i = 0; i < borroweraddressArray.length; i++)
        {
            if (borroweraddressArray[i] == msg.sender) {
                exists = true;
                break;  
            } 
            }
              if(!exists){
                    borroweraddressArray.push(msg.sender);
                }
   
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
}
