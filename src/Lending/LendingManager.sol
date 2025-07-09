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
contract LendingManager is ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    using RWA_Types for RWA_Types.RWA_Info;

    error LendingManager__NotZeroAmount();
    error LendingManager__InvalidAddress();
    error LendingManager__InvalidToken();
    error LendingManager__ExpectedMinimumAmount();
    error LendingManager__InsufficientBalance();
    error LendingManager__NFTValueIsLowerThanAmount();

    struct LendingInfo {
        uint256 amount;
        uint8 interest; //max 30%
        uint8 minBorrow; //like 10%,5%
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

    mapping(address user => LendingInfo lendingInfo) private i_lendingPool;
    mapping(address user => BorrowingInfo borrowingInfo)
        private i_borrowingPool;

    event coinDeposited(
        address indexed user,
        uint256 indexed amount,
        uint8 interest,
        uint8 minBorrow
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
        address RWA_Manager
    ) {
        i_rwaCoin = IERC20(rwaCoin);
        i_rwaNft = IERC721(rwaNft);
        i_nftVault = INFTVault(nftVault);
        i_rwaManager = IRWA_Manager(RWA_Manager); // assuming this contract is deployed by RWA_Manager
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
        (,,uint256 assetId_,,,uint256 valueInUSD_,
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
        if (valueInUSD_ < _amount) {
            revert LendingManager__NFTValueIsLowerThanAmount();
        }

        i_rwaNft.safeTransferFrom(msg.sender, address(i_nftVault), _tokenIdNFT);
        i_rwaCoin.safeTransfer(msg.sender, _amount);
        _borrowCoin(
            _amount,
            _tokenIdNFT,
            _lender,
            _assetId
        );
        _calculateInterest(
            _amount,
            lendingInfo.interest,
            lendingInfo.returnPeriod
        );  
        
    }
    function chainlinkLoanHealthFactor(
        uint256 _amount,
        uint8 _interest,
        uint256 _returnPeriod
    ) external view returns (uint256) {
        // Calculate the health factor using InterestAndHealthFactor library
        return InterestAndHealthFactor.calculateHealthFactor(
            _amount,
            _interest * 1e16, // Convert percentage to fixed-point format
            _returnPeriod
        );
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
        i_borrowingPool[msg.sender].amount += _amount;
        i_borrowingPool[msg.sender].tokenIdNFT = _tokenIdNFT;
        i_borrowingPool[msg.sender].lender = _lender;
        i_borrowingPool[msg.sender].assetId = _assetId;
        i_borrowingPool[msg.sender].borrowTime = block.timestamp;
        i_borrowingPool[msg.sender].isReturned = false;
        i_borrowingPool[msg.sender].returnTime =
            block.timestamp +
            i_lendingPool[_lender].returnPeriod;
        i_nftVault.depositNFT(_tokenIdNFT, _lender);
        i_lendingPool[_lender].amount -= _amount;

    }
    function _calculateInterest(
        uint256 _amount,
        uint8 _interest,
        uint256 _returnPeriod
    ) internal {
        // Calculate interest using InterestAndHealthFactor library
        uint256 interestAmount = InterestAndHealthFactor.calculateSimpleInterest(
            _amount,
            _interest * 1e16, // Convert percentage to fixed-point format
            _returnPeriod
        );
        // Update the borrowing info with the calculated interest
        i_borrowingPool[msg.sender].amount += interestAmount;
    }
}
