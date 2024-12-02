// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

contract LockUpPeriodETF is Ownable {
    IERC1400 public securityToken;
    
    // Mapping to track lock-up periods
    mapping(address => uint256) private lockUpEndDate;

    event TokensLocked(address indexed investor, uint256 lockUpPeriod);
    event TokensUnlocked(address indexed investor);

    constructor(address _securityToken) {
        securityToken = IERC1400(_securityToken);
    }

    // Function to lock tokens for a specified period
    function lockTokens(uint256 lockUpPeriodInDays) external {
        require(lockUpPeriodInDays > 0, "Lock-up period must be greater than zero");
        require(lockUpEndDate[msg.sender] < block.timestamp, "Tokens are already locked");

        uint256 lockUpDuration = block.timestamp + (lockUpPeriodInDays * 1 days);
        lockUpEndDate[msg.sender] = lockUpDuration;

        emit TokensLocked(msg.sender, lockUpPeriodInDays);
    }

    // Function to check if an address's tokens are locked
    function areTokensLocked(address investor) external view returns (bool) {
        return block.timestamp < lockUpEndDate[investor];
    }

    // Function to unlock tokens after the lock-up period
    function unlockTokens() external {
        require(block.timestamp >= lockUpEndDate[msg.sender], "Lock-up period is not over");
        
        lockUpEndDate[msg.sender] = 0; // Reset lock-up end date
        emit TokensUnlocked(msg.sender);
    }

    // Function to check the end date of the lock-up period
    function getLockUpEndDate(address investor) external view returns (uint256) {
        return lockUpEndDate[investor];
    }
}
