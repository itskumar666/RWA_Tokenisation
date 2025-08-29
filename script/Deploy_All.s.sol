// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

// Core RWA minting/managing
import {RWA_Coins} from "../src/CoinMintingAndManaging/RWA_Coins.sol";
import {RWA_NFT} from "../src/CoinMintingAndManaging/RWA_NFT.sol";
import {RWA_VerifiedAssets} from "../src/CoinMintingAndManaging/RWA_VerifiedAssets.sol";
import {RWA_Manager} from "../src/CoinMintingAndManaging/RWA_Manager.sol";

// Lending suite
import {NFTVault} from "../src/Lending/NFTVault.sol";
import {LendingManager} from "../src/Lending/LendingManager.sol";
import {AuctionHouse} from "../src/Lending/AuctionHouse.sol";

// Staking
import {StakingCoin} from "../src/Staking/StakingCoin.sol";

// Chainlink Automation
import {ChainlinkAutomation} from "../src/ChainlinnkServices/Automation.sol";

contract Deploy_All is Script {
    // Defaults (overridable via env)
    uint256 internal constant DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    // Env keys
    string internal constant ENV_PRIVATE_KEY = "PRIVATE_KEY";
    string internal constant ENV_MIN_RETURN_PERIOD = "MIN_RETURN_PERIOD"; // seconds
    string internal constant ENV_AUCTION_DURATION = "AUCTION_DURATION";   // seconds
    string internal constant ENV_AUCTION_DEFAULT_PRICE = "AUCTION_DEFAULT_PRICE"; // in RWAC (18d)
    string internal constant ENV_AUTOMATION_INTERVAL = "AUTOMATION_INTERVAL"; // seconds
    string internal constant ENV_STAKING_APY_PERCENT = "STAKING_APY_PERCENT"; // integer percent, e.g., 10 for 10%
    string internal constant ENV_STAKING_LOCK_PERIOD = "STAKING_LOCK_PERIOD"; // seconds
    string internal constant ENV_STAKING_MIN_FINE = "STAKING_MIN_FINE"; // in RWAC (18d)
    string internal constant ENV_STAKING_REWARD_MINT = "STAKING_REWARD_MINT"; // initial reward top-up to staking (18d)

    struct Addresses {
        address deployer;
        address rwaCoins;
        address rwaNft;
        address rwaVerifiedAssets;
        address rwaManager;
        address nftVault;
        address auctionHouse;
        address lendingManager;
        address staking;
        address automation;
    }

    function run() external returns (Addresses memory addrs) {
        // 1) Load config/env with sensible defaults
        uint256 pk = _getPrivateKeyOrDefault();
        address deployer = vm.addr(pk);

        uint256 minReturnPeriod = _getUintOrDefault(ENV_MIN_RETURN_PERIOD, 1 days);
        uint256 auctionDuration = _getUintOrDefault(ENV_AUCTION_DURATION, 3 days);
        uint256 auctionDefaultPrice = _getUintOrDefault(ENV_AUCTION_DEFAULT_PRICE, 100 ether);
        uint256 automationInterval = _getUintOrDefault(ENV_AUTOMATION_INTERVAL, 1 days);
        uint256 stakingApyPercent = _getUintOrDefault(ENV_STAKING_APY_PERCENT, 10); // 10% APY default
        uint256 stakingLockPeriod = _getUintOrDefault(ENV_STAKING_LOCK_PERIOD, 7 days);
        uint256 stakingMinFine = _getUintOrDefault(ENV_STAKING_MIN_FINE, 1 ether);
        uint256 stakingRewardMint = _getUintOrDefault(ENV_STAKING_REWARD_MINT, 1_000_000 ether);

        // Convert APY% to per-second rewardRate scaled by 1e18
        // rewardRate = (APY% / 100) / secondsInYear * 1e18
        uint256 secondsInYear = 365 days;
        uint256 rewardRate = (stakingApyPercent * 1e16) / secondsInYear; // 1e16 = 1e18 / 100

        console.log("Deployer:", deployer);
        vm.startBroadcast(pk);

        // 2) Deploy base tokens/contracts
        RWA_Coins rwaCoins = new RWA_Coins();
        RWA_NFT rwaNft = new RWA_NFT();
        RWA_VerifiedAssets rwaVA = new RWA_VerifiedAssets(deployer);

    // 3) Deploy NFTVault temporarily owned by deployer; transfer to manager later
    NFTVault nftVault = new NFTVault(address(rwaNft), deployer);

    // 4) Deploy AuctionHouse
        AuctionHouse auctionHouse = new AuctionHouse(
            address(rwaNft),
            address(rwaCoins),
            auctionDuration,
            deployer,
            auctionDefaultPrice
        );

    // 5) Deploy RWA_Manager now that base deps exist
    RWA_Manager rwaManager = new RWA_Manager(
            address(rwaVA),
            address(rwaNft),
            address(rwaCoins)
        );

        // 6) Now deploy LendingManager (needs nftVault + auctionHouse + rwaManager)
    LendingManager lendingManager = new LendingManager(
            address(rwaCoins),
            address(rwaNft),
            address(nftVault),
            address(rwaManager),
            minReturnPeriod,
            address(auctionHouse)
        );

        // 7) Deploy Staking (we'll seed rewards and wire roles below)
        StakingCoin staking = new StakingCoin(
            address(rwaCoins),
            1, // any non-zero value to satisfy constructor require
            rewardRate,
            stakingLockPeriod,
            stakingMinFine
        );

    // 8) Roles and ownership wiring
    // First, grant roles while deployer is still the owner
    rwaCoins.addMinter(address(rwaManager));
    rwaCoins.addMinter(address(staking));
    // Seed reward pool before ownership transfer
    rwaCoins.mint(address(staking), stakingRewardMint);
    // Then transfer ownerships
    // RWA_NFT: RWA_Manager must be owner to mint/burn
    rwaNft.transferOwnership(address(rwaManager));
    // RWA_Coins: make RWA_Manager the owner (burn authority)
    rwaCoins.transferOwnership(address(rwaManager));


        // RWA_VerifiedAssets: add RWA_Manager as MEMBER
        rwaVA.addMember(address(rwaManager));

    // NFTVault: move owner from deployer to LendingManager so only it can control
        nftVault.transferOwnership(address(lendingManager));

    // 9) Deploy Chainlink Automation pointing to LendingManager
        ChainlinkAutomation automation = new ChainlinkAutomation(
            automationInterval,
            address(lendingManager)
        );

        vm.stopBroadcast();

        // 10) Log & persist addresses
        addrs = Addresses({
            deployer: deployer,
            rwaCoins: address(rwaCoins),
            rwaNft: address(rwaNft),
            rwaVerifiedAssets: address(rwaVA),
            rwaManager: address(rwaManager),
            nftVault: address(nftVault),
            auctionHouse: address(auctionHouse),
            lendingManager: address(lendingManager),
            staking: address(staking),
            automation: address(automation)
        });

        console.log("RWA_Coins:", addrs.rwaCoins);
        console.log("RWA_NFT:", addrs.rwaNft);
        console.log("RWA_VerifiedAssets:", addrs.rwaVerifiedAssets);
        console.log("RWA_Manager:", addrs.rwaManager);
        console.log("NFTVault:", addrs.nftVault);
        console.log("AuctionHouse:", addrs.auctionHouse);
        console.log("LendingManager:", addrs.lendingManager);
        console.log("StakingCoin:", addrs.staking);
        console.log("ChainlinkAutomation:", addrs.automation);

        // Write a JSON file only on local networks (avoid FS errors on live RPCs)
        if (block.chainid == 31337) {
            string memory root = "broadcast/deployments";
            // Ensure dir exists before writing
            vm.createDir(root, true);
            string memory obj = "addrs";
            vm.serializeAddress(obj, "deployer", addrs.deployer);
            vm.serializeAddress(obj, "rwaCoins", addrs.rwaCoins);
            vm.serializeAddress(obj, "rwaNft", addrs.rwaNft);
            vm.serializeAddress(obj, "rwaVerifiedAssets", addrs.rwaVerifiedAssets);
            vm.serializeAddress(obj, "rwaManager", addrs.rwaManager);
            vm.serializeAddress(obj, "nftVault", addrs.nftVault);
            vm.serializeAddress(obj, "auctionHouse", addrs.auctionHouse);
            vm.serializeAddress(obj, "lendingManager", addrs.lendingManager);
            vm.serializeAddress(obj, "staking", addrs.staking);
            vm.serializeAddress(obj, "automation", addrs.automation);
            string memory out = vm.serializeString(obj, "chainId", _toString(block.chainid));
            string memory file = string.concat(root, "/", _toString(block.chainid), ".json");
            // Attempt to write JSON; ignore errors in environments that restrict FS writes
            try vm.writeJson(out, file) { } catch {}
        }

        return addrs;
    }

    // ---------------------- helpers ----------------------
    function _getPrivateKeyOrDefault() internal returns (uint256) {
        try vm.envUint(ENV_PRIVATE_KEY) returns (uint256 pk) {
            return pk;
        } catch {
            return DEFAULT_ANVIL_KEY; // fallback for local anvil
        }
    }

    function _getUintOrDefault(string memory key, uint256 defVal) internal returns (uint256) {
        try vm.envUint(key) returns (uint256 v) {
            return v;
        } catch {
            return defVal;
        }
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
