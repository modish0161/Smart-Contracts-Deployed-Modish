// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title Investor Accreditation Contract (ERC1404)
/// @notice This contract represents equity tokens with built-in accreditation verification for investors.
contract InvestorAccreditationContract is ERC20, AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    // Mapping to store the accreditation status for each address
    mapping(address => bool) private accreditedInvestors;
    mapping(address => bool) private blacklistedInvestors;

    // Events for accreditation and compliance actions
    event InvestorAccredited(address indexed account, bool status);
    event InvestorBlacklisted(address indexed account, bool status);
    event TransferBlocked(address indexed from, address indexed to, uint256 value, string reason);

    /// @notice Constructor to initialize the ERC20 token with details
    /// @param name Name of the equity token
    /// @param symbol Symbol of the equity token
    /// @param initialSupply Initial supply of the tokens to be minted to the deployer
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_ROLE, msg.sender);

        _mint(msg.sender, initialSupply);
    }

    /// @notice Add or remove an address from the accredited investor list
    /// @param account Address to be accredited or removed from the accreditation list
    /// @param status True to accredit, false to remove
    function setAccreditedInvestor(address account, bool status) external onlyRole(COMPLIANCE_ROLE) {
        accreditedInvestors[account] = status;
        emit InvestorAccredited(account, status);
    }

    /// @notice Add or remove an address from the blacklist
    /// @param account Address to be blacklisted or removed from the blacklist
    /// @param status True to blacklist, false to remove
    function setBlacklistedInvestor(address account, bool status) external onlyRole(COMPLIANCE_ROLE) {
        blacklistedInvestors[account] = status;
        emit InvestorBlacklisted(account, status);
    }

    /// @notice Checks if an address is accredited
    /// @param account Address to be checked
    /// @return Boolean indicating whether the address is accredited
    function isAccreditedInvestor(address account) external view returns (bool) {
        return accreditedInvestors[account];
    }

    /// @notice Checks if an address is blacklisted
    /// @param account Address to be checked
    /// @return Boolean indicating whether the address is blacklisted
    function isBlacklistedInvestor(address account) external view returns (bool) {
        return blacklistedInvestors[account];
    }

    /// @notice Override transfer function to include accreditation and compliance checks
    /// @param recipient Address to receive the tokens
    /// @param amount Amount of tokens to be transferred
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(accreditedInvestors[msg.sender], "InvestorAccreditationContract: Sender not accredited");
        require(accreditedInvestors[recipient], "InvestorAccreditationContract: Recipient not accredited");
        require(!blacklistedInvestors[msg.sender], "InvestorAccreditationContract: Sender blacklisted");
        require(!blacklistedInvestors[recipient], "InvestorAccreditationContract: Recipient blacklisted");

        return super.transfer(recipient, amount);
    }

    /// @notice Override transferFrom function to include accreditation and compliance checks
    /// @param sender Address sending the tokens
    /// @param recipient Address receiving the tokens
    /// @param amount Amount of tokens to be transferred
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(accreditedInvestors[sender], "InvestorAccreditationContract: Sender not accredited");
        require(accreditedInvestors[recipient], "InvestorAccreditationContract: Recipient not accredited");
        require(!blacklistedInvestors[sender], "InvestorAccreditationContract: Sender blacklisted");
        require(!blacklistedInvestors[recipient], "InvestorAccreditationContract: Recipient blacklisted");

        return super.transferFrom(sender, recipient, amount);
    }

    /// @notice Pauses the contract (only by admin)
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses the contract (only by admin)
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Mint new tokens to a specified address (only by admin)
    /// @param account Address to receive the new tokens
    /// @param amount Amount of tokens to be minted
    function mint(address account, uint256 amount) external onlyRole(ADMIN_ROLE) {
        _mint(account, amount);
    }

    /// @notice Burn tokens from a specified address (only by admin)
    /// @param account Address to burn the tokens from
    /// @param amount Amount of tokens to be burned
    function burn(address account, uint256 amount) external onlyRole(ADMIN_ROLE) {
        _burn(account, amount);
    }

    /// @notice Block token transfers if the contract is paused or sender/recipient not accredited
    /// @param from Address sending the tokens
    /// @param to Address receiving the tokens
    /// @param amount Amount of tokens being transferred
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        if (!accreditedInvestors[from] || !accreditedInvestors[to]) {
            emit TransferBlocked(from, to, amount, "Transfer not allowed: Investor not accredited");
            revert("InvestorAccreditationContract: Transfer not allowed: Investor not accredited");
        }

        if (blacklistedInvestors[from] || blacklistedInvestors[to]) {
            emit TransferBlocked(from, to, amount, "Transfer not allowed: Blacklisted");
            revert("InvestorAccreditationContract: Transfer not allowed: Blacklisted");
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}
