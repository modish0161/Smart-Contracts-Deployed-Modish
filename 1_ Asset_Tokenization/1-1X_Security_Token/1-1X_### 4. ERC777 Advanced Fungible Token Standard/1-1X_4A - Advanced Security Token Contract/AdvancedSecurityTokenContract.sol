// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Advanced Security Token Contract
/// @notice ERC777 token with enhanced functionalities like minting, burning, and operator permissions.
contract AdvancedSecurityTokenContract is ERC777, Ownable, AccessControl, Pausable, ReentrancyGuard {
    // Define roles for access control
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // Event emitted when tokens are minted
    event TokensMinted(address indexed to, uint256 amount);

    // Event emitted when tokens are burned
    event TokensBurned(address indexed from, uint256 amount);

    /// @notice Constructor to initialize the ERC777 token
    /// @param name_ Token name
    /// @param symbol_ Token symbol
    /// @param defaultOperators_ List of default operators
    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_
    ) ERC777(name_, symbol_, defaultOperators_) {
        // Grant the contract deployer the default admin, minter, and burner roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
    }

    /// @notice Mint new tokens
    /// @param to Address to receive the minted tokens
    /// @param amount Amount of tokens to mint
    /// @dev Only accounts with the MINTER_ROLE can mint tokens
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) whenNotPaused nonReentrant {
        _mint(to, amount, "", "");
        emit TokensMinted(to, amount);
    }

    /// @notice Burn tokens
    /// @param amount Amount of tokens to burn
    /// @dev Only accounts with the BURNER_ROLE can burn tokens
    function burn(uint256 amount) public onlyRole(BURNER_ROLE) whenNotPaused nonReentrant {
        _burn(msg.sender, amount, "", "");
        emit TokensBurned(msg.sender, amount);
    }

    /// @notice Burn tokens from a specified address
    /// @param from Address from which tokens will be burned
    /// @param amount Amount of tokens to burn
    /// @dev Only accounts with the BURNER_ROLE can burn tokens from other accounts
    function burnFrom(address from, uint256 amount) public onlyRole(BURNER_ROLE) whenNotPaused nonReentrant {
        require(isOperatorFor(msg.sender, from), "Caller is not an operator for the account");
        _burn(from, amount, "", "");
        emit TokensBurned(from, amount);
    }

    /// @notice Pause the contract
    /// @dev Only accounts with the DEFAULT_ADMIN_ROLE can pause the contract
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract
    /// @dev Only accounts with the DEFAULT_ADMIN_ROLE can unpause the contract
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Override transfer function to include pausability
    /// @dev Prevent token transfers when the contract is paused
    function _beforeTokenTransfer(address operator, address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, amount);
    }

    /// @notice Assign operator role to an address
    /// @param operator Address to assign the operator role to
    /// @dev Only accounts with the DEFAULT_ADMIN_ROLE can assign the operator role
    function assignOperator(address operator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(OPERATOR_ROLE, operator);
    }

    /// @notice Revoke operator role from an address
    /// @param operator Address to revoke the operator role from
    /// @dev Only accounts with the DEFAULT_ADMIN_ROLE can revoke the operator role
    function revokeOperator(address operator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(OPERATOR_ROLE, operator);
    }

    /// @notice Check if an address has operator role
    /// @param operator Address to check for the operator role
    /// @return true if the address has the operator role, false otherwise
    function isOperator(address operator) public view returns (bool) {
        return hasRole(OPERATOR_ROLE, operator);
    }
}
