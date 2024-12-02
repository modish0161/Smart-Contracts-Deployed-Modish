// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";

contract MutualFundVault is ERC4626, Ownable, ReentrancyGuard {
    IERC20 public immutable asset; // The underlying asset token (e.g., stablecoin, bond token, etc.)

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);

    constructor(IERC20 _asset, string memory name, string memory symbol) ERC4626(_asset) ERC20(name, symbol) {
        asset = _asset;
    }

    /**
     * @dev Allows investors to deposit assets into the vault in exchange for shares.
     * @param assets The amount of assets to deposit.
     * @param receiver The address that will receive the shares.
     * @return shares The number of shares minted for the assets.
     */
    function deposit(uint256 assets, address receiver) public override nonReentrant returns (uint256 shares) {
        require(assets > 0, "Deposit must be greater than zero");
        shares = previewDeposit(assets);
        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
        _transferAssetFrom(msg.sender, address(this), assets);
        return shares;
    }

    /**
     * @dev Allows investors to withdraw assets from the vault by redeeming their shares.
     * @param shares The number of shares to redeem.
     * @param receiver The address that will receive the assets.
     * @param owner The address that owns the shares.
     * @return assets The number of assets withdrawn.
     */
    function withdraw(uint256 shares, address receiver, address owner) public override nonReentrant returns (uint256 assets) {
        require(shares > 0, "Withdraw must be greater than zero");
        require(balanceOf(owner) >= shares, "Insufficient shares");
        assets = previewWithdraw(shares);
        _burn(owner, shares);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
        _transferAsset(receiver, assets);
        return assets;
    }

    /**
     * @dev Preview the number of shares that will be minted for the given assets.
     * @param assets The amount of assets to be deposited.
     * @return shares The number of shares that will be minted.
     */
    function previewDeposit(uint256 assets) public view override returns (uint256 shares) {
        return convertToShares(assets);
    }

    /**
     * @dev Preview the amount of assets that will be withdrawn for the given shares.
     * @param shares The number of shares to be redeemed.
     * @return assets The amount of assets that will be withdrawn.
     */
    function previewWithdraw(uint256 shares) public view override returns (uint256 assets) {
        return convertToAssets(shares);
    }

    /**
     * @dev Internal function to transfer assets from the user to the vault.
     * @param from The address to transfer assets from.
     * @param to The address to transfer assets to.
     * @param amount The amount of assets to transfer.
     */
    function _transferAssetFrom(address from, address to, uint256 amount) internal {
        require(asset.transferFrom(from, to, amount), "Asset transfer failed");
    }

    /**
     * @dev Internal function to transfer assets from the vault to the user.
     * @param to The address to transfer assets to.
     * @param amount The amount of assets to transfer.
     */
    function _transferAsset(address to, uint256 amount) internal {
        require(asset.transfer(to, amount), "Asset transfer failed");
    }

    /**
     * @dev Emergency function to pause the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Emergency function to unpause the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Function to recover any tokens accidentally sent to the contract.
     * @param token The address of the token to recover.
     * @param to The address to send the tokens to.
     * @param amount The amount of tokens to recover.
     */
    function recoverERC20(IERC20 token, address to, uint256 amount) external onlyOwner {
        require(token != asset, "Cannot recover asset token");
        require(token.transfer(to, amount), "Token transfer failed");
    }
}
