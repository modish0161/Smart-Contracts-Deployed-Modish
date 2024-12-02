// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract WhitelistBasedKYCAMLContract is ERC20, Ownable, Pausable, ReentrancyGuard, AccessControl {
    
    // Role for Whitelist Managers
    bytes32 public constant WHITELIST_MANAGER_ROLE = keccak256("WHITELIST_MANAGER_ROLE");

    // Mapping to track whitelist status of users
    mapping(address => bool) private _whitelisted;

    // Events for whitelist updates
    event Whitelisted(address indexed user);
    event RemovedFromWhitelist(address indexed user);

    // Modifier to restrict actions to whitelisted addresses only
    modifier onlyWhitelisted(address _user) {
        require(_whitelisted[_user], "User is not whitelisted");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _whitelistManager
    ) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(WHITELIST_MANAGER_ROLE, _whitelistManager);
    }

    /**
     * @dev Adds a user to the whitelist
     * @param user Address to be added to the whitelist
     */
    function addWhitelist(address user) external onlyRole(WHITELIST_MANAGER_ROLE) {
        _whitelisted[user] = true;
        emit Whitelisted(user);
    }

    /**
     * @dev Removes a user from the whitelist
     * @param user Address to be removed from the whitelist
     */
    function removeWhitelist(address user) external onlyRole(WHITELIST_MANAGER_ROLE) {
        _whitelisted[user] = false;
        emit RemovedFromWhitelist(user);
    }

    /**
     * @dev Checks if a user is whitelisted
     * @param user Address to check whitelist status
     * @return true if the user is whitelisted, false otherwise
     */
    function isWhitelisted(address user) external view returns (bool) {
        return _whitelisted[user];
    }

    /**
     * @dev Overrides the ERC20 transfer function to include whitelist check
     * @param recipient Address of the recipient
     * @param amount Amount of tokens to transfer
     */
    function transfer(address recipient, uint256 amount) public override onlyWhitelisted(msg.sender) onlyWhitelisted(recipient) returns (bool) {
        return super.transfer(recipient, amount);
    }

    /**
     * @dev Overrides the ERC20 transferFrom function to include whitelist check
     * @param sender Address of the sender
     * @param recipient Address of the recipient
     * @param amount Amount of tokens to transfer
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override onlyWhitelisted(sender) onlyWhitelisted(recipient) returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    /**
     * @dev Mint function with whitelist and onlyOwner checks
     * @param account Address to receive the tokens
     * @param amount Amount of tokens to mint
     */
    function mint(address account, uint256 amount) external onlyOwner onlyWhitelisted(account) {
        _mint(account, amount);
    }

    /**
     * @dev Function to pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Function to unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Burn function for the owner to burn tokens
     * @param amount Amount of tokens to burn
     */
    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Internal function to include pause checks on token transfers
     * @param from Address of the sender
     * @param to Address of the recipient
     * @param amount Amount of tokens to transfer
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
