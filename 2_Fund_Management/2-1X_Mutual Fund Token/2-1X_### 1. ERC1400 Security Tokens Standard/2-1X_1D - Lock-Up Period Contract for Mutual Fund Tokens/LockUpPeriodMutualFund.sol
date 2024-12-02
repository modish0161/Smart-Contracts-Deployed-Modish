// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1400/ERC1400.sol";

contract LockUpPeriodMutualFund is ERC1400, Ownable, Pausable, ReentrancyGuard, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    struct LockUp {
        uint256 releaseTime;
        bool isLocked;
    }

    // Mapping to track the lock-up periods for each investor
    mapping(address => LockUp) public lockUps;

    event LockUpSet(address indexed investor, uint256 releaseTime);
    event LockUpRemoved(address indexed investor);
    event TransferBlocked(address indexed from, address indexed to, uint256 amount, string reason);

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    )
        ERC1400(name, symbol, new address )
    {
        _mint(msg.sender, initialSupply, "", "");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(ISSUER_ROLE, msg.sender);
    }

    // Set lock-up period for a specific investor
    function setLockUpPeriod(address investor, uint256 releaseTime) external onlyRole(ISSUER_ROLE) {
        require(investor != address(0), "Invalid address");
        require(releaseTime > block.timestamp, "Release time must be in the future");

        lockUps[investor] = LockUp(releaseTime, true);
        emit LockUpSet(investor, releaseTime);
    }

    // Remove lock-up period for a specific investor
    function removeLockUpPeriod(address investor) external onlyRole(ISSUER_ROLE) {
        require(investor != address(0), "Invalid address");
        require(lockUps[investor].isLocked, "No lock-up period set for this investor");

        lockUps[investor] = LockUp(0, false);
        emit LockUpRemoved(investor);
    }

    // Override ERC1400 transfer function to include lock-up check
    function _transferWithData(
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal override whenNotPaused {
        require(lockUps[from].releaseTime <= block.timestamp, "Tokens are locked");
        super._transferWithData(from, to, value, data);
    }

    // Check if an investor is under a lock-up period
    function isUnderLockUp(address investor) external view returns (bool) {
        return lockUps[investor].isLocked && block.timestamp < lockUps[investor].releaseTime;
    }

    // Get lock-up release time for an investor
    function getLockUpReleaseTime(address investor) external view returns (uint256) {
        require(lockUps[investor].isLocked, "No lock-up period set for this investor");
        return lockUps[investor].releaseTime;
    }

    // Transfer ownership override to ensure role setup for new owner
    function transferOwnership(address newOwner) public override onlyOwner {
        _setupRole(ADMIN_ROLE, newOwner);
        _setupRole(ISSUER_ROLE, newOwner);
        super.transferOwnership(newOwner);
    }

    // Pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }
}
