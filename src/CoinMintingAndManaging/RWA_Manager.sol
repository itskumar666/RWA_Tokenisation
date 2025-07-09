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

pragma solidity ^0.8.20;
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {RWA_Verification} from "./RWA_Verification.sol";
import {RWA_NFT} from "./RWA_NFT.sol";
import {RWA_Coins} from "./RWA_Coins.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {RWA_Types} from "./RWA_Types.sol";
contract RWA_Manager is Ownable, ReentrancyGuard, IERC721Receiver {
    using SafeERC20 for IERC20;

    error RWA_Manager__AssetNotVerified();
    error RWA_Manager__AssetValueNotPositive();
    error RWA_Manager__BalanceMustBeGreaterThanBurnAmount();
    error RWA_Manager__NotOwnerOfAsset();
    error RWA_NFT__NFTMIntingFailed();

    RWA_Verification private immutable i_rwaV;
    RWA_NFT private immutable i_rwaN;
    RWA_Coins private immutable i_rwaC;
    uint256 private valueOfToken;
    //storing asset information for each asset using requestId
    mapping(uint256 => RWA_Types.RWA_Info) public s_userRWAInfoagainstRequestId;
    //storing user information for every asset using user address and requestId
    mapping(address => mapping(uint256 => RWA_Types.RWA_Info))
        public s_userAssets;

    constructor(
        address _rwaV,
        address _rwaN,
        address _rwaC
    ) Ownable(msg.sender) {
        i_rwaV = RWA_Verification(_rwaV);
        i_rwaN = RWA_NFT(_rwaN);
        i_rwaC = RWA_Coins(_rwaC);
    }
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
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
    function depositRWAAndMintNFT(
        address _to,
        uint256 _requestId,
        string memory tokenURI
    ) public nonReentrant {
        (
            RWA_Types.assetType assetType_,
            string memory assetName_,
            uint256 assetId_,
            bool isLocked_,
            bool isVerified,
            uint256 valueInUSD_,
            ,

        ) = i_rwaV.s_requestResponsesData(_requestId);
        if (!isVerified) {
            revert RWA_Manager__AssetNotVerified();
        }
        if (valueInUSD_ <= 0) {
            revert RWA_Manager__AssetValueNotPositive();
        }
        _mintNFT(_to, tokenURI, assetType_, assetName_, assetId_, valueInUSD_);
        _mintCoins(_to, valueInUSD_);
        s_userAssets[_to][_requestId] = RWA_Types.RWA_Info({
            assetType: assetType_,
            assetName: assetName_,
            assetId: assetId_,
            isLocked: isLocked_,
            isVerified: isVerified,
            valueInUSD: valueInUSD_,
            owner: msg.sender,
            tradable: true // Assuming the asset is tradable if this function is called
        });
    }
    /* 
    @param tokenId The ID of the NFT to be burned.
    @param _requestId The request ID of the asset to be withdrawn.
    @notice This function allows a user to withdraw RWA and burn their NFT and coins.
     check if the user have valid nft and coins
     If the user does not have a valid NFT or coins, revert the transaction.
     If the user has a valid NFT and coins, burn the NFT and coins.
    */
    function withdrawRWAAndBurnNFTandCoin(
        uint256 tokenId,
        uint256 _requestId
    ) public nonReentrant {
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
    */
    function updateAssetValue(
        uint256 _requestId,
        uint256 _valueInUSD
    ) public nonReentrant {
        if (s_userAssets[msg.sender][_requestId].assetId != _requestId) {
            revert RWA_Manager__AssetNotVerified();
        }
        if (_valueInUSD <= 0) {
            revert RWA_Manager__AssetValueNotPositive();
        }
        if (s_userAssets[msg.sender][_requestId].owner != msg.sender) {
            revert RWA_Manager__NotOwnerOfAsset();
        }
        s_userAssets[msg.sender][_requestId].valueInUSD = _valueInUSD;
        s_userRWAInfoagainstRequestId[_requestId].valueInUSD = _valueInUSD;
        if (s_userAssets[msg.sender][_requestId].valueInUSD <= _valueInUSD) {
            uint256 difference = s_userAssets[msg.sender][_requestId]
                .valueInUSD - _valueInUSD;
            _mintCoins(msg.sender, difference);
        }
        s_userRWAInfoagainstRequestId[_requestId].valueInUSD = _valueInUSD;
        if (s_userAssets[msg.sender][_requestId].valueInUSD > _valueInUSD) {
            uint256 difference = s_userAssets[msg.sender][_requestId]
                .valueInUSD - _valueInUSD;
            if (difference > i_rwaC.balanceOf(msg.sender)) {
                s_userAssets[msg.sender][_requestId].tradable = false;
                revert RWA_Manager__BalanceMustBeGreaterThanBurnAmount();
            }
            _burnCoins(difference);
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

    function mintCoinAgainstEth(
        address _to
        
    ) external payable nonReentrant {
        if (msg.value <= 0) {
            revert RWA_Manager__AssetValueNotPositive();
        }
       
        // Assuming 1 ETH = 1000 USD for simplicity, adjust as needed
        // update it according to coin value in usd 
        uint256 coinsToMint = (msg.value /1e18) ;
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
            msg.sender,
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
        if (balance < valueOfToken) {
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

}
