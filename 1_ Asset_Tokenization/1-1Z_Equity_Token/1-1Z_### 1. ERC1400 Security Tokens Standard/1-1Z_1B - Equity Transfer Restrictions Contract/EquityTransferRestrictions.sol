// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

/// @title Equity Transfer Restrictions Contract
/// @notice This contract enforces transfer restrictions on equity tokens (ERC1400) for regulatory compliance.
contract EquityTransferRestrictions is AccessControl, Pausable, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant REGULATOR_ROLE = keccak256("REGULATOR_ROLE");

    IERC1400 public equityToken;

    mapping(address => bool) private whitelistedInvestors;
    mapping(address => bool) private blacklistedInvestors;

    event InvestorWhitelisted(address indexed investor);
    event InvestorBlacklisted(address indexed investor);
    event InvestorRemovedFromWhitelist(address indexed investor);
    event InvestorRemovedFromBlacklist(address indexed investor);

    /// @notice Constructor to initialize the contract
    /// @param _equityToken Address of the ERC1400 token representing the equity
    constructor(address _equityToken) {
        require(_equityToken != address(0), "Invalid token address");

        equityToken = IERC1400(_equityToken);

        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(REGULATOR_ROLE, msg.sender);
    }

    /// @notice Whitelist an investor
    /// @param investor Address of the investor to whitelist
    function whitelistInvestor(address investor) external onlyRole(REGULATOR_ROLE) {
        require(investor != address(0), "Invalid investor address");
        require(!blacklistedInvestors[investor], "Investor is blacklisted");

        whitelistedInvestors[investor] = true;
        emit InvestorWhitelisted(investor);
    }

    /// @notice Blacklist an investor
    /// @param investor Address of the investor to blacklist
    function blacklistInvestor(address investor) external onlyRole(REGULATOR_ROLE) {
        require(investor != address(0), "Invalid investor address");
        require(!whitelistedInvestors[investor], "Investor is whitelisted");

        blacklistedInvestors[investor] = true;
        emit InvestorBlacklisted(investor);
    }

    /// @notice Remove an investor from the whitelist
    /// @param investor Address of the investor to remove from the whitelist
    function removeInvestorFromWhitelist(address investor) external onlyRole(REGULATOR_ROLE) {
        require(investor != address(0), "Invalid investor address");

        whitelistedInvestors[investor] = false;
        emit InvestorRemovedFromWhitelist(investor);
    }

    /// @notice Remove an investor from the blacklist
    /// @param investor Address of the investor to remove from the blacklist
    function removeInvestorFromBlacklist(address investor) external onlyRole(REGULATOR_ROLE) {
        require(investor != address(0), "Invalid investor address");

        blacklistedInvestors[investor] = false;
        emit InvestorRemovedFromBlacklist(investor);
    }

    /// @notice Check if an investor is whitelisted
    /// @param investor Address of the investor to check
    /// @return bool True if the investor is whitelisted, false otherwise
    function isWhitelisted(address investor) external view returns (bool) {
        return whitelistedInvestors[investor];
    }

    /// @notice Check if an investor is blacklisted
    /// @param investor Address of the investor to check
    /// @return bool True if the investor is blacklisted, false otherwise
    function isBlacklisted(address investor) external view returns (bool) {
        return blacklistedInvestors[investor];
    }

    /// @notice Transfer tokens with compliance check
    /// @param from Address of the sender
    /// @param to Address of the recipient
    /// @param value Amount of tokens to transfer
    function transferWithCompliance(
        address from,
        address to,
        uint256 value
    ) external whenNotPaused nonReentrant {
        require(whitelistedInvestors[from], "Sender is not whitelisted");
        require(whitelistedInvestors[to], "Recipient is not whitelisted");
        require(!blacklistedInvestors[from], "Sender is blacklisted");
        require(!blacklistedInvestors[to], "Recipient is blacklisted");

        equityToken.transferFrom(from, to, value);
    }

    /// @notice Pause the contract
    /// @dev Only callable by the contract admin
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract
    /// @dev Only callable by the contract admin
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Add new admin
    /// @dev Only callable by an existing admin
    /// @param newAdmin Address of the new admin
    function addAdmin(address newAdmin) external onlyRole(ADMIN_ROLE) {
        grantRole(ADMIN_ROLE, newAdmin);
    }

    /// @notice Remove an admin
    /// @dev Only callable by an existing admin
    /// @param admin Address of the admin to remove
    function removeAdmin(address admin) external onlyRole(ADMIN_ROLE) {
        revokeRole(ADMIN_ROLE, admin);
    }

    /// @notice Add new regulator
    /// @dev Only callable by an admin
    /// @param newRegulator Address of the new regulator
    function addRegulator(address newRegulator) external onlyRole(ADMIN_ROLE) {
        grantRole(REGULATOR_ROLE, newRegulator);
    }

    /// @notice Remove a regulator
    /// @dev Only callable by an admin
    /// @param regulator Address of the regulator to remove
    function removeRegulator(address regulator) external onlyRole(ADMIN_ROLE) {
        revokeRole(REGULATOR_ROLE, regulator);
    }
}
