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
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
/* 
    @title LendingVault
    @author Ashutosh Kumar
    @notice This contract is used to lend coins to users, it allows users to deposit erc-20 coins, borrow coins, withdraw coins and return borrowed coins.
    @notice The contract is designed to be used with a specific token, which is passed during deployment.
    @dev This contract is pausable and can be paused by the owner.
    @dev This contract is protected by OpenZeppelin's ReentrancyGuard to prevent reentrancy attacks.
    @dev This contract for now is not receving the coin from user, it is only allowing the owner to deposit coins on behalf of user through lending manager contract .

*/

contract LendingVault is Pausable, Ownable, ReentrancyGuard {
    error Lending__NotZeroAmount();
    error Lending__InvalidAddress();
    error Lending__AmountExceedsBorrowingLimit();
    error Lending__AmountExceedsUserBalance();
    
    // using SafeERC20 for IERC20;
    // IERC20 private immutable i_rwaCoin;
    uint256 private i_totalDepositedCoins;
    uint256 private i_totalBorrowedCoins;
    uint256 private minBorrowCapacity;
    // Storing  coin deposited by user
    mapping(address user => uint256 balance) private i_userCreditBalance;
    // Storing  coin borrowed by user

     mapping(address user => uint256 balance) private i_userDebitBalance;


    event coinDeposited(address indexed user,uint256 indexed amount);
    event coinBorrowed(address indexed user,uint256 indexed amount);
    event coinWithdrawn(address indexed user,uint256 indexed amount);
    event coinReturned(address indexed user,uint256 indexed amount);
    event MinBorrowCapacityChanged(uint256 indexed newCapacity);
    


    modifier notZeroAmount(uint256 _amount) {
        if (_amount <= 0) {
            revert Lending__NotZeroAmount();
        }
        _;
    }
     modifier invalidAddress(address _by) {
        if (_by <= address(0)) {
            revert Lending__InvalidAddress();
        }
        _;
    }
    /* 
    @params _rwaCoinAddress Address of i_rwaCoin contract which is used for lending
    @params _minBorrowCapacity Minimum amount of coin that can be borrowed by user like 1000 i_rwaCoin or i_totalCoinInPool/10

    */
    constructor(address _rwaCoinAddress,uint256 _minBorrowCapacity,address _lendingManager) Ownable(_lendingManager) {
        // i_rwaCoin = IERC20(_rwaCoinAddress);
        minBorrowCapacity=_minBorrowCapacity;
    }

   ///////////////////////////
   /// External Functions ///
   ///////////////////////////

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
        }
    function changeMinBorrowCapacity(uint256 _newCapacity)external onlyOwner{
      minBorrowCapacity=_newCapacity;
      emit MinBorrowCapacityChanged(_newCapacity);

    }

    /*
    @params _amount Amount to be deposited by lender/User
    @Notice this function accept i_rwaCoin(minted through my contract only) and save it in its private userCreditBalance 
    @Dev its pausable under attack by owner and also protected by openzepeelin reentrancygurad
    */
    function depositCoin(address _user,
        uint256 _amount,
        uint8 _interest,
        uint8 _minBorrow
    ) external nonReentrant whenNotPaused notZeroAmount(_amount) invalidAddress(_user) onlyOwner{
        // i_rwaCoin.safeTransferFrom(_user,address(this),_amount);
        emit coinDeposited(_user,_amount);
        i_userCreditBalance[_user]+=_amount;
        i_totalDepositedCoins+=_amount;
    }
    /* 
    @params _user Address of user who is borrowing the coin
    @params _amount Amount of coin to be borrowed by user
    @Notice this function allows user to borrow coin from the pool, it checks if the amount
    is less than or equal to the minimum borrow capacity and then transfers the coin to the user
    @Dev its pausable under attack by owner and also protected by openzepeelin reentrancygurad
    @Dev this function is only callable by owner of the contract which is lending manager,
    */

    function borrowCoin(address _user,uint256 _amount)external nonReentrant whenNotPaused notZeroAmount(_amount) invalidAddress(_user) onlyOwner{
        if(_amount>minBorrowCapacity){
            revert Lending__AmountExceedsBorrowingLimit();

        }
        // i_rwaCoin.safeTransfer(_user,_amount);
        emit coinBorrowed(_user,_amount);
        i_userDebitBalance[_user]+=_amount;
        i_totalBorrowedCoins+=_amount;

    }
    /* 
    @params _user Address of user who is withdrawing the coin
    @params _amount Amount of coin to be withdrawn by user
    @Notice this function allows user to withdraw coin from user credit balance 
    @Dev it checks if the amount is less than or equal to the user credit balance and then transfers the coin to the user
    @Dev its pausable under attack by owner and also protected by openzepeelin reentrancygurad
    @Dev this function is only callable by owner of the contract which is lending manager,
    @Dev this function is used to withdraw the coin deposited by user in the pool
    */

     function withdrawDepositedCoin(address _user,uint256 _amount)external nonReentrant whenNotPaused notZeroAmount(_amount) invalidAddress(_user) onlyOwner{
        if(_amount>i_userCreditBalance[_user]){
            revert Lending__AmountExceedsUserBalance();

        }
        // i_rwaCoin.safeTransfer(_user,_amount);
        emit coinWithdrawn(_user,_amount);
        i_userCreditBalance[_user]-=_amount;
        i_totalDepositedCoins-=_amount;

    }
/* 
    @params _user Address of user who is returning the coin
    @params _amount Amount of coin to be returned by user
    @Notice this function allows user to return the coin borrowed from the pool
    @Dev it checks if the amount is greater than the borrowed amount if yes then it returns the remaining amount to the user credit balance and sets the debit balance to zero
    @Dev if the amount is less than or equal to the borrowed amount then it reduces the debit balance by the amount
    @Dev its pausable under attack by owner and also protected by openzepeelin reentrancygurad
    @Dev this function is only callable by owner of the contract which is lending manager,

*/

       function returnWithdrawnCoin(address _user,uint256 _amount)external nonReentrant whenNotPaused notZeroAmount(_amount) invalidAddress(_user) onlyOwner{
        if(_amount>i_userDebitBalance[_user]){
            i_userCreditBalance[_user]+=_amount-i_userDebitBalance[_user];
        
            i_totalDepositedCoins+=_amount-i_userDebitBalance[_user];
            i_totalBorrowedCoins-=i_userDebitBalance[_user];
            i_userDebitBalance[_user]=0;
            emit coinDeposited(_user,_amount-i_userDebitBalance[_user]);
        }
        else{
             i_userDebitBalance[_user]-=_amount;
   
        }
        // i_rwaCoin.safeTransferFrom(_user,address(this),_amount);
        emit coinReturned(_user,_amount);

    }

    //////////////////////////////
    // External View functions ///
    //////////////////////////////
    function getUserBalances(address user) external view returns (uint256 credit, uint256 debt){
        return (i_userCreditBalance[user],i_userDebitBalance[user]);
    }

function getTotalPoolState() external view returns (uint256 totalDeposited, uint256 totalBorrowed){
    return (i_totalDepositedCoins, i_totalBorrowedCoins);
}

function getMinBorrowCapacity() external view returns (uint256){
    return minBorrowCapacity;
}
// function getRwaCoinAddress() external view returns (address) {
//     return address(i_rwaCoin);}
function getTotalCoinInPool() external view returns (uint256) {
    return i_totalDepositedCoins + i_totalBorrowedCoins;}
function getUserCreditBalance(address user) external view returns (uint256) {
    return i_userCreditBalance[user];}
function getUserDebitBalance(address user) external view returns (uint256) {
    return i_userDebitBalance[user];}
function getTotalDepositedCoins() external view returns (uint256) {
    return i_totalDepositedCoins;}
function getTotalBorrowedCoins() external view returns (uint256) {
    return i_totalBorrowedCoins;
}



}
