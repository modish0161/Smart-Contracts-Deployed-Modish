// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

contract WhitelistingBlacklistingETF is Ownable {
    IERC1400 public securityToken;

    // Mapping for whitelisted addresses
    mapping(address => bool) public whitelist;
    // Mapping for blacklisted addresses
    mapping(address => bool) public blacklist;

    event AddressWhitelisted(address indexed account);
    event AddressBlacklisted(address indexed account);
    event AddressRemovedFromWhitelist(address indexed account);
    event AddressRemovedFromBlacklist(address indexed account);

    constructor(address _securityToken) {
        securityToken = IERC1400(_securityToken);
    }

    // Function to add an address to the whitelist
    function addToWhitelist(address account) external onlyOwner {
        require(!whitelist[account], "Address already whitelisted");
        whitelist[account] = true;
        emit AddressWhitelisted(account);
    }

    // Function to remove an address from the whitelist
    function removeFromWhitelist(address account) external onlyOwner {
        require(whitelist[account], "Address not whitelisted");
        whitelist[account] = false;
        emit AddressRemovedFromWhitelist(account);
    }

    // Function to add an address to the blacklist
    function addToBlacklist(address account) external onlyOwner {
        require(!blacklist[account], "Address already blacklisted");
        blacklist[account] = true;
        emit AddressBlacklisted(account);
    }

    // Function to remove an address from the blacklist
    function removeFromBlacklist(address account) external onlyOwner {
        require(blacklist[account], "Address not blacklisted");
        blacklist[account] = false;
        emit AddressRemovedFromBlacklist(account);
    }

    // Function to check if an address is whitelisted
    function isWhitelisted(address account) external view returns (bool) {
        return whitelist[account];
    }

    // Function to check if an address is blacklisted
    function isBlacklisted(address account) external view returns (bool) {
        return blacklist[account];
    }

    // Override transfer functions to check whitelist/blacklist status
    function canTransfer(address from, address to) internal view {
        require(whitelist[from], "Sender not whitelisted");
        require(!blacklist[from], "Sender is blacklisted");
        require(whitelist[to], "Recipient not whitelisted");
        require(!blacklist[to], "Recipient is blacklisted");
    }
}
