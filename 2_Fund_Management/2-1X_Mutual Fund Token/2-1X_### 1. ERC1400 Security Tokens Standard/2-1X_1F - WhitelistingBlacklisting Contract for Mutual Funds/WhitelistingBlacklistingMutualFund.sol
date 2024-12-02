// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1400/ERC1400.sol";

contract WhitelistingBlacklistingMutualFund is ERC1400, Ownable, Pausable, ReentrancyGuard, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    mapping(address => bool) public whitelisted;
    mapping(address => bool) public blacklisted;

    event AddressWhitelisted(address indexed account);
    event AddressBlacklisted(address indexed account);
    event AddressRemovedFromWhitelist(address indexed account);
    event AddressRemovedFromBlacklist(address indexed account);
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
        _setupRole(COMPLIANCE_ROLE, msg.sender);
    }

    // Whitelist an address to allow participation
    function whitelistAddress(address account) external onlyRole(COMPLIANCE_ROLE) {
        require(account != address(0), "Invalid address");
        require(!whitelisted[account], "Address already whitelisted");
        whitelisted[account] = true;
        emit AddressWhitelisted(account);
    }

    // Remove an address from the whitelist
    function removeWhitelistAddress(address account) external onlyRole(COMPLIANCE_ROLE) {
        require(account != address(0), "Invalid address");
        require(whitelisted[account], "Address not in whitelist");
        whitelisted[account] = false;
        emit AddressRemovedFromWhitelist(account);
    }

    // Blacklist an address to prevent participation
    function blacklistAddress(address account) external onlyRole(COMPLIANCE_ROLE) {
        require(account != address(0), "Invalid address");
        require(!blacklisted[account], "Address already blacklisted");
        blacklisted[account] = true;
        emit AddressBlacklisted(account);
    }

    // Remove an address from the blacklist
    function removeBlacklistAddress(address account) external onlyRole(COMPLIANCE_ROLE) {
        require(account != address(0), "Invalid address");
        require(blacklisted[account], "Address not in blacklist");
        blacklisted[account] = false;
        emit AddressRemovedFromBlacklist(account);
    }

    // Override ERC1400 transfer function to enforce whitelist and blacklist checks
    function _transferWithData(
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal override whenNotPaused {
        require(whitelisted[from], "Sender is not whitelisted");
        require(whitelisted[to], "Recipient is not whitelisted");
        require(!blacklisted[from], "Sender is blacklisted");
        require(!blacklisted[to], "Recipient is blacklisted");

        super._transferWithData(from, to, value, data);
    }

    // Check if an address is whitelisted
    function isWhitelisted(address account) external view returns (bool) {
        return whitelisted[account];
    }

    // Check if an address is blacklisted
    function isBlacklisted(address account) external view returns (bool) {
        return blacklisted[account];
    }

    // Pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    // Transfer ownership override to ensure role setup for new owner
    function transferOwnership(address newOwner) public override onlyOwner {
        _setupRole(ADMIN_ROLE, newOwner);
        _setupRole(COMPLIANCE_ROLE, newOwner);
        super.transferOwnership(newOwner);
    }

    // Emergency function to withdraw all funds (Owner only)
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available for withdrawal");
        payable(owner()).transfer(balance);
    }
}
