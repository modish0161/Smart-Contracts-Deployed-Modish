// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1400/ERC1400.sol";

/// @title Transfer Restrictions Contract for Real Assets
/// @notice Tokenizes real assets with built-in transfer restrictions to comply with regulatory requirements.
/// Only compliant and verified entities are allowed to trade or hold these tokens.
contract TransferRestrictionsRealAssets is ERC1400, Ownable, AccessControl, ReentrancyGuard, Pausable {
    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant REGULATOR_ROLE = keccak256("REGULATOR_ROLE");
    
    // KYC approved whitelist mapping
    mapping(address => bool) private _kycApproved;
    
    // AML/Compliance flagged mapping
    mapping(address => bool) private _amlFlagged;

    // Events
    event KYCApproved(address indexed investor);
    event KYCRevoked(address indexed investor);
    event AMLFlagged(address indexed investor, string reason);
    event AMLCleared(address indexed investor);

    /// @dev Constructor to set up the initial values and roles
    /// @param name Name of the security token (e.g., "Real Estate Security Token")
    /// @param symbol Symbol of the security token (e.g., "REST")
    /// @param partitions Array of partition names for ERC1400 compliance
    constructor(
        string memory name,
        string memory symbol,
        bytes32[] memory partitions
    ) ERC1400(name, symbol, partitions) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(ISSUER_ROLE, msg.sender);
        _setupRole(REGULATOR_ROLE, msg.sender);
    }

    /// @notice Function to approve an investor's KYC status
    /// @param investor Address of the investor
    /// @dev Only accounts with the ADMIN_ROLE can approve KYC
    function approveKYC(address investor) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _kycApproved[investor] = true;
        emit KYCApproved(investor);
    }

    /// @notice Function to revoke an investor's KYC status
    /// @param investor Address of the investor
    /// @dev Only accounts with the ADMIN_ROLE can revoke KYC
    function revokeKYC(address investor) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _kycApproved[investor] = false;
        emit KYCRevoked(investor);
    }

    /// @notice Function to check if an investor is KYC approved
    /// @param investor Address of the investor
    /// @return Boolean indicating whether the investor is KYC approved
    function isKYCApproved(address investor) public view returns (bool) {
        return _kycApproved[investor];
    }

    /// @notice Function to flag an investor for AML concerns
    /// @param investor Address of the investor
    /// @param reason Reason for AML flagging
    /// @dev Only accounts with the REGULATOR_ROLE can flag AML concerns
    function flagAML(address investor, string memory reason) external onlyRole(REGULATOR_ROLE) whenNotPaused {
        _amlFlagged[investor] = true;
        emit AMLFlagged(investor, reason);
    }

    /// @notice Function to clear an investor's AML flag
    /// @param investor Address of the investor
    /// @dev Only accounts with the REGULATOR_ROLE can clear AML flags
    function clearAML(address investor) external onlyRole(REGULATOR_ROLE) whenNotPaused {
        _amlFlagged[investor] = false;
        emit AMLCleared(investor);
    }

    /// @notice Function to check if an investor is AML flagged
    /// @param investor Address of the investor
    /// @return Boolean indicating whether the investor is AML flagged
    function isAMLFlagged(address investor) public view returns (bool) {
        return _amlFlagged[investor];
    }

    /// @notice Function to transfer tokens with compliance and KYC checks
    /// @param from Address of the sender
    /// @param to Address of the receiver
    /// @param amount Number of tokens to transfer
    /// @param data Additional data for compliance checks
    /// @dev Overrides ERC1400 transfer function to include KYC and compliance checks
    function transferFrom(
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) public override whenNotPaused returns (bool) {
        require(_kycApproved[from], "Sender is not KYC approved");
        require(_kycApproved[to], "Receiver is not KYC approved");
        require(!_amlFlagged[from], "Sender is AML flagged");
        require(!_amlFlagged[to], "Receiver is AML flagged");
        return super.transferFrom(from, to, amount, data);
    }

    /// @notice Function to mint new security tokens to an investor
    /// @param to Address of the investor to mint tokens to
    /// @param amount Number of tokens to mint
    /// @param data Additional data for compliance checks
    /// @dev Only accounts with the ISSUER_ROLE can mint new tokens
    function issueSecurityTokens(
        address to,
        uint256 amount,
        bytes memory data
    ) external onlyRole(ISSUER_ROLE) nonReentrant whenNotPaused {
        require(_kycApproved[to], "Investor is not KYC approved");
        require(!_amlFlagged[to], "Investor is AML flagged");
        _mint(to, amount, data);
    }

    /// @notice Function to redeem security tokens from an investor
    /// @param from Address of the investor to redeem tokens from
    /// @param amount Number of tokens to redeem
    /// @param data Additional data for compliance checks
    /// @dev Only accounts with the ISSUER_ROLE can redeem tokens
    function redeemSecurityTokens(
        address from,
        uint256 amount,
        bytes memory data
    ) external onlyRole(ISSUER_ROLE) nonReentrant whenNotPaused {
        _burn(from, amount, data);
    }

    /// @notice Function to pause the contract
    /// @dev Only accounts with ADMIN_ROLE can pause the contract
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Function to unpause the contract
    /// @dev Only accounts with ADMIN_ROLE can unpause the contract
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @dev Override required by Solidity for multiple inheritance
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1400, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
