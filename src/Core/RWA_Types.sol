//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;
library RWA_Types{
    enum assetType {
        CarbonCredit,
        DigitalGold,
        RealEstate,
        Other
    }
    struct RWA_Info{
        assetType assetType;
        string assetName;
        uint256 assetId;
        bool isLocked;
        bool isVerified;
        uint256 valueInUSD;
        address owner;
        bool tradable;
    }
}