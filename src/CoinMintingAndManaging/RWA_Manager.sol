//SPDX--License-Identifier: MIT

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

//Temp comments:- while making any nft stakable or lendable just check if its locked/tradable or not if locked dont allow to use it on any other defi protocol like lending and staking

/* 
@title RWA Manager
@Author Ashutosh Kumar
@Notice its the first contract where you submit your asset to mint NFT and coins and also burn nft & coins.
@Notice asset can be withdrawn by submitting minted nft and coins.
@DEV any dev looking for improvement can implement these things to make code and secure.
@DEV it is highly inefficient can a lot of improvement can be made, like making code modular for depositing & withdrawing nft and coins(internal). and also fix  updating two mappings.
@DEV and also it can be made more secure by adding Pausable and ownable contract from openzeppelin;
@DEV instead of importing contracts we can use their interfaces.
*/

pragma solidity ^0.8.20;
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

// import {RWA_Verification} from "./RWA_Verification.sol";
import {RWA_VerifiedAssets} from "./RWA_VerifiedAssets.sol";
import {RWA_NFT} from "./RWA_NFT.sol";
import {RWA_Coins} from "./RWA_Coins.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {RWA_Types} from "./RWA_Types.sol";
contract RWA_Manager is Ownable, ReentrancyGuard, IERC721Receiver, AccessControl {
    using SafeERC20 for IERC20;
    

    error RWA_Manager__AssetNotVerified();
    error RWA_Manager__AssetValueNotPositive();
    error RWA_Manager__BalanceMustBeGreaterThanBurnAmount();
    error RWA_Manager__NotOwnerOfAsset();
    error RWA_NFT__NFTMIntingFailed();
    error RWA_Manager__NFTValueIsMoreThanSubmittedToken();
    error RWA_Manager__TokenAlreadyMinted();
    error RWA_Manager__ValueNotUpdatedFromVerifiedAssetsContract();
    error RWA_Manager__InsufficientETH();
    error RWA_Manager__ETHrefundFailed();
    error RWA_Manager__InsufficientCoins();
    error RWA_Manager__ZeroAddress();
    error RWA_Manager__ZeroAmount();

    // Events
    event AssetDeposited(address indexed owner, uint256 indexed requestId, uint256 assetValue, uint256 valueInUSD);
    event AssetValueUpdated(address indexed owner, uint256 indexed requestId, uint256 oldValue, uint256 newValue);
    event NFTTradabilityChanged(address indexed owner, uint256 indexed requestId, uint256 tokenId, bool tradable);

    // RWA_Verification private immutable i_rwaV;
    bytes32 public constant MEMBER_ROLE = keccak256("MEMBER_ROLE");
    RWA_VerifiedAssets private immutable i_rwaVA;
    RWA_NFT private immutable i_rwaN;
    RWA_Coins private immutable i_rwaC;
    uint256 private valueOfToken;
    uint256 public ethPriceFromChainlink = 0.001 ether; // Default ETH price, should be updated via oracle
    //storing asset information for each asset using requestId
    mapping(uint256 => RWA_Types.RWA_Info) public s_userRWAInfoagainstRequestId;
    //storing user information for every asset using user address and requestId
    mapping(address => mapping(uint256 => RWA_Types.RWA_Info))
        public s_userAssets;

    event TokenTradable(uint256 indexed tokenId);
    event NFTReceived(
        address indexed operator,
        address indexed from,
        uint256 indexed tokenId,
        bytes data
    );

    modifier onlyMember() {
        require(hasRole(MEMBER_ROLE, msg.sender), "Caller is not a member");
        _;
    }

    constructor(
        // address _rwaV,
        address _rwaVA,
        address _rwaN,
        address _rwaC
    ) Ownable(msg.sender) {
        // i_rwaV = RWA_Verification(_rwaV);
        i_rwaN = RWA_NFT(_rwaN); 
        i_rwaVA = RWA_VerifiedAssets(_rwaVA);
        i_rwaC = RWA_Coins(_rwaC);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MEMBER_ROLE, msg.sender);


    }
    function setNewMember(
        address _newMember
    ) external onlyOwner {
        _grantRole(MEMBER_ROLE, _newMember);
    }
    function removeMember(
        address _member
    ) external onlyOwner {
        _revokeRole(MEMBER_ROLE, _member);
    }

    function updateEthPrice(uint256 _newPrice) external onlyOwner {
        if (_newPrice == 0) {
            revert RWA_Manager__ZeroAmount();
        }
        ethPriceFromChainlink = _newPrice;
    }
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        emit NFTReceived(operator, from, tokenId, data);

        return IERC721Receiver.onERC721Received.selector;
    }

    //////////////////////////////
    /// Public & External Functions   //////////
    //////////////////////////////
    // These functions are used to deposit RWA and mint NFT.
    // They are external to allow users to call them from outside the contract.
    // They are used to deposit RWA and mint NFT.
    // The depositRWAAndMintNFT function is used to deposit RWA and mint NFT.
    // It takes the address of the user, the request ID, and the token URI as parameters.
    // ******* before calling this function make sure that the asset is verified by RWA_VerifiedAssets contract *************
    function depositRWAAndMintNFT(
        uint256 _requestId,
        uint256 _assetValue,
        address _assetOwner,
        string memory _tokenURI,
        uint256 _valueInUSD
    ) external payable onlyMember {
        // Input validation
        if (_assetOwner == address(0)) {
            revert RWA_Manager__ZeroAddress();
        }
        if (_assetValue == 0 || _valueInUSD == 0) {
            revert RWA_Manager__ZeroAmount();
        }
        if (msg.value != ethPriceFromChainlink) {
            revert RWA_Manager__InsufficientETH();
        }

        // Get asset details from verified assets contract - use separate variables to avoid stack too deep
        (, , uint256 assetId_, , bool isVerified_, , , ) = i_rwaVA.verifiedAssets(_assetOwner, _requestId);

        // Verify asset is registered and verified
        if (!isVerified_ || assetId_ != _requestId) {
            revert RWA_Manager__AssetNotVerified();
        }

        // Get asset type and name separately
        (RWA_Types.assetType assetType_, string memory assetName_, , , , , , ) = i_rwaVA.verifiedAssets(_assetOwner, _requestId);

        // Mint NFT
        _mintNFT(_assetOwner, _tokenURI, assetType_, assetName_, _requestId, _valueInUSD);
        
        // Mint coins
        _mintCoins(_assetOwner, _valueInUSD);

        // Store asset information - create struct directly
        RWA_Types.RWA_Info memory newAsset = RWA_Types.RWA_Info({
            assetType: assetType_,
            assetName: assetName_,
            assetId: _requestId,
            isLocked: false,
            isVerified: true,
            valueInUSD: _valueInUSD,
            owner: _assetOwner,
            tradable: false // Initially not tradable until coins are burned
        });

        s_userRWAInfoagainstRequestId[_requestId] = newAsset;
        s_userAssets[_assetOwner][_requestId] = newAsset;

        emit AssetDeposited(_assetOwner, _requestId, _assetValue, _valueInUSD);
    }

    // submit all coins minted against this token to make token tradable on lending platform
    //Because if he have NFT and coins then he will have double value for same assets that is why burning Coins is important

    function changeNftTradable(
        uint256 tokenId,
        uint256 _requestId,
        uint256 _tokenAmount
    ) external {
        // Input validation
        if (_tokenAmount == 0) {
            revert RWA_Manager__ZeroAmount();
        }
        // Check if asset exists
        if (s_userAssets[msg.sender][_requestId].assetId != _requestId) {
            revert RWA_Manager__AssetNotVerified();
        }
        if (
            _tokenAmount < s_userRWAInfoagainstRequestId[_requestId].valueInUSD
        ) {
            revert RWA_Manager__NFTValueIsMoreThanSubmittedToken();
        }
        if (
            s_userAssets[msg.sender][_requestId].owner != msg.sender
        ) {
            revert RWA_Manager__NotOwnerOfAsset();
        }
        _burnCoins(s_userAssets[msg.sender][_requestId].valueInUSD);
        // inefficient updating two mappings could have merged in one
        // Improve in future version
        s_userRWAInfoagainstRequestId[_requestId].tradable = true;
        s_userAssets[msg.sender][_requestId].tradable = true;
        emit TokenTradable(tokenId);
        emit NFTTradabilityChanged(msg.sender, _requestId, tokenId, true);
    }

    /* 
    @param tokenId The ID of the NFT to be burned.
    @param _requestId The request ID of the asset to be withdrawn.
    @notice This function allows a user to withdraw RWA and burn their NFT and coins.
     check if the user have valid nft and coins
     If the user does not have a valid NFT or coins, revert the transaction.
     If the user has a valid NFT and coins, burn the NFT and coins.
     ****** to completely remove from the system you have to deregistered asset from RWA_VerifiedAssets contract
    */
    function withdrawRWAAndBurnNFTandCoin(
        uint256 tokenId,
        uint256 _requestId
    ) external nonReentrant {
        if (s_userAssets[msg.sender][_requestId].assetId != _requestId) {
            revert RWA_Manager__AssetNotVerified();
        }
        if (s_userAssets[msg.sender][_requestId].valueInUSD <= 0) {
            revert RWA_Manager__AssetValueNotPositive();
        }
        if (s_userAssets[msg.sender][_requestId].owner != msg.sender) {
            revert RWA_Manager__NotOwnerOfAsset();
        }
        valueOfToken = s_userRWAInfoagainstRequestId[_requestId].valueInUSD;

        _burnNFT(tokenId);
        _burnCoins(s_userAssets[msg.sender][_requestId].valueInUSD);
        delete s_userAssets[msg.sender][_requestId]; // Remove the asset info for the user
        delete s_userRWAInfoagainstRequestId[_requestId]; // Remove the asset info
        // Burn the NFT and coins
    }

    /*
    @param _requestId The request ID of the asset to be updated.
    @param _valueInUSD The new value of the asset in USD.
    @notice This function allows a user to update the value of an asset.
    in forntend or backend you can call this function to update the value of an asset regularly.
    */
    function updateAssetValue(address _to,
        uint256 _requestId,
        uint256 _valueInUSD
    ) external nonReentrant onlyMember {
        // Input validation
        if (_to == address(0)) {
            revert RWA_Manager__ZeroAddress();
        }
        if (_valueInUSD == 0) {
            revert RWA_Manager__ZeroAmount();
        }
        
         (
           ,
          ,
            ,
            bool isLocked_,
          , // Not needed here as we are checking it in the contract
            uint256 valueInUSD_,
            ,
            bool tradable

        ) = i_rwaVA.verifiedAssets(_to, _requestId);
        if(valueInUSD_ ==s_userRWAInfoagainstRequestId[_requestId].valueInUSD ){
            revert RWA_Manager__ValueNotUpdatedFromVerifiedAssetsContract();
        }
        if (s_userAssets[_to][_requestId].assetId != _requestId) {
            revert RWA_Manager__AssetNotVerified();
        }
        if (_valueInUSD <= 0) {
            revert RWA_Manager__AssetValueNotPositive();
        }
        uint256 difference = 0;
   
        if (valueInUSD_<= _valueInUSD) {
            difference = _valueInUSD - s_userAssets[_to][_requestId]
                .valueInUSD;
             uint256 oldValue = s_userAssets[_to][_requestId].valueInUSD;
             _mintCoins(_to, difference);
             s_userRWAInfoagainstRequestId[_requestId].valueInUSD = _valueInUSD;
             s_userAssets[_to][_requestId].valueInUSD = _valueInUSD;
             i_rwaVA.upDateAssetValue(_to, _requestId, _valueInUSD, isLocked_, tradable);
             emit AssetValueUpdated(_to, _requestId, oldValue, _valueInUSD);
        }


        if (valueInUSD_ > _valueInUSD) {

            difference = s_userAssets[_to][_requestId]
                .valueInUSD - _valueInUSD;
            if (difference > i_rwaC.balanceOf(_to)) {
                
                s_userAssets[_to][_requestId].tradable = false;
                s_userAssets[_to][_requestId].isLocked = true;
                s_userRWAInfoagainstRequestId[_requestId].tradable = false;
                s_userRWAInfoagainstRequestId[_requestId].isLocked = true;
                s_userRWAInfoagainstRequestId[_requestId].valueInUSD = _valueInUSD;
                s_userAssets[_to][_requestId].valueInUSD = _valueInUSD;
                // Update the asset value in the verified assets contract
                i_rwaVA.upDateAssetValue(_to, _requestId, _valueInUSD, true, false);
                revert RWA_Manager__BalanceMustBeGreaterThanBurnAmount();
            } else {
                // User has sufficient balance - burn the difference and update values
                // Transfer coins from user to contract and burn them
                uint256 oldValue = s_userAssets[_to][_requestId].valueInUSD;
                IERC20(address(i_rwaC)).safeTransferFrom(_to, address(this), difference);
                i_rwaC.burn(difference);
                s_userRWAInfoagainstRequestId[_requestId].valueInUSD = _valueInUSD;
                s_userAssets[_to][_requestId].valueInUSD = _valueInUSD;
                i_rwaVA.upDateAssetValue(_to, _requestId, _valueInUSD, isLocked_, tradable);
                emit AssetValueUpdated(_to, _requestId, oldValue, _valueInUSD);
            }
           
        }
        
    }
    /*
    @param _requestId The request ID of the asset to be updated.
    @param _tokenId The ID of the NFT to be updated.
    @param _imageUri The new image URI of the asset.
    @notice This function allows a user to update the image URI of an asset.
    It checks if the asset is verified and if the user is the owner of the asset.
    If the asset is not verified or the user is not the owner, it reverts the transaction.
    If the asset is verified and the user is the owner, it updates the image URI
    in the NFT contract.
    */
    function updateAssetImageUri(
        uint256 _requestId,
        uint256 _tokenId,
        string memory _imageUri
    ) public nonReentrant {
        if (s_userAssets[msg.sender][_requestId].assetId != _requestId) {
            revert RWA_Manager__AssetNotVerified();
        }
        if (s_userAssets[msg.sender][_requestId].owner != msg.sender) {
            revert RWA_Manager__NotOwnerOfAsset();
        }
        // Update the image URI in the NFT contract
        i_rwaN.setImageUri(_tokenId, _imageUri);
    }

    function mintCoinAgainstEth(address _to) external payable nonReentrant {
        if (msg.value <= 0) {
            revert RWA_Manager__AssetValueNotPositive();
        }

        // Assuming 1 ETH = 1000 USD for simplicity, adjust as needed
        // update it according to coin value in usd
        uint256 coinsToMint = (msg.value / 1e18);
        _mintCoins(_to, coinsToMint);
    }
    function withdraw(address payable _to, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool success, ) = _to.call{value: amount}("");
        require(success, "Transfer failed");
    }

    //////////////////////////////
    /// Private Functions   //////////
    //////////////////////////////
    // These functions are used to mint coins and burn NFT and coins.
    // They are private to ensure that they can only be called within this contract.
    // This is to ensure that the minting and burning of coins and NFTs are controlled and
    // can only be done by the contract owner or through the depositRWAAndMintNFT function.
    // This is to prevent unauthorized minting or burning of coins and NFTs.

    function _mintNFT(
        address _to,
        string memory tokenURI,
        RWA_Types.assetType assetType_,
        string memory assetName_,
        uint256 assetId_,
        uint256 valueInUSD_
    ) private {
        bool minted = i_rwaN.mint(
            _to,
            tokenURI,
            assetType_,
            assetName_,
            valueInUSD_
        );
        if (!minted) {
            revert RWA_NFT__NFTMIntingFailed();
        }
    }

    function _mintCoins(address _to, uint256 valueInUSD_) private {
        bool mintedCoins = i_rwaC.mint(_to, valueInUSD_);
        if (!mintedCoins) {
            revert RWA_NFT__NFTMIntingFailed();
        }
    }
    function _burnNFT(uint256 tokenId) private {
        i_rwaN.safeTransferFrom(msg.sender, address(this), tokenId);
        i_rwaN.burn(tokenId);
    }
    function _burnCoins(uint256 amount) private {
        uint256 balance = i_rwaC.balanceOf(msg.sender);
        if (balance < amount) {
            revert RWA_Manager__BalanceMustBeGreaterThanBurnAmount();
        }

        IERC20(address(i_rwaC)).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        i_rwaC.burn(amount);
    }
    function getContractEthBalance() external view returns (uint256) {
        return address(this).balance;
    }
    function getContractCoinBalance() external view returns (uint256) {
        return i_rwaC.balanceOf(address(this));
    }
    function getUserAssetInfo(
        address _user,
        uint256 _requestId
    ) external view returns (RWA_Types.RWA_Info memory) {
        return s_userAssets[_user][_requestId];
    }
    function getUserRWAInfo(
        uint256 _requestId
    ) external view returns (RWA_Types.RWA_Info memory) {
        return s_userRWAInfoagainstRequestId[_requestId];
    }
    
    function checkIfAssetIsTradable(
        address _user,
        uint256 _requestId
    ) external view returns (bool) {
        return s_userAssets[_user][_requestId].tradable;
    }
      // Implement this function if missing
// Replace the problematic function with this:
function getUserRWAInfoagainstRequestId(uint256 assetId) external view returns (RWA_Types.RWA_Info memory) {
    return s_userRWAInfoagainstRequestId[assetId];
}

    
}
