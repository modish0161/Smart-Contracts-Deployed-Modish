// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin libraries for ERC20 and security features
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// UtilityTokenContract based on ERC20 standard
contract UtilityTokenContract is ERC20, Ownable, AccessControl, Pausable, ReentrancyGuard {
    // Define roles for access control
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Constructor for initial contract setup
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_
    ) ERC20(name_, symbol_) {
        _mint(msg.sender, initialSupply_ * (10 ** uint256(decimals())));

        // Setup roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    // Function to mint new tokens
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) whenNotPaused {
        _mint(to, amount);
    }

    // Function to burn tokens
    function burn(uint256 amount) public whenNotPaused {
        _burn(msg.sender, amount);
    }

    // Function to burn tokens from a specific account
    function burnFrom(address account, uint256 amount) public whenNotPaused {
        uint256 decreasedAllowance = allowance(account, msg.sender) - amount;
        _approve(account, msg.sender, decreasedAllowance);
        _burn(account, amount);
    }

    // Pause the contract
    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    // Unpause the contract
    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // Override transfer function to include pausability
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
