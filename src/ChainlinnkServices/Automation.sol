// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {LendingManager} from "../Lending/LendingManager.sol";

contract ChainlinkAutomation is Ownable, AutomationCompatibleInterface {
    uint256 public immutable interval;
    uint256 public lastTimeStamp;
    LendingManager public immutable lendingManager;

    event UpkeepPerformed(uint256 timestamp);

    constructor(
        uint256 updateInterval,
        address lendingManagerAddress
    ) Ownable(msg.sender) {
        require(lendingManagerAddress != address(0), "Invalid LendingManager");
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
        lendingManager = LendingManager(lendingManagerAddress);
    }

    function checkUpkeep(
        bytes calldata
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) >= interval;
        performData = ""; // not used currently
    }

    function performUpkeep(
        bytes calldata
    ) external override {
        if ((block.timestamp - lastTimeStamp) >= interval) {
            lastTimeStamp = block.timestamp;

            // Call LendingManager's automated function
            lendingManager.performUpkeep();

            emit UpkeepPerformed(block.timestamp);
        }
    }
}
