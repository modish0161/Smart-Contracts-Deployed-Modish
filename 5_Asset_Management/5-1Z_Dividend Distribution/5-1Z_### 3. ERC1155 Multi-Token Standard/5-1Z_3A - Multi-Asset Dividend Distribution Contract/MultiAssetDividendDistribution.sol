// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MultiAssetDividendDistribution is Ownable, ReentrancyGuard {
    // ERC1155 token contract
    ERC1155 public assetToken;

    // Mapping to track dividends per token ID
    mapping(uint256 => uint256) public dividendsPerToken;

    // Mapping to track claimed dividends for each holder and token ID
    mapping(address => mapping(uint256 => uint256)) public claimedDividends;

    // Event emitted when dividends are distributed
    event DividendsDistributed(uint256 indexed tokenId, uint256 amount);

    // Event emitted when dividends are claimed
    event DividendsClaimed(address indexed holder, uint256 indexed tokenId, uint256 amount);

    constructor(address _assetToken) {
        require(_assetToken != address(0), "Invalid asset token address");
        assetToken = ERC1155(_assetToken);
    }

    // Function to distribute dividends to holders of a specific token ID
    function distributeDividends(uint256 tokenId, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        
        // Transfer the dividend tokens to the contract
        IERC20(dividendsPerToken[tokenId]).transferFrom(msg.sender, address(this), amount);
        
        dividendsPerToken[tokenId] += amount;
        emit DividendsDistributed(tokenId, amount);
    }

    // Function to claim dividends for a specific token ID
    function claimDividends(uint256 tokenId) external nonReentrant {
        uint256 holderBalance = assetToken.balanceOf(msg.sender, tokenId);
        require(holderBalance > 0, "No tokens to claim dividends for");

        uint256 unclaimedDividends = getUnclaimedDividends(msg.sender, tokenId);
        require(unclaimedDividends > 0, "No unclaimed dividends");

        claimedDividends[msg.sender][tokenId] += unclaimedDividends;

        IERC20(dividendsPerToken[tokenId]).transfer(msg.sender, unclaimedDividends);
        emit DividendsClaimed(msg.sender, tokenId, unclaimedDividends);
    }

    // Function to calculate the unclaimed dividends for a specific holder and token ID
    function getUnclaimedDividends(address holder, uint256 tokenId) public view returns (uint256) {
        uint256 totalDividends = dividendsPerToken[tokenId];
        uint256 holderBalance = assetToken.balanceOf(holder, tokenId);
        uint256 totalSupply = assetToken.totalSupply(tokenId);

        uint256 entitledDividends = (totalDividends * holderBalance) / totalSupply;
        uint256 claimedAmount = claimedDividends[holder][tokenId];

        return entitledDividends - claimedAmount;
    }

    // Function to get the total dividends for a specific token ID
    function getTotalDividends(uint256 tokenId) external view returns (uint256) {
        return dividendsPerToken[tokenId];
    }
}
