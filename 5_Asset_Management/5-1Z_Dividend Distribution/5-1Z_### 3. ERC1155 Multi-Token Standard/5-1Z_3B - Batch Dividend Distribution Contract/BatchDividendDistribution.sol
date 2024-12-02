// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BatchDividendDistribution is Ownable, ReentrancyGuard {
    // ERC1155 token contract
    ERC1155 public assetToken;

    // ERC20 token used for dividend distribution
    IERC20 public dividendToken;

    // Mapping to track dividends per token ID
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

    // Function to distribute dividends in a batch to multiple token IDs
    function distributeDividendsBatch(uint256[] calldata tokenIds, uint256[] calldata amounts) external onlyOwner nonReentrant {
        require(tokenIds.length == amounts.length, "Array lengths must match");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 amount = amounts[i];

            require(amount > 0, "Amount must be greater than zero");

            totalDividends[tokenId] += amount;
            emit DividendsDistributed(tokenId, amount);
        }

        // Transfer the dividend tokens to the contract
        uint256 totalAmount = getTotalAmount(amounts);
        require(dividendToken.transferFrom(msg.sender, address(this), totalAmount), "Dividend transfer failed");
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
        uint256 totalSupply = assetToken.totalSupply(tokenId);

        uint256 entitledDividends = (totalDividendsForToken * holderBalance) / totalSupply;
        uint256 claimedAmount = claimedDividends[holder][tokenId];

        return entitledDividends - claimedAmount;
    }

    // Function to get the total amount of dividends being distributed
    function getTotalAmount(uint256[] memory amounts) internal pure returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }
        return total;
    }
}