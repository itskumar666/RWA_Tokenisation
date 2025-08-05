//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { RWA_Manager } from "../../../src/CoinMintingAndManaging/RWA_Manager.sol";
import { RWA_Types } from "../../../src/CoinMintingAndManaging/RWA_Types.sol";
import { RWA_VerifiedAssetsMock } from "../../mocks/RWA_VerifiedAssetsMock.sol";
import { RWA_NFTMock } from "../../mocks/RWA_NFTMock.sol";
import { RWA_CoinsMock } from "../../mocks/RWA_CoinsMock.sol";

contract RWA_ManagerBasicTest is Test {
    RWA_Manager public rwaManager;
    RWA_VerifiedAssetsMock public rwaVerifiedAssets;
    RWA_NFTMock public rwaNFT;
    RWA_CoinsMock public rwaCoins;

    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    address public member = address(4);

    uint256 public constant REQUEST_ID_1 = 1;
    uint256 public constant ASSET_VALUE_USD = 1000e18;

    function setUp() public {
        vm.startPrank(owner);
        
        // Deploy mock contracts
        rwaVerifiedAssets = new RWA_VerifiedAssetsMock();
        rwaNFT = new RWA_NFTMock();
        rwaCoins = new RWA_CoinsMock();
        
        // Deploy RWA_Manager
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
    /// Constructor and Basic Setup Tests
    ///////////////////////////////////////////////
    
    function testConstructor() public view {
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
    /// View Function Tests (Focus on getUserRWAInfoagainstRequestId)
    ///////////////////////////////////////////////
    
    function testGetUserRWAInfoagainstRequestIdEmpty() public view {
        // Test the function that was highlighted in the user's selection
        RWA_Types.RWA_Info memory rwaInfo = rwaManager.getUserRWAInfoagainstRequestId(REQUEST_ID_1);
        
        // Should return empty struct for non-existent request ID
        assertEq(rwaInfo.assetId, 0);
        assertEq(rwaInfo.valueInUSD, 0);
        assertEq(rwaInfo.owner, address(0));
        assertFalse(rwaInfo.isVerified);
        assertFalse(rwaInfo.tradable);
        assertFalse(rwaInfo.isLocked);
        assertEq(rwaInfo.assetName, "");
    }

    function testGetUserRWAInfoagainstRequestIdMultipleIds() public view {
        // Test multiple request IDs
        for (uint256 i = 1; i <= 5; i++) {
            RWA_Types.RWA_Info memory rwaInfo = rwaManager.getUserRWAInfoagainstRequestId(i);
            assertEq(rwaInfo.assetId, 0);
            assertEq(rwaInfo.valueInUSD, 0);
        }
    }

    function testGetUserAssetInfoEmpty() public view {
        RWA_Types.RWA_Info memory userAsset = rwaManager.getUserAssetInfo(user1, REQUEST_ID_1);
        
        assertEq(userAsset.assetId, 0);
        assertEq(userAsset.valueInUSD, 0);
        assertEq(userAsset.owner, address(0));
    }

    function testGetUserRWAInfoEmpty() public view {
        RWA_Types.RWA_Info memory rwaInfo = rwaManager.getUserRWAInfo(REQUEST_ID_1);
        
        assertEq(rwaInfo.assetId, 0);
        assertEq(rwaInfo.valueInUSD, 0);
    }

    function testCheckIfAssetIsTradableEmpty() public view {
        bool isTradable = rwaManager.checkIfAssetIsTradable(user1, REQUEST_ID_1);
        assertFalse(isTradable);
    }

    ///////////////////////////////////////////////
    /// ETH and Balance Tests
    ///////////////////////////////////////////////
    
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

    function testGetContractCoinBalance() public view {
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
        
        bytes4 result = rwaManager.onERC721Received(operator, from, tokenId, data);
        assertEq(result, rwaManager.onERC721Received.selector);
    }

    ///////////////////////////////////////////////
    /// Constants and Role Tests
    ///////////////////////////////////////////////
    
    function testMemberRoleConstant() public view {
        bytes32 memberRole = rwaManager.MEMBER_ROLE();
        assertEq(memberRole, keccak256("MEMBER_ROLE"));
    }

    ///////////////////////////////////////////////
    /// Fuzz Tests for Working Functions
    ///////////////////////////////////////////////
    
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

    function testFuzzGetUserRWAInfoagainstRequestId(uint256 requestId) public view {
        // Fuzz test the main function from user's selection
        RWA_Types.RWA_Info memory rwaInfo = rwaManager.getUserRWAInfoagainstRequestId(requestId);
        
        // For non-existent request IDs, should return empty struct
        assertEq(rwaInfo.assetId, 0);
        assertEq(rwaInfo.valueInUSD, 0);
        assertEq(rwaInfo.owner, address(0));
    }

    function testFuzzCheckIfAssetIsTradable(address user, uint256 requestId) public view {
        // Fuzz test with different users and request IDs
        bool isTradable = rwaManager.checkIfAssetIsTradable(user, requestId);
        
        // For non-existent assets, should return false
        assertFalse(isTradable);
    }

    ///////////////////////////////////////////////
    /// Error Condition Tests
    ///////////////////////////////////////////////
    
    function testDepositRWAAndMintNFTAssetNotVerified() public {
        // Setup unverified asset
        vm.prank(owner);
        rwaVerifiedAssets.addVerifiedAsset(
            user1,
            REQUEST_ID_1,
            RWA_Types.assetType.DigitalGold,
            "Gold Asset",
            REQUEST_ID_1,
            false,
            false, // not verified
            ASSET_VALUE_USD,
            false
        );

        vm.prank(member);
        vm.expectRevert(RWA_Manager.RWA_Manager__AssetNotVerified.selector);
        vm.deal(member, 0.001 ether);
        rwaManager.depositRWAAndMintNFT{value: 0.001 ether}(REQUEST_ID_1, ASSET_VALUE_USD, user1, "https://example.com/token/1", ASSET_VALUE_USD);
    }

    function testDepositRWAAndMintNFTZeroValue() public {
        // Setup asset with zero value
        vm.prank(owner);
        rwaVerifiedAssets.addVerifiedAsset(
            user1,
            REQUEST_ID_1,
            RWA_Types.assetType.DigitalGold,
            "Gold Asset",
            REQUEST_ID_1,
            false,
            true,
            0, // zero value
            false
        );

        vm.prank(member);
        vm.expectRevert(RWA_Manager.RWA_Manager__ZeroAmount.selector);
        vm.deal(member, 0.001 ether);
        rwaManager.depositRWAAndMintNFT{value: 0.001 ether}(REQUEST_ID_1, ASSET_VALUE_USD, user1, "https://example.com/token/1", 0);
    }
}
