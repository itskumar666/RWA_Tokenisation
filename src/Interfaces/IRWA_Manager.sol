// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RWA_Types} from "../CoinMintingAndManaging/RWA_Types.sol";

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
    error RWA_NFT__NFTMIntingFailed();
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

    // --- Access Control Functions ---

    /**
     * @notice Grants member role to a new address.
     * Only callable by owner.
     * @param _newMember The address to grant member role to.
     */
    function setNewMember(address _newMember) external;

    /**
     * @notice Revokes member role from an address.
     * Only callable by owner.
     * @param _member The address to revoke member role from.
     */
    function removeMember(address _member) external;

    // --- Core RWA Functions ---

    /**
     * @notice Deposits RWA and mints corresponding NFT and coins.
     * @param _to The address to mint tokens to.
     * @param _requestId The request ID of the verified asset.
     * @param tokenURI The metadata URI for the NFT.
     */
    function depositRWAAndMintNFT(
        address _to,
        uint256 _requestId,
        string memory tokenURI
    ) external;

    /**
     * @notice Makes an NFT tradable by burning equivalent coins.
     * @param tokenId The ID of the NFT to make tradable.
     * @param _requestId The request ID of the asset.
     * @param _tokenAmount The amount of tokens to burn.
     */
    function changeNftTradable(
        uint256 tokenId,
        uint256 _requestId,
        uint256 _tokenAmount
    ) external;

    /**
     * @notice Withdraws RWA by burning NFT and coins.
     * @param tokenId The ID of the NFT to burn.
     * @param _requestId The request ID of the asset to withdraw.
     */
    function withdrawRWAAndBurnNFTandCoin(
        uint256 tokenId,
        uint256 _requestId
    ) external;

    /**
     * @notice Updates the value of an asset (member only).
     * @param _to The owner of the asset.
     * @param _requestId The request ID of the asset.
     * @param _valueInUSD The new value in USD.
     */
    function updateAssetValue(
        address _to,
        uint256 _requestId,
        uint256 _valueInUSD
    ) external;

    /**
     * @notice Updates the image URI of an asset's NFT.
     * @param _requestId The request ID of the asset.
     * @param _tokenId The ID of the NFT.
     * @param _imageUri The new image URI.
     */
    function updateAssetImageUri(
        uint256 _requestId,
        uint256 _tokenId,
        string memory _imageUri
    ) external;

    /**
     * @notice Mints coins against ETH payment.
     * @param _to The address to mint coins to.
     */
    function mintCoinAgainstEth(address _to) external payable;

    /**
     * @notice Withdraws ETH from the contract (owner only).
     * @param _to The address to send ETH to.
     * @param amount The amount of ETH to withdraw.
     */
    function withdraw(address payable _to, uint256 amount) external;

    // --- ERC721 Receiver ---

    /**
     * @notice Handles the receipt of an NFT.
     * @param operator The address which called `safeTransferFrom`.
     * @param from The address which previously owned the token.
     * @param tokenId The NFT identifier which is being transferred.
     * @param data Additional data with no specified format.
     * @return bytes4 The selector to confirm token transfer.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);

    // --- View Functions ---

    /**
     * @notice Gets the contract's ETH balance.
     * @return The ETH balance of the contract.
     */
    function getContractEthBalance() external view returns (uint256);

    /**
     * @notice Gets the contract's coin balance.
     * @return The coin balance of the contract.
     */
    function getContractCoinBalance() external view returns (uint256);

    /**
     * @notice Gets asset information for a specific user and request ID.
     * @param _user The user's address.
     * @param _requestId The request ID.
     * @return RWA_Info struct containing asset details.
     */
    function getUserAssetInfo(
        address _user,
        uint256 _requestId
    ) external view returns (RWA_Types.RWA_Info memory);

    /**
     * @notice Gets RWA information by request ID.
     * @param _requestId The request ID.
     * @return RWA_Info struct containing asset details.
     */
    function getUserRWAInfo(
        uint256 _requestId
    ) external view returns (RWA_Types.RWA_Info memory);

    /**
     * @notice Gets RWA information by asset ID.
     * @param assetId The asset ID.
     * @return RWA_Info struct containing asset details.
     */
    function getUserRWAInfoagainstRequestId(
        uint256 assetId
    ) external view returns (RWA_Types.RWA_Info memory);

    /**
     * @notice Checks if an asset is tradable.
     * @param _user The user's address.
     * @param _requestId The request ID.
     * @return Boolean indicating if the asset is tradable.
     */
    function checkIfAssetIsTradable(
        address _user,
        uint256 _requestId
    ) external view returns (bool);

    /**
     * @notice Gets the member role constant.
     * @return The bytes32 hash of the member role.
     */
    function MEMBER_ROLE() external view returns (bytes32);

    /**
     * @notice Gets RWA information stored against request ID (public mapping).
     * @param requestId The request ID.
     * @return RWA_Info struct containing asset details.
     */
    function s_userRWAInfoagainstRequestId(
        uint256 requestId
    ) external view returns (RWA_Types.RWA_Info memory);

    /**
     * @notice Gets user asset information (public mapping).
     * @param user The user's address.
     * @param requestId The request ID.
     * @return RWA_Info struct containing asset details.
     */
    function s_userAssets(
        address user,
        uint256 requestId
    ) external view returns (RWA_Types.RWA_Info memory);
}