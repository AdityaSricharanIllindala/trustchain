// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// owner - the one who deployed the contract
// lastCompletedMigration - tracks the last migration that was completed.

contract Migrations {
    address public owner = msg.sender;
    uint256 public lastCompletedMigration;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    function setCompleted(uint256 completed) public onlyOwner {
        lastCompletedMigration = completed;
    }
}
