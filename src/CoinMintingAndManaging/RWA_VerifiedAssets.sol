//SPDX License-Identifier: MIT

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
/* 
@Dev add Manager contract as a member of RWA_VerifiedAssets contract
*/

pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import "./RWA_Types.sol";

contract RWA_VerifiedAssets is Ownable,AccessControl{
    error RWA_VerifiedAssets__InvalidAddress();
    // This contract is a placeholder for the RWA_VerifiedAssets functionality.
    // It should include the necessary logic for managing verified assets.

    // Example state variable
    //mapping to store verified assets
    bytes32 public constant MEMBER_ROLE = keccak256("MEMBER_ROLE");
    mapping(address => RWA_Types.RWA_Info[]) public verifiedAssets;

    event Assetregistered(
        address indexed owner,
        RWA_Types.RWA_Info asset,
        string message
    );
    event AssetDeregistered(
        address indexed owner,
        uint256 assetId,
        string message
    );
     event OwnerAllowed(address indexed newOwner);
    event OwnerRemoved(address indexed removedOwner);


    // modifier validAddress(address _owner) {
    //     if (_owner == address(0)) {
    //         revert RWA_VerifiedAssets__InvalidAddress();
    //     }
    //     _;
    // }
  
    modifier onlyMember() {
        require(
          hasRole(MEMBER_ROLE, msg.sender),
            "Caller is not a member"
        );
        _;
    }

     constructor(address _owner) Ownable(_owner) {
        _grantRole(MEMBER_ROLE, _owner);
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    }
   
    function addMember(address newMember) external onlyOwner {
        require(newMember != address(0), "Invalid member address");
        _grantRole(MEMBER_ROLE, newMember);
        emit OwnerAllowed(newMember);
    }
    function removeMember(address member) external onlyOwner {
        require(member != address(0), "Invalid member address");
        require(hasRole(MEMBER_ROLE, member), "Member does not exist");
        _revokeRole(MEMBER_ROLE, member);
        emit OwnerRemoved(member);
    }
   //assetId is the unique identifier for the asset, so frontend have to always pass aunique assetId from wherever the asset is verified
    function registerVerifiedAsset(address owner,  bytes memory response) external onlyMember {
         (uint8 assetType_, string memory assetName_, uint256 assetId_, bool isLocked_, uint256 valueInUSD_,address owner_) =
        abi.decode(response, (uint8, string, uint256, bool, uint256,address));

    // Store in s_lastResponse
      RWA_Types.RWA_Info memory newAsset = RWA_Types.RWA_Info({
        assetType: RWA_Types.assetType(assetType_), // Cast uint8 to enum
        assetName: assetName_,
        assetId: assetId_,
        isLocked: isLocked_, // Assuming the asset is locked if this function is called
        isVerified: true, // Assuming the asset is verified if this function is called
        valueInUSD: valueInUSD_,
        owner: owner_,
        tradable: true // Assuming the asset is tradable if this function is called
    });
        verifiedAssets[msg.sender].push(newAsset);
        emit Assetregistered(
            msg.sender,
            newAsset,
            "Asset registered successfully"
        );
    }
    function DeRegisterVerifiedAsset(address owner, uint256 assetId) external onlyMember{

        RWA_Types.RWA_Info[] storage assets = verifiedAssets[owner];
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].assetId == assetId) {
                // Remove the asset by shifting elements
                assets[i] = assets[assets.length - 1];
                assets.pop();
                break;
            }
        }
        emit AssetDeregistered(
            owner,
            assetId,
            "Asset deregistered successfully"
        );
    }
    function upDateAssetValue(
        address owner,
        uint256 assetId,
        uint256 newValueInUSD,
        bool isLocked,
        bool tradable
    ) external onlyMember {
        RWA_Types.RWA_Info[] storage assets = verifiedAssets[owner];
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].assetId == assetId) {
                assets[i].valueInUSD = newValueInUSD;
                assets[i].isLocked = isLocked;
                assets[i].tradable = tradable;
                break;
            }
        }
    }
    function getVerifiedAssets(address owner) external view returns (RWA_Types.RWA_Info[] memory) {
        return verifiedAssets[owner];
    }
    function isOwnerAllowed(address _owner) external view returns (bool) {
        return hasRole(MEMBER_ROLE, _owner);
    }

}