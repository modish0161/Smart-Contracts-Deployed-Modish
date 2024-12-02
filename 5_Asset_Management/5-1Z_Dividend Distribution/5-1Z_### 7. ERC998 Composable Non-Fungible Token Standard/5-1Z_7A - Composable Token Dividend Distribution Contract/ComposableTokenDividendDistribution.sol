// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC998/IERC998TopDown.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ComposableTokenDividendDistribution is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    IERC998TopDown public composableToken;  // ERC998 Composable Token
    IERC20 public dividendToken;            // ERC20 Token used for distributing dividends

    uint256 public totalDividends;          // Total dividends available for distribution
    mapping(uint256 => uint256) public claimedDividends; // Track claimed dividends for each composable token ID
    mapping(address => bool) public approvedDistributors; // Approved distributors for dividend distribution

    event DividendsDistributed(uint256 amount);         // Event emitted when dividends are distributed
    event DividendsClaimed(uint256 indexed tokenId, uint256 amount); // Event emitted when dividends are claimed
    event DistributorApproved(address distributor);     // Event emitted when a distributor is approved
    event DistributorRevoked(address distributor);      // Event emitted when a distributor is revoked

    modifier onlyApprovedDistributor() {
        require(approvedDistributors[msg.sender], "Not an approved distributor");
        _;
    }

    constructor(address _composableToken, address _dividendToken) {
        require(_composableToken != address(0), "Invalid composable token address");
        require(_dividendToken != address(0), "Invalid dividend token address");

        composableToken = IERC998TopDown(_composableToken);
        dividendToken = IERC20(_dividendToken);
    }

    // Function to approve a distributor for dividend distribution
    function approveDistributor(address distributor) external onlyOwner {
        approvedDistributors[distributor] = true;
        emit DistributorApproved(distributor);
    }

    // Function to revoke a distributor
    function revokeDistributor(address distributor) external onlyOwner {
        approvedDistributors[distributor] = false;
        emit DistributorRevoked(distributor);
    }

    // Function to distribute dividends to all composable token holders
    function distributeDividends(uint256 amount) external onlyApprovedDistributor nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(dividendToken.balanceOf(msg.sender) >= amount, "Insufficient dividend token balance");

        totalDividends = totalDividends.add(amount);
        require(dividendToken.transferFrom(msg.sender, address(this), amount), "Dividend transfer failed");

        emit DividendsDistributed(amount);
    }

    // Function to claim dividends
    function claimDividends(uint256 tokenId) external nonReentrant {
        require(composableToken.ownerOf(tokenId) == msg.sender, "Not token owner");

        uint256 unclaimedDividends = getUnclaimedDividends(tokenId);
        require(unclaimedDividends > 0, "No unclaimed dividends");

        claimedDividends[tokenId] = claimedDividends[tokenId].add(unclaimedDividends);
        require(dividendToken.transfer(msg.sender, unclaimedDividends), "Dividend claim transfer failed");

        emit DividendsClaimed(tokenId, unclaimedDividends);
    }

    // Function to calculate unclaimed dividends for a composable token
    function getUnclaimedDividends(uint256 tokenId) public view returns (uint256) {
        uint256 totalValue = composableToken.totalValue(tokenId);
        uint256 entitledDividends = (totalDividends.mul(totalValue)).div(composableToken.totalValue(address(this)));
        uint256 claimedAmount = claimedDividends[tokenId];

        return entitledDividends > claimedAmount ? entitledDividends.sub(claimedAmount) : 0;
    }

    // Function to withdraw remaining dividends (onlyOwner)
    function withdrawRemainingDividends() external onlyOwner nonReentrant {
        uint256 remainingDividends = dividendToken.balanceOf(address(this));
        require(remainingDividends > 0, "No remaining dividends");

        totalDividends = 0; // Reset total dividends
        require(dividendToken.transfer(owner(), remainingDividends), "Withdrawal transfer failed");
    }
}
