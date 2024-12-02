// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC1404.sol";

/// @title Restricted Commodity Token Contract
/// @notice Represents ownership of physical commodities with restricted transfers based on investor qualifications or regulatory compliance.
contract RestrictedCommodityToken is ERC1404, Ownable, AccessControl, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Role definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant REGULATOR_ROLE = keccak256("REGULATOR_ROLE");

    // Approved investor set
    EnumerableSet.AddressSet private _approvedInvestors;

    // Regulatory restrictions mapping
    mapping(address => uint8) private _restrictionReasons;

    // Events
    event InvestorApproved(address indexed investor);
    event InvestorRevoked(address indexed investor);
    event TransferRestricted(address indexed from, address indexed to, uint256 value, uint8 reason);

    /// @dev Constructor to initialize the contract with name and symbol
    /// @param name Token name
    /// @param symbol Token symbol
    /// @param decimals Number of decimals the token will have
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC1404(name, symbol, decimals) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(REGULATOR_ROLE, msg.sender);
    }

    /// @notice Function to approve an investor
    /// @param investor Address of the investor
    /// @dev Only accounts with the ADMIN_ROLE can approve investors
    function approveInvestor(address investor) external onlyRole(ADMIN_ROLE) whenNotPaused {
        require(!_approvedInvestors.contains(investor), "Investor already approved");
        _approvedInvestors.add(investor);
        emit InvestorApproved(investor);
    }

    /// @notice Function to revoke an investor's approval
    /// @param investor Address of the investor
    /// @dev Only accounts with the ADMIN_ROLE can revoke investors
    function revokeInvestor(address investor) external onlyRole(ADMIN_ROLE) whenNotPaused {
        require(_approvedInvestors.contains(investor), "Investor not approved");
        _approvedInvestors.remove(investor);
        emit InvestorRevoked(investor);
    }

    /// @notice Function to check if an investor is approved
    /// @param investor Address of the investor
    /// @return Boolean indicating whether the investor is approved
    function isApprovedInvestor(address investor) public view returns (bool) {
        return _approvedInvestors.contains(investor);
    }

    /// @notice Function to restrict a transfer with a reason code
    /// @param from Address of the sender
    /// @param to Address of the receiver
    /// @param value Number of tokens to transfer
    /// @param reason Reason code for the restriction
    /// @dev Only accounts with the REGULATOR_ROLE can restrict transfers
    function restrictTransfer(address from, address to, uint256 value, uint8 reason) external onlyRole(REGULATOR_ROLE) whenNotPaused {
        require(_restrictionReasons[from] == 0, "Sender already restricted");
        _restrictionReasons[from] = reason;
        emit TransferRestricted(from, to, value, reason);
    }

    /// @notice Function to check the transfer restriction reason code
    /// @param investor Address of the investor
    /// @return Reason code for the restriction (0 if no restriction)
    function transferRestrictionReason(address investor) public view returns (uint8) {
        return _restrictionReasons[investor];
    }

    /// @notice Function to get the restriction message
    /// @param restrictionCode The restriction code to check
    /// @return The corresponding restriction message
    function messageForTransferRestriction(uint8 restrictionCode) external view override returns (string memory) {
        if (restrictionCode == 1) return "Sender not an approved investor";
        if (restrictionCode == 2) return "Receiver not an approved investor";
        if (restrictionCode == 3) return "Sender is restricted";
        return "No restrictions";
    }

    /// @notice Function to detect if a transfer will fail
    /// @param from Address of the sender
    /// @param to Address of the receiver
    /// @param value Number of tokens to transfer
    /// @return The restriction code (0 if no restriction)
    function detectTransferRestriction(address from, address to, uint256 value) public view override returns (uint8) {
        if (!_approvedInvestors.contains(from)) {
            return 1; // Sender not an approved investor
        }
        if (!_approvedInvestors.contains(to)) {
            return 2; // Receiver not an approved investor
        }
        if (_restrictionReasons[from] != 0) {
            return 3; // Sender is restricted
        }
        return 0; // No restrictions
    }

    /// @notice Function to mint new restricted commodity tokens
    /// @param to Address of the investor to mint tokens to
    /// @param amount Number of tokens to mint
    /// @dev Only accounts with the ADMIN_ROLE can mint new tokens
    function mintRestrictedTokens(address to, uint256 amount) external onlyRole(ADMIN_ROLE) nonReentrant whenNotPaused {
        require(_approvedInvestors.contains(to), "Investor is not approved");
        _mint(to, amount);
    }

    /// @notice Function to burn restricted commodity tokens
    /// @param from Address of the investor to burn tokens from
    /// @param amount Number of tokens to burn
    /// @dev Only accounts with the ADMIN_ROLE can burn tokens
    function burnRestrictedTokens(address from, uint256 amount) external onlyRole(ADMIN_ROLE) nonReentrant whenNotPaused {
        _burn(from, amount);
    }

    /// @notice Function to pause the contract
    /// @dev Only accounts with the ADMIN_ROLE can pause the contract
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Function to unpause the contract
    /// @dev Only accounts with the ADMIN_ROLE can unpause the contract
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @dev Override required by Solidity for multiple inheritance
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1404, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
