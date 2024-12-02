// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title Equity Vault Contract
/// @notice This contract tokenizes a vault that holds equity in multiple companies, allowing investors to buy and sell shares in a diversified basket of equities.
contract EquityVaultContract is ERC4626, ERC20Permit, Ownable, ReentrancyGuard, Pausable {
    // Mapping to store the price oracles for each equity token in the vault
    mapping(address => AggregatorV3Interface) public priceOracles;

    // Event emitted when a new equity token is added to the vault
    event EquityTokenAdded(address indexed token, address indexed oracle);

    // Event emitted when equity tokens are removed from the vault
    event EquityTokenRemoved(address indexed token);

    /// @notice Constructor to initialize the vault contract
    /// @param asset The underlying asset (equity token) of the vault
    /// @param name The name of the vault token
    /// @param symbol The symbol of the vault token
    constructor(
        IERC20 asset,
        string memory name,
        string memory symbol
    ) ERC4626(asset) ERC20(name, symbol) ERC20Permit(name) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Function to add a new equity token and its price oracle to the vault
    /// @param token The address of the equity token
    /// @param oracle The address of the Chainlink price oracle for the equity token
    function addEquityToken(address token, address oracle) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(oracle != address(0), "Invalid oracle address");
        priceOracles[token] = AggregatorV3Interface(oracle);
        emit EquityTokenAdded(token, oracle);
    }

    /// @notice Function to remove an equity token from the vault
    /// @param token The address of the equity token to be removed
    function removeEquityToken(address token) external onlyOwner {
        require(priceOracles[token] != AggregatorV3Interface(address(0)), "Token not in vault");
        delete priceOracles[token];
        emit EquityTokenRemoved(token);
    }

    /// @notice Function to get the current price of an equity token from its oracle
    /// @param token The address of the equity token
    /// @return The latest price of the equity token
    function getEquityTokenPrice(address token) public view returns (uint256) {
        require(priceOracles[token] != AggregatorV3Interface(address(0)), "Token not in vault");
        (, int256 price, , , ) = priceOracles[token].latestRoundData();
        return uint256(price);
    }

    /// @notice Function to deposit equity tokens into the vault and receive vault shares
    /// @param assets The amount of equity tokens to deposit
    /// @param receiver The address that will receive the vault shares
    /// @return The amount of vault shares minted
    function deposit(uint256 assets, address receiver) public override nonReentrant whenNotPaused returns (uint256) {
        return super.deposit(assets, receiver);
    }

    /// @notice Function to redeem vault shares for underlying equity tokens
    /// @param shares The amount of vault shares to redeem
    /// @param receiver The address that will receive the underlying equity tokens
    /// @param owner The address of the owner of the vault shares
    /// @return The amount of underlying assets redeemed
    function redeem(uint256 shares, address receiver, address owner) public override nonReentrant whenNotPaused returns (uint256) {
        return super.redeem(shares, receiver, owner);
    }

    /// @notice Function to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Function to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Fallback function to receive Ether
    receive() external payable {}

    /// @notice Override required by Solidity for ERC4626 _beforeTokenTransfer hook
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, amount);
    }
}
