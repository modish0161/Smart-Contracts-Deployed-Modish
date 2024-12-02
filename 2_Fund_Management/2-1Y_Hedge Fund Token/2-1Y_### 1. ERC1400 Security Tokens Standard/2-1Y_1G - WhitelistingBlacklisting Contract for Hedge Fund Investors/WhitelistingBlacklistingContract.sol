// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

contract WhitelistingBlacklistingContract is Ownable, ReentrancyGuard {
    IERC1400 public token; // Reference to the ERC1400 token contract

    mapping(address => bool) public whitelist; // Track whitelisted addresses
    mapping(address => bool) public blacklist; // Track blacklisted addresses

    event Whitelisted(address indexed investor);
    event Blacklisted(address indexed investor);
    event RemovedFromWhitelist(address indexed investor);
    event RemovedFromBlacklist(address indexed investor);

    constructor(address _tokenAddress) {
        token = IERC1400(_tokenAddress);
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Not an authorized investor");
        _;
    }

    modifier notBlacklisted() {
        require(!blacklist[msg.sender], "Investor is blacklisted");
        _;
    }

    function addToWhitelist(address _investor) external onlyOwner {
        require(!whitelist[_investor], "Investor is already whitelisted");
        whitelist[_investor] = true;
        emit Whitelisted(_investor);
    }

    function removeFromWhitelist(address _investor) external onlyOwner {
        require(whitelist[_investor], "Investor is not whitelisted");
        whitelist[_investor] = false;
        emit RemovedFromWhitelist(_investor);
    }

    function addToBlacklist(address _investor) external onlyOwner {
        require(!blacklist[_investor], "Investor is already blacklisted");
        blacklist[_investor] = true;
        emit Blacklisted(_investor);
    }

    function removeFromBlacklist(address _investor) external onlyOwner {
        require(blacklist[_investor], "Investor is not blacklisted");
        blacklist[_investor] = false;
        emit RemovedFromBlacklist(_investor);
    }

    function transferToken(address _to, uint256 _value) external onlyWhitelisted notBlacklisted nonReentrant {
        require(_to != address(0), "Invalid recipient address");
        require(token.balanceOf(msg.sender) >= _value, "Insufficient balance");

        // Transfer logic (customize as needed based on your ERC1400 implementation)
        token.transferFrom(msg.sender, _to, _value);
    }
}
