// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1404/IERC1404.sol";

contract RestrictedETFToken is IERC1404, Ownable {
    // Token details
    string public name = "Restricted ETF Token";
    string public symbol = "RETF";
    uint8 public decimals = 18;

    // Total supply
    uint256 private totalSupply_;

    // Mappings for balance and allowed transfers
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    // Whitelist and blacklist mappings
    mapping(address => bool) public whitelist;
    mapping(address => bool) public blacklist;

    // Events
    event AddressWhitelisted(address indexed account);
    event AddressBlacklisted(address indexed account);
    event AddressRemovedFromWhitelist(address indexed account);
    event AddressRemovedFromBlacklist(address indexed account);

    // ERC1404 compliance reasons
    string constant NOT_WHITELISTED = "Sender not whitelisted";
    string constant BLACKLISTED = "Sender is blacklisted";

    constructor(uint256 initialSupply) {
        totalSupply_ = initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply_;
    }

    // Function to transfer tokens
    function transfer(address to, uint256 value) external returns (bool) {
        require(isTransferAllowed(msg.sender, to), "Transfer not allowed");
        _transfer(msg.sender, to, value);
        return true;
    }

    // Internal transfer function
    function _transfer(address from, address to, uint256 value) internal {
        require(balances[from] >= value, "Insufficient balance");
        balances[from] -= value;
        balances[to] += value;
    }

    // Check if the transfer is allowed
    function isTransferAllowed(address from, address to) internal view returns (bool) {
        if (blacklist[from] || blacklist[to]) return false;
        return whitelist[from] && whitelist[to];
    }

    // Owner-only function to whitelist an address
    function addToWhitelist(address account) external onlyOwner {
        require(!whitelist[account], "Already whitelisted");
        whitelist[account] = true;
        emit AddressWhitelisted(account);
    }

    // Owner-only function to remove an address from the whitelist
    function removeFromWhitelist(address account) external onlyOwner {
        require(whitelist[account], "Not whitelisted");
        whitelist[account] = false;
        emit AddressRemovedFromWhitelist(account);
    }

    // Owner-only function to blacklist an address
    function addToBlacklist(address account) external onlyOwner {
        require(!blacklist[account], "Already blacklisted");
        blacklist[account] = true;
        emit AddressBlacklisted(account);
    }

    // Owner-only function to remove an address from the blacklist
    function removeFromBlacklist(address account) external onlyOwner {
        require(blacklist[account], "Not blacklisted");
        blacklist[account] = false;
        emit AddressRemovedFromBlacklist(account);
    }

    // Function to check the total supply
    function totalSupply() external view returns (uint256) {
        return totalSupply_;
    }

    // Function to check the balance of an address
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    // ERC1404 compliance methods
    function detectTransferRestriction(address from, address to) external view returns (uint8) {
        if (blacklist[from] || blacklist[to]) {
            return 1; // Blacklisted
        } else if (!whitelist[from] || !whitelist[to]) {
            return 2; // Not whitelisted
        }
        return 0; // No restriction
    }

    function canTransfer(address from, address to) external view returns (bool) {
        return isTransferAllowed(from, to);
    }
}
