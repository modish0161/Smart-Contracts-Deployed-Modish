// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998TopDown.sol";

contract MultiLayerReinvestmentContract is Ownable, ReentrancyGuard, ERC998TopDown {
    using SafeMath for uint256;

    struct LayerAsset {
        address assetAddress;
        uint256 tokenId;
        uint256 percentage; // Percentage of reinvestment to this asset
    }

    // Mapping from parent token ID to its layer assets
    mapping(uint256 => LayerAsset[]) public layerAssets;
    IERC20 public profitToken; // Token in which profits are distributed
    IERC20 public reinvestToken; // Token used for reinvestment

    event ProfitReinvested(uint256 indexed parentTokenId, uint256 amount, address assetAddress, uint256 tokenId);
    event LayerAssetAdded(uint256 indexed parentTokenId, address assetAddress, uint256 tokenId, uint256 percentage);

    constructor(
        string memory name,
        string memory symbol,
        address _profitToken,
        address _reinvestToken
    ) ERC721(name, symbol) {
        require(_profitToken != address(0), "Invalid profit token address");
        require(_reinvestToken != address(0), "Invalid reinvest token address");
        profitToken = IERC20(_profitToken);
        reinvestToken = IERC20(_reinvestToken);
    }

    // Function to add a layer asset to a parent token
    function addLayerAsset(
        uint256 parentTokenId,
        address assetAddress,
        uint256 tokenId,
        uint256 percentage
    ) external onlyOwner {
        require(ownerOf(parentTokenId) != address(0), "Parent token does not exist");
        require(assetAddress != address(0), "Invalid asset address");
        require(percentage > 0 && percentage <= 100, "Invalid percentage");

        layerAssets[parentTokenId].push(
            LayerAsset({
                assetAddress: assetAddress,
                tokenId: tokenId,
                percentage: percentage
            })
        );

        emit LayerAssetAdded(parentTokenId, assetAddress, tokenId, percentage);
    }

    // Function to reinvest profits into the parent token and its underlying assets
    function reinvest(uint256 parentTokenId) external nonReentrant {
        require(ownerOf(parentTokenId) != address(0), "Parent token does not exist");

        uint256 profitAmount = profitToken.balanceOf(address(this));
        require(profitAmount > 0, "No profits to reinvest");

        // Reinvest into parent token and its layer assets based on the specified percentages
        for (uint256 i = 0; i < layerAssets[parentTokenId].length; i++) {
            LayerAsset memory layer = layerAssets[parentTokenId][i];
            uint256 reinvestAmount = profitAmount.mul(layer.percentage).div(100);

            // Transfer reinvest amount to the layer asset
            profitToken.transfer(layer.assetAddress, reinvestAmount);
            emit ProfitReinvested(parentTokenId, reinvestAmount, layer.assetAddress, layer.tokenId);
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

    // Function to set profit and reinvest tokens
    function setTokens(address _profitToken, address _reinvestToken) external onlyOwner {
        require(_profitToken != address(0), "Invalid profit token address");
        require(_reinvestToken != address(0), "Invalid reinvest token address");
        profitToken = IERC20(_profitToken);
        reinvestToken = IERC20(_reinvestToken);
    }
}
