// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Basic Equity Token Contract
/// @notice This contract issues fungible equity tokens that represent shares in a company. Each ERC20 token represents a fraction of ownership.
contract BasicEquityToken is ERC20, Ownable, Pausable, ReentrancyGuard {
    // Initial token distribution
    uint256 public initialSupply = 1_000_000 * (10 ** decimals()); // 1 million tokens

    // Mapping for token holder lockup periods
    mapping(address => uint256) private lockupExpiry;

    // Events
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    event LockupPeriodSet(address indexed holder, uint256 lockupExpiry);

    /// @notice Constructor to initialize the equity token
    /// @param name Name of the equity token
    /// @param symbol Symbol of the equity token
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply); // Mint initial supply to the contract deployer
    }

    /// @notice Mint new tokens to a specified address
    /// @param to Address to mint tokens to
    /// @param amount Amount of tokens to mint
    function mint(address to, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount should be greater than zero");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /// @notice Burn tokens from a specified address
    /// @param amount Amount of tokens to burn
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    /// @notice Pause all token transfers (onlyOwner)
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause all token transfers (onlyOwner)
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Set lockup period for a specific token holder
    /// @param holder Address of the token holder
    /// @param lockupDuration Duration of the lockup period in seconds
    function setLockupPeriod(address holder, uint256 lockupDuration) external onlyOwner {
        lockupExpiry[holder] = block.timestamp + lockupDuration;
        emit LockupPeriodSet(holder, lockupExpiry[holder]);
    }

    /// @notice Check if an address is locked up
    /// @param account Address to check
    /// @return Whether the address is locked up or not
    function isLockedUp(address account) public view returns (bool) {
        return block.timestamp < lockupExpiry[account];
    }

    /// @notice Override _beforeTokenTransfer to include lockup and pause checks
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!paused(), "ERC20Pausable: token transfer while paused");
        require(!isLockedUp(from), "Token transfer is locked up");
        super._beforeTokenTransfer(from, to, amount);
    }

    /// @notice Function to handle emergency token withdrawals in case of a failed token sale or emergency
    /// @param token Address of the ERC20 token to withdraw
    /// @param recipient Address to receive the withdrawn tokens
    /// @param amount Amount of tokens to withdraw
    function emergencyTokenWithdrawal(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external onlyOwner nonReentrant {
        require(amount > 0, "Amount should be greater than zero");
        require(token.transfer(recipient, amount), "Token transfer failed");
    }
}
