// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RWA_Types} from "../CoinMintingAndManaging/RWA_Types.sol"; // Assuming RWA_Types is defined in a separate file

/**
 * @title IRWA_Manager
 * @dev Interface for the RWA_Manager contract.
 * Defines the external functions, events, and errors that other contracts can interact with.
 */
interface IRWA_Manager {
    // --- Errors ---
    error RWA_Manager__AssetNotVerified();
    error RWA_Manager__AssetValueNotPositive();
    error RWA_Manager__BalanceMustBeGreaterThanBurnAmount();
    error RWA_Manager__NotOwnerOfAsset();
    error RWA_NFT__NFTMIntingFailed(); // This error originates from RWA_NFT but is caught and re-thrown here.
    error RWA_Manager__NFTValueIsMoreThanSubmittedToken();
    error RWA_Manager__TokenAlreadyMinted();
    error RWA_Manager__ValueNotUpdatedFromVerifiedAssetsContract();

    // --- Events ---
    event TokenTradable(uint256 indexed tokenId);
    event NFTReceived(
        address indexed operator,
        address indexed from,
        uint256 indexed tokenId,
        bytes data
    );

    // --- Functions ---

    /**
     * @dev Sets a new member with MEMBER_ROLE.
     * @param _newMember The address to grant MEMBER_ROLE to.
     */
    function setNewMember(address _newMember) external;

    /**
     * @dev Removes a member's MEMBER_ROLE.
     * @param _member The address to revoke MEMBER_ROLE from.
     */
    function removeMember(address _member) external;

    /**
     * @dev ERC721 `onReceived` callback.
     * @param operator The address which called `safeTransferFrom` function.
     * @param from The address which previously owned the token.
     * @param tokenId The ID of the NFT being transferred.
     * @param data Additional data with no specified format.
     * @return The `bytes4` selector of `onERC721Received`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Deposits RWA (Real World Asset) and mints a corresponding NFT and RWA_Coins.
     * Requires the asset to be verified and have a positive value.
     * @param _to The address to which the NFT and RWA_Coins will be minted.
     * @param _requestId The unique identifier for the RWA verification request.
     * @param tokenURI The URI for the NFT metadata.
     */
    function depositRWAAndMintNFT(
        address _to,
        uint256 _requestId,
        string memory tokenURI
    ) external;

    /**
     * @dev Makes an NFT tradable by burning the corresponding coins.
     * @param tokenId The ID of the NFT to make tradable.
     * @param _requestId The request ID of the asset.
     * @param _tokenAmount The amount of coins to burn.
     */
    function changeNftTradable(
        uint256 tokenId,
        uint256 _requestId,
        uint256 _tokenAmount
    ) external;

    /**
     * @dev Allows a user to withdraw RWA by burning their NFT and RWA_Coins.
     * Checks if the user owns the asset and if the asset is valid.
     * @param tokenId The ID of the NFT to be burned.
     * @param _requestId The request ID of the asset to be withdrawn.
     */
    function withdrawRWAAndBurnNFTandCoin(
        uint256 tokenId,
        uint256 _requestId
    ) external;

    /**
     * @dev Allows a member to update the value of an asset.
     * Mints or burns RWA_Coins based on the change in asset value.
     * @param _to The address of the asset owner.
     * @param _requestId The request ID of the asset to be updated.
     * @param _valueInUSD The new value of the asset in USD.
     */
    function updateAssetValue(
        address _to,
        uint256 _requestId,
        uint256 _valueInUSD
    ) external;

    /**
     * @dev Allows a user to update the image URI of an asset's NFT.
     * @param _requestId The request ID of the asset.
     * @param _tokenId The ID of the NFT to be updated.
     * @param _imageUri The new image URI for the NFT.
     */
    function updateAssetImageUri(
        uint256 _requestId,
        uint256 _tokenId,
        string memory _imageUri
    ) external;

    /**
     * @dev Allows users to mint RWA_Coins by sending ETH.
     * The amount of coins minted is based on the ETH sent (simplified 1 ETH = 1 RWA_Coin).
     * @param _to The address to which the RWA_Coins will be minted.
     */
    function mintCoinAgainstEth(address _to) external payable;

    /**
     * @dev Allows the contract owner to withdraw ETH from the contract.
     * @param _to The address to send the ETH to.
     * @param amount The amount of ETH to withdraw.
     */
    function withdraw(address payable _to, uint256 amount) external;

    /**
     * @dev Returns the current ETH balance of the contract.
     * @return The ETH balance of the contract.
     */
    function getContractEthBalance() external view returns (uint256);

    /**
     * @dev Returns the current coin balance of the contract.
     * @return The coin balance of the contract.
     */
    function getContractCoinBalance() external view returns (uint256);

    /**
     * @dev Returns the RWA_Info struct for a specific user and request ID.
     * @param _user The address of the user.
     * @param _requestId The request ID to query.
     * @return The RWA_Info struct associated with the user and requestId.
     */
    function getUserAssetInfo(
        address _user,
        uint256 _requestId
    ) external view returns (RWA_Types.RWA_Info memory);

    /**
     * @dev Returns the RWA_Info struct for a given request ID.
     * @param _requestId The request ID to query.
     * @return The RWA_Info struct associated with the requestId.
     */
    function getUserRWAInfo(
        uint256 _requestId
    ) external view returns (RWA_Types.RWA_Info memory);

    /**
     * @dev Checks if an asset is tradable.
     * @param _user The address of the user.
     * @param _requestId The request ID to query.
     * @return Whether the asset is tradable.
     */
    function checkIfAssetIsTradable(
        address _user,
        uint256 _requestId
    ) external view returns (bool);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    function getUserRWAInfoagainstRequestId(uint256 assetId) external view  returns (
    uint256, uint256, uint256, uint256, uint256, uint256, address, bool
) 
}
