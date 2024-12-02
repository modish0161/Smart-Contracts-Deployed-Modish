// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DynamicDividendDistribution is Ownable, ReentrancyGuard {
    // ERC1155 token contract
    ERC1155 public assetToken;

    // ERC20 token used for dividend distribution
    IERC20 public dividendToken;

    // Mapping to track total dividends distributed for each token ID
    mapping(uint256 => uint256) public totalDividends;

    // Mapping to track claimed dividends for each holder and token ID
    mapping(address => mapping(uint256 => uint256)) public claimedDividends;

    // Event emitted when dividends are distributed
    event DividendsDistributed(uint256 indexed tokenId, uint256 amount);

    // Event emitted when dividends are claimed
    event DividendsClaimed(address indexed holder, uint256 indexed tokenId, uint256 amount);

    constructor(address _assetToken, address _dividendToken) {
        require(_assetToken != address(0), "Invalid asset token address");
        require(_dividendToken != address(0), "Invalid dividend token address");

        assetToken = ERC1155(_assetToken);
        dividendToken = IERC20(_dividendToken);
    }

    // Function to dynamically distribute dividends based on performance
    function distributeDividends(uint256 tokenId, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        totalDividends[tokenId] += amount;

        // Transfer the dividend tokens to the contract
        require(dividendToken.transferFrom(msg.sender, address(this), amount), "Dividend transfer failed");

        emit DividendsDistributed(tokenId, amount);
    }

    // Function to claim dividends for a specific token ID
    function claimDividends(uint256 tokenId) external nonReentrant {
        uint256 holderBalance = assetToken.balanceOf(msg.sender, tokenId);
        require(holderBalance > 0, "No tokens to claim dividends for");

        uint256 unclaimedDividends = getUnclaimedDividends(msg.sender, tokenId);
        require(unclaimedDividends > 0, "No unclaimed dividends");

        claimedDividends[msg.sender][tokenId] += unclaimedDividends;

        require(dividendToken.transfer(msg.sender, unclaimedDividends), "Dividend claim transfer failed");
        emit DividendsClaimed(msg.sender, tokenId, unclaimedDividends);
    }

    // Function to calculate the unclaimed dividends for a specific holder and token ID
    function getUnclaimedDividends(address holder, uint256 tokenId) public view returns (uint256) {
        uint256 totalDividendsForToken = totalDividends[tokenId];
        uint256 holderBalance = assetToken.balanceOf(holder, tokenId);
        uint256 totalSupply = getTotalSupply(tokenId);

        if (totalSupply == 0) return 0;

        uint256 entitledDividends = (totalDividendsForToken * holderBalance) / totalSupply;
        uint256 claimedAmount = claimedDividends[holder][tokenId];

        return entitledDividends > claimedAmount ? entitledDividends - claimedAmount : 0;
    }

    // Function to get the total supply for a given token ID
    function getTotalSupply(uint256 tokenId) public view returns (uint256) {
        return assetToken.totalSupply(tokenId);
    }
}
