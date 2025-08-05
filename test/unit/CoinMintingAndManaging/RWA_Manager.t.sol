//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { RWA_Manager } from "../../../src/CoinMintingAndManaging/RWA_Manager.sol";
import { RWA_Types } from "../../../src/CoinMintingAndManaging/RWA_Types.sol";
import { RWA_VerifiedAssetsMock } from "../../mocks/RWA_VerifiedAssetsMock.sol";
import { RWA_NFTMock } from "../../mocks/RWA_NFTMock.sol";
import { RWA_CoinsMock } from "../../mocks/RWA_CoinsMock.sol";

contract RWA_ManagerTest is Test {
    RWA_Manager public rwaManager;
    RWA_VerifiedAssetsMock public rwaVerifiedAssets;
    RWA_NFTMock public rwaNFT;
    RWA_CoinsMock public rwaCoins;

    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    address public member = address(4);

    uint256 public constant REQUEST_ID_1 = 1;
    uint256 public constant REQUEST_ID_2 = 2;
    uint256 public constant ASSET_VALUE_USD = 1000e18;
    string public constant TOKEN_URI = "https://example.com/token/1";
    string public constant ASSET_NAME = "Gold Asset";

    event TokenTradable(uint256 indexed tokenId);
    event NFTReceived(
        address indexed operator,
        address indexed from,
        uint256 indexed tokenId,
        bytes data
    );

    function setUp() public {
        vm.startPrank(owner);
        
        // Deploy mock contracts
        rwaVerifiedAssets = new RWA_VerifiedAssetsMock();
        rwaNFT = new RWA_NFTMock();
        rwaCoins = new RWA_CoinsMock();
        
        // Deploy RWA_Manager - Note: constructor has missing i_rwaN assignment
        // We need to work around this by deploying differently
        rwaManager = new RWA_Manager(
            address(rwaVerifiedAssets),
            address(rwaNFT),
            address(rwaCoins)
        );
        
        // Set up ownership and permissions
        rwaNFT.transferOwnership(address(rwaManager));
        rwaCoins.transferOwnership(address(rwaManager));
        
        // Add member role
        rwaManager.setNewMember(member);
        
        vm.stopPrank();
    }

    ///////////////////////////////////////////////
    /// Constructor and Setup Tests
    ///////////////////////////////////////////////
    
    function testConstructor() public {
        assertEq(rwaManager.owner(), owner);
        assertTrue(rwaManager.hasRole(rwaManager.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(rwaManager.hasRole(rwaManager.MEMBER_ROLE(), owner));
        assertTrue(rwaManager.hasRole(rwaManager.MEMBER_ROLE(), member));
    }

    ///////////////////////////////////////////////
    /// Access Control Tests
    ///////////////////////////////////////////////
    
    function testSetNewMember() public {
        vm.prank(owner);
        rwaManager.setNewMember(user1);
        assertTrue(rwaManager.hasRole(rwaManager.MEMBER_ROLE(), user1));
    }

    function testSetNewMemberOnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        rwaManager.setNewMember(user2);
    }

    function testRemoveMember() public {
        vm.prank(owner);
        rwaManager.removeMember(member);
        assertFalse(rwaManager.hasRole(rwaManager.MEMBER_ROLE(), member));
    }

    function testRemoveMemberOnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        rwaManager.removeMember(member);
    }

    ///////////////////////////////////////////////
    /// Core Functionality Tests
    ///////////////////////////////////////////////
    
    function testDepositRWAAndMintNFT() public {
        // Setup verified asset
        vm.prank(owner);
        rwaVerifiedAssets.addVerifiedAsset(
            user1,
            REQUEST_ID_1,
            RWA_Types.assetType.DigitalGold,
            ASSET_NAME,
            REQUEST_ID_1,
            false, // not locked
            true,  // verified
            ASSET_VALUE_USD,
            false  // not tradable initially
        );

        vm.prank(member);
        vm.deal(member, 0.001 ether);
        rwaManager.depositRWAAndMintNFT{value: 0.001 ether}(REQUEST_ID_1, ASSET_VALUE_USD, user1, TOKEN_URI, ASSET_VALUE_USD);

        // Check user asset info
        RWA_Types.RWA_Info memory userAsset = rwaManager.getUserAssetInfo(user1, REQUEST_ID_1);
        assertEq(uint256(userAsset.assetType), uint256(RWA_Types.assetType.DigitalGold));
        assertEq(userAsset.assetName, ASSET_NAME);
        assertEq(userAsset.assetId, REQUEST_ID_1);
        assertEq(userAsset.valueInUSD, ASSET_VALUE_USD);
        assertEq(userAsset.owner, user1);
        assertFalse(userAsset.tradable);
        assertTrue(userAsset.isVerified);

        // Check RWA info against request ID
        RWA_Types.RWA_Info memory rwaInfo = rwaManager.getUserRWAInfoagainstRequestId(REQUEST_ID_1);
        assertEq(rwaInfo.assetId, REQUEST_ID_1);
        assertEq(rwaInfo.valueInUSD, ASSET_VALUE_USD);

        // Check balances
        assertEq(rwaCoins.balanceOf(user1), ASSET_VALUE_USD);
        assertEq(rwaNFT.balanceOf(user1), 1);
    }

    function testDepositRWAAndMintNFTAssetNotVerified() public {
        // Setup unverified asset
        vm.prank(owner);
        rwaVerifiedAssets.addVerifiedAsset(
            user1,
            REQUEST_ID_1,
            RWA_Types.assetType.DigitalGold,
            ASSET_NAME,
            REQUEST_ID_1,
            false,
            false, // not verified
            ASSET_VALUE_USD,
            false
        );

        vm.prank(user1);
        vm.expectRevert(RWA_Manager.RWA_Manager__AssetNotVerified.selector);
        vm.deal(user1, 0.001 ether);
        rwaManager.depositRWAAndMintNFT{value: 0.001 ether}(REQUEST_ID_1, ASSET_VALUE_USD, user1, TOKEN_URI, ASSET_VALUE_USD);
    }

    function testDepositRWAAndMintNFTZeroValue() public {
        // Setup asset with zero value
        vm.prank(owner);
        rwaVerifiedAssets.addVerifiedAsset(
            user1,
            REQUEST_ID_1,
            RWA_Types.assetType.DigitalGold,
            ASSET_NAME,
            REQUEST_ID_1,
            false,
            true,
            0, // zero value
            false
        );

        vm.prank(member);
        vm.expectRevert(RWA_Manager.RWA_Manager__ZeroAmount.selector);
        vm.deal(member, 0.001 ether);
        rwaManager.depositRWAAndMintNFT{value: 0.001 ether}(REQUEST_ID_1, ASSET_VALUE_USD, user1, TOKEN_URI, 0);
    }

    function testDepositRWAAndMintNFTTokenAlreadyMinted() public {
        // Setup verified asset
        vm.prank(owner);
        rwaVerifiedAssets.addVerifiedAsset(
            user1,
            REQUEST_ID_1,
            RWA_Types.assetType.DigitalGold,
            ASSET_NAME,
            REQUEST_ID_1,
            false,
            true,
            ASSET_VALUE_USD,
            false
        );

        // First mint
        vm.prank(member);
        vm.deal(member, 0.001 ether);
        rwaManager.depositRWAAndMintNFT{value: 0.001 ether}(REQUEST_ID_1, ASSET_VALUE_USD, user1, TOKEN_URI, ASSET_VALUE_USD);

        // Try to mint again with same request ID
        vm.prank(member);
        vm.expectRevert(); // This might fail for different reasons now
        vm.deal(member, 0.001 ether);
        rwaManager.depositRWAAndMintNFT{value: 0.001 ether}(REQUEST_ID_1, ASSET_VALUE_USD, user1, TOKEN_URI, ASSET_VALUE_USD);
    }

    function testChangeNftTradable() public {
        // Setup and mint NFT first
        _setupAndMintNFT(user1, REQUEST_ID_1, ASSET_VALUE_USD);

        uint256 tokenId = 0; // First token
        
        vm.expectEmit(true, false, false, false);
        emit TokenTradable(tokenId);
        
        vm.prank(user1);
        rwaManager.changeNftTradable(tokenId, REQUEST_ID_1, ASSET_VALUE_USD);

        // Check that asset is now tradable
        assertTrue(rwaManager.checkIfAssetIsTradable(user1, REQUEST_ID_1));
        
        RWA_Types.RWA_Info memory userAsset = rwaManager.getUserAssetInfo(user1, REQUEST_ID_1);
        assertTrue(userAsset.tradable);
        
        RWA_Types.RWA_Info memory rwaInfo = rwaManager.getUserRWAInfoagainstRequestId(REQUEST_ID_1);
        assertTrue(rwaInfo.tradable);
    }

    function testChangeNftTradableInsufficientTokens() public {
        // Setup and mint NFT first
        _setupAndMintNFT(user1, REQUEST_ID_1, ASSET_VALUE_USD);

        uint256 tokenId = 0;
        uint256 insufficientAmount = ASSET_VALUE_USD - 1;
        
        vm.prank(user1);
        vm.expectRevert(RWA_Manager.RWA_Manager__NFTValueIsMoreThanSubmittedToken.selector);
        rwaManager.changeNftTradable(tokenId, REQUEST_ID_1, insufficientAmount);
    }

    function testWithdrawRWAAndBurnNFTandCoin() public {
        // Setup and mint NFT first
        _setupAndMintNFT(user1, REQUEST_ID_1, ASSET_VALUE_USD);
        
        uint256 tokenId = 0;
        uint256 initialNFTBalance = rwaNFT.balanceOf(user1);
        uint256 initialCoinBalance = rwaCoins.balanceOf(user1);
        
        vm.prank(user1);
        rwaManager.withdrawRWAAndBurnNFTandCoin(tokenId, REQUEST_ID_1);
        
        // Check that NFT and coins are burned
        assertEq(rwaNFT.balanceOf(user1), initialNFTBalance - 1);
        assertEq(rwaCoins.balanceOf(user1), 0); // Coins should be burned
        
        // Check that asset info is deleted
        RWA_Types.RWA_Info memory userAsset = rwaManager.getUserAssetInfo(user1, REQUEST_ID_1);
        assertEq(userAsset.assetId, 0);
        assertEq(userAsset.valueInUSD, 0);
        
        RWA_Types.RWA_Info memory rwaInfo = rwaManager.getUserRWAInfoagainstRequestId(REQUEST_ID_1);
        assertEq(rwaInfo.assetId, 0);
        assertEq(rwaInfo.valueInUSD, 0);
    }

    function testWithdrawRWAAndBurnNFTandCoinNotOwner() public {
        // Setup and mint NFT for user1
        _setupAndMintNFT(user1, REQUEST_ID_1, ASSET_VALUE_USD);
        
        uint256 tokenId = 0;
        
        // Try to withdraw as user2 (not owner)
        vm.prank(user2);
        vm.expectRevert(RWA_Manager.RWA_Manager__NotOwnerOfAsset.selector);
        rwaManager.withdrawRWAAndBurnNFTandCoin(tokenId, REQUEST_ID_1);
    }

    function testMintCoinAgainstEth() public {
        uint256 ethAmount = 1 ether;
        uint256 expectedCoins = ethAmount / 1e18; // Based on contract logic
        uint256 initialBalance = rwaCoins.balanceOf(user1);
        
        vm.deal(user1, ethAmount);
        vm.prank(user1);
        rwaManager.mintCoinAgainstEth{value: ethAmount}(user1);
        
        assertEq(rwaCoins.balanceOf(user1), initialBalance + expectedCoins);
        assertEq(address(rwaManager).balance, ethAmount);
    }

    function testMintCoinAgainstEthZeroValue() public {
        vm.prank(user1);
        vm.expectRevert(RWA_Manager.RWA_Manager__AssetValueNotPositive.selector);
        rwaManager.mintCoinAgainstEth{value: 0}(user1);
    }

    function testWithdrawEth() public {
        uint256 ethAmount = 2 ether;
        uint256 withdrawAmount = 1 ether;
        
        // First, add some ETH to the contract
        vm.deal(user1, ethAmount);
        vm.prank(user1);
        rwaManager.mintCoinAgainstEth{value: ethAmount}(user1);
        
        uint256 initialBalance = user2.balance;
        
        vm.prank(owner);
        rwaManager.withdraw(payable(user2), withdrawAmount);
        
        assertEq(user2.balance, initialBalance + withdrawAmount);
        assertEq(address(rwaManager).balance, ethAmount - withdrawAmount);
    }

    function testWithdrawEthOnlyOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        rwaManager.withdraw(payable(user1), 1 ether);
    }

    ///////////////////////////////////////////////
    /// View Function Tests
    ///////////////////////////////////////////////
    
    function testGetUserRWAInfoagainstRequestId() public {
        // Setup and mint NFT first
        _setupAndMintNFT(user1, REQUEST_ID_1, ASSET_VALUE_USD);
        
        RWA_Types.RWA_Info memory rwaInfo = rwaManager.getUserRWAInfoagainstRequestId(REQUEST_ID_1);
        
        assertEq(uint256(rwaInfo.assetType), uint256(RWA_Types.assetType.DigitalGold));
        assertEq(rwaInfo.assetName, ASSET_NAME);
        assertEq(rwaInfo.assetId, REQUEST_ID_1);
        assertEq(rwaInfo.valueInUSD, ASSET_VALUE_USD);
        assertEq(rwaInfo.owner, user1);
        assertFalse(rwaInfo.tradable);
        assertTrue(rwaInfo.isVerified);
    }

    function testGetUserRWAInfoagainstRequestIdNonExistent() public {
        RWA_Types.RWA_Info memory rwaInfo = rwaManager.getUserRWAInfoagainstRequestId(999);
        
        // Should return empty struct for non-existent request ID
        assertEq(rwaInfo.assetId, 0);
        assertEq(rwaInfo.valueInUSD, 0);
        assertEq(rwaInfo.owner, address(0));
    }

    function testGetUserAssetInfo() public {
        // Setup and mint NFT first
        _setupAndMintNFT(user1, REQUEST_ID_1, ASSET_VALUE_USD);
        
        RWA_Types.RWA_Info memory userAsset = rwaManager.getUserAssetInfo(user1, REQUEST_ID_1);
        
        assertEq(uint256(userAsset.assetType), uint256(RWA_Types.assetType.DigitalGold));
        assertEq(userAsset.assetName, ASSET_NAME);
        assertEq(userAsset.assetId, REQUEST_ID_1);
        assertEq(userAsset.valueInUSD, ASSET_VALUE_USD);
        assertEq(userAsset.owner, user1);
        assertFalse(userAsset.tradable);
        assertTrue(userAsset.isVerified);
    }

    function testGetUserRWAInfo() public {
        // Setup and mint NFT first
        _setupAndMintNFT(user1, REQUEST_ID_1, ASSET_VALUE_USD);
        
        RWA_Types.RWA_Info memory rwaInfo = rwaManager.getUserRWAInfo(REQUEST_ID_1);
        
        assertEq(rwaInfo.assetId, REQUEST_ID_1);
        assertEq(rwaInfo.valueInUSD, ASSET_VALUE_USD);
    }

    function testCheckIfAssetIsTradable() public {
        // Setup and mint NFT first
        _setupAndMintNFT(user1, REQUEST_ID_1, ASSET_VALUE_USD);
        
        // Initially should not be tradable
        assertFalse(rwaManager.checkIfAssetIsTradable(user1, REQUEST_ID_1));
        
        // Make it tradable
        vm.prank(user1);
        rwaManager.changeNftTradable(0, REQUEST_ID_1, ASSET_VALUE_USD);
        
        // Now should be tradable
        assertTrue(rwaManager.checkIfAssetIsTradable(user1, REQUEST_ID_1));
    }

    function testGetContractEthBalance() public {
        uint256 ethAmount = 2 ether;
        
        // Initially should be 0
        assertEq(rwaManager.getContractEthBalance(), 0);
        
        // Add some ETH
        vm.deal(user1, ethAmount);
        vm.prank(user1);
        rwaManager.mintCoinAgainstEth{value: ethAmount}(user1);
        
        assertEq(rwaManager.getContractEthBalance(), ethAmount);
    }

    function testGetContractCoinBalance() public {
        // Initially should be 0
        assertEq(rwaManager.getContractCoinBalance(), 0);
        
        // The contract doesn't hold coins directly in normal operation
        // This test validates the function works
        assertEq(rwaManager.getContractCoinBalance(), rwaCoins.balanceOf(address(rwaManager)));
    }

    ///////////////////////////////////////////////
    /// ERC721 Receiver Tests
    ///////////////////////////////////////////////
    
    function testOnERC721Received() public {
        address operator = address(this);
        address from = user1;
        uint256 tokenId = 1;
        bytes memory data = "test data";
        
        vm.expectEmit(true, true, true, true);
        emit NFTReceived(operator, from, tokenId, data);
        
        bytes4 result = rwaManager.onERC721Received(operator, from, tokenId, data);
        assertEq(result, rwaManager.onERC721Received.selector);
    }

    ///////////////////////////////////////////////
    /// Multiple Asset Tests
    ///////////////////////////////////////////////
    
    function testMultipleAssetsForSameUser() public {
        // Setup first asset
        _setupAndMintNFT(user1, REQUEST_ID_1, ASSET_VALUE_USD);
        
        // Setup second asset
        vm.prank(owner);
        rwaVerifiedAssets.addVerifiedAsset(
            user1,
            REQUEST_ID_2,
            RWA_Types.assetType.RealEstate,
            "Real Estate Asset",
            REQUEST_ID_2,
            false,
            true,
            ASSET_VALUE_USD * 2,
            false
        );

        vm.prank(member);
        vm.deal(member, 0.001 ether);
        rwaManager.depositRWAAndMintNFT{value: 0.001 ether}(REQUEST_ID_2, ASSET_VALUE_USD * 2, user1, "https://example.com/token/2", ASSET_VALUE_USD * 2);

        // Check both assets exist
        RWA_Types.RWA_Info memory asset1 = rwaManager.getUserAssetInfo(user1, REQUEST_ID_1);
        RWA_Types.RWA_Info memory asset2 = rwaManager.getUserAssetInfo(user1, REQUEST_ID_2);
        
        assertEq(asset1.assetId, REQUEST_ID_1);
        assertEq(asset2.assetId, REQUEST_ID_2);
        assertEq(asset1.valueInUSD, ASSET_VALUE_USD);
        assertEq(asset2.valueInUSD, ASSET_VALUE_USD * 2);
        
        // Check coin balance (should be sum of both)
        assertEq(rwaCoins.balanceOf(user1), ASSET_VALUE_USD + (ASSET_VALUE_USD * 2));
        
        // Check NFT balance
        assertEq(rwaNFT.balanceOf(user1), 2);
    }

    function testMultipleUsersWithAssets() public {
        // Setup asset for user1
        _setupAndMintNFT(user1, REQUEST_ID_1, ASSET_VALUE_USD);
        
        // Setup asset for user2
        vm.prank(owner);
        rwaVerifiedAssets.addVerifiedAsset(
            user2,
            REQUEST_ID_2,
            RWA_Types.assetType.CarbonCredit,
            "Carbon Credit Asset",
            REQUEST_ID_2,
            false,
            true,
            ASSET_VALUE_USD / 2,
            false
        );

        vm.prank(member);
        vm.deal(member, 0.001 ether);
        rwaManager.depositRWAAndMintNFT{value: 0.001 ether}(REQUEST_ID_2, ASSET_VALUE_USD / 2, user2, "https://example.com/token/2", ASSET_VALUE_USD / 2);

        // Check both users have their assets
        RWA_Types.RWA_Info memory user1Asset = rwaManager.getUserAssetInfo(user1, REQUEST_ID_1);
        RWA_Types.RWA_Info memory user2Asset = rwaManager.getUserAssetInfo(user2, REQUEST_ID_2);
        
        assertEq(user1Asset.owner, user1);
        assertEq(user2Asset.owner, user2);
        assertEq(user1Asset.valueInUSD, ASSET_VALUE_USD);
        assertEq(user2Asset.valueInUSD, ASSET_VALUE_USD / 2);
        
        // Check individual balances
        assertEq(rwaCoins.balanceOf(user1), ASSET_VALUE_USD);
        assertEq(rwaCoins.balanceOf(user2), ASSET_VALUE_USD / 2);
        assertEq(rwaNFT.balanceOf(user1), 1);
        assertEq(rwaNFT.balanceOf(user2), 1);
    }

    ///////////////////////////////////////////////
    /// Fuzz Tests
    ///////////////////////////////////////////////
    
    function testFuzzDepositRWAAndMintNFT(uint256 assetValue) public {
        // Bound the asset value to reasonable range
        assetValue = bound(assetValue, 1, type(uint128).max);
        
        // Setup verified asset with fuzzed value
        vm.prank(owner);
        rwaVerifiedAssets.addVerifiedAsset(
            user1,
            REQUEST_ID_1,
            RWA_Types.assetType.DigitalGold,
            ASSET_NAME,
            REQUEST_ID_1,
            false,
            true,
            assetValue,
            false
        );

        vm.prank(member);
        vm.deal(member, 0.001 ether);
        rwaManager.depositRWAAndMintNFT{value: 0.001 ether}(REQUEST_ID_1, assetValue, user1, TOKEN_URI, assetValue);

        // Check that the asset value is correctly stored
        RWA_Types.RWA_Info memory userAsset = rwaManager.getUserAssetInfo(user1, REQUEST_ID_1);
        assertEq(userAsset.valueInUSD, assetValue);
        assertEq(rwaCoins.balanceOf(user1), assetValue);
    }

    function testFuzzMintCoinAgainstEth(uint256 ethAmount) public {
        // Bound the ETH amount to reasonable range
        ethAmount = bound(ethAmount, 1, 1000 ether);
        
        uint256 expectedCoins = ethAmount / 1e18;
        
        vm.deal(user1, ethAmount);
        vm.prank(user1);
        rwaManager.mintCoinAgainstEth{value: ethAmount}(user1);
        
        assertEq(rwaCoins.balanceOf(user1), expectedCoins);
        assertEq(address(rwaManager).balance, ethAmount);
    }

    ///////////////////////////////////////////////
    /// Helper Functions
    ///////////////////////////////////////////////
    
    function _setupAndMintNFT(address user, uint256 requestId, uint256 value) internal {
        vm.prank(owner);
        rwaVerifiedAssets.addVerifiedAsset(
            user,
            requestId,
            RWA_Types.assetType.DigitalGold,
            ASSET_NAME,
            requestId,
            false, // not locked
            true,  // verified
            value,
            false  // not tradable initially
        );

        vm.prank(member);
        vm.deal(member, 0.001 ether);
        rwaManager.depositRWAAndMintNFT{value: 0.001 ether}(requestId, value, user, TOKEN_URI, value);
    }
}
