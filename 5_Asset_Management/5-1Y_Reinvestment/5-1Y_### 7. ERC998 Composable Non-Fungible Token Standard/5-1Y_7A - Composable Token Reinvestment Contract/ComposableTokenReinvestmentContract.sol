// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998TopDown.sol";

contract ComposableTokenReinvestmentContract is Ownable, ReentrancyGuard, ERC998TopDown {
    using SafeMath for uint256;

    struct ChildAsset {
        address assetAddress;
        uint256 tokenId;
        uint256 percentage;
    }

    mapping(uint256 => ChildAsset[]) public tokenAssets; // Maps parent token to its child assets
    IERC20 public profitToken; // Token in which profits are paid
    IERC20 public assetToken;  // Token used for reinvestment

    event Reinvested(uint256 indexed parentTokenId, uint256 amount, address assetAddress, uint256 tokenId);
    event ChildAssetAdded(uint256 indexed parentTokenId, address assetAddress, uint256 tokenId, uint256 percentage);

    constructor(string memory name, string memory symbol, address _profitToken, address _assetToken) ERC721(name, symbol) {
        require(_profitToken != address(0), "Invalid profit token address");
        require(_assetToken != address(0), "Invalid asset token address");
        profitToken = IERC20(_profitToken);
        assetToken = IERC20(_assetToken);
    }

    // Function to add child assets to a parent token
    function addChildAsset(uint256 parentTokenId, address assetAddress, uint256 tokenId, uint256 percentage) external onlyOwner {
        require(ownerOf(parentTokenId) != address(0), "Parent token does not exist");
        require(assetAddress != address(0), "Invalid asset address");
        require(percentage > 0 && percentage <= 100, "Invalid percentage");

        tokenAssets[parentTokenId].push(ChildAsset({
            assetAddress: assetAddress,
            tokenId: tokenId,
            percentage: percentage
        }));

        emit ChildAssetAdded(parentTokenId, assetAddress, tokenId, percentage);
    }

    // Function to reinvest profits into the underlying assets
    function reinvest(uint256 parentTokenId) external nonReentrant {
        require(ownerOf(parentTokenId) != address(0), "Parent token does not exist");

        uint256 profitAmount = profitToken.balanceOf(address(this));
        require(profitAmount > 0, "No profits to reinvest");

        // Reinvest into each child asset according to its percentage
        for (uint256 i = 0; i < tokenAssets[parentTokenId].length; i++) {
            ChildAsset memory child = tokenAssets[parentTokenId][i];
            uint256 reinvestAmount = profitAmount.mul(child.percentage).div(100);

            // Transfer reinvest amount to the child asset
            profitToken.transfer(child.assetAddress, reinvestAmount);
            emit Reinvested(parentTokenId, reinvestAmount, child.assetAddress, child.tokenId);
        }
    }

    // Function to deposit profits into the contract
    function depositProfits(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(profitToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }

    // Function to create a new parent composable token
    function mintComposableToken(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }

    // Function to withdraw profits from the contract
    function withdrawProfits(uint256 amount) external onlyOwner nonReentrant {
        require(amount <= profitToken.balanceOf(address(this)), "Insufficient balance");
        profitToken.transfer(owner(), amount);
    }

    // Function to set profit and asset tokens
    function setTokens(address _profitToken, address _assetToken) external onlyOwner {
        require(_profitToken != address(0), "Invalid profit token address");
        require(_assetToken != address(0), "Invalid asset token address");
        profitToken = IERC20(_profitToken);
        assetToken = IERC20(_assetToken);
    }
}
