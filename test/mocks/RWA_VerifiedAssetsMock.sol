//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "../../src/CoinMintingAndManaging/RWA_Types.sol";

contract RWA_VerifiedAssetsMock is Ownable {
    error RWA_VerifiedAssets__AssetNotVerified();
    error RWA_VerifiedAssets__AssetValueNotPositive();
    
    // User address -> Request ID -> Asset Info
    mapping(address => mapping(uint256 => RWA_Types.RWA_Info)) public verifiedAssets;
    
    event AssetVerified(address indexed user, uint256 indexed requestId, uint256 valueInUSD);
    event AssetValueUpdated(address indexed user, uint256 indexed requestId, uint256 newValue);
    
    constructor() Ownable(msg.sender) {}
    
    // For testing - allows setting up verified assets
    function addVerifiedAsset(
        address _user,
        uint256 _requestId,
        RWA_Types.assetType _assetType,
        string memory _assetName,
        uint256 _assetId,
        bool _isLocked,
        bool _isVerified,
        uint256 _valueInUSD,
        bool _tradable
    ) external {
        verifiedAssets[_user][_requestId] = RWA_Types.RWA_Info({
            assetType: _assetType,
            assetName: _assetName,
            assetId: _assetId,
            isLocked: _isLocked,
            isVerified: _isVerified,
            valueInUSD: _valueInUSD,
            owner: _user,
            tradable: _tradable
        });
        
        emit AssetVerified(_user, _requestId, _valueInUSD);
    }
    
    function upDateAssetValue(
        address _user,
        uint256 _requestId,
        uint256 _newValue,
        bool _isLocked,
        bool _tradable
    ) external {
        if (!verifiedAssets[_user][_requestId].isVerified) {
            revert RWA_VerifiedAssets__AssetNotVerified();
        }
        if (_newValue <= 0) {
            revert RWA_VerifiedAssets__AssetValueNotPositive();
        }
        
        verifiedAssets[_user][_requestId].valueInUSD = _newValue;
        verifiedAssets[_user][_requestId].isLocked = _isLocked;
        verifiedAssets[_user][_requestId].tradable = _tradable;
        
        emit AssetValueUpdated(_user, _requestId, _newValue);
    }
    
    function getVerifiedAsset(
        address _user,
        uint256 _requestId
    ) external view returns (RWA_Types.RWA_Info memory) {
        return verifiedAssets[_user][_requestId];
    }
}
