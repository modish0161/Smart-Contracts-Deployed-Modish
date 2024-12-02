// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IERC998TopDown is IERC721 {
    function childContractsFor(uint256 _tokenId) external view returns (address[] memory);
    function childTokenBalance(uint256 _tokenId, address _childContract, uint256 _childTokenId) external view returns (uint256);
}

contract MultiLayeredDividendDistribution is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    IERC998TopDown public composableToken;  // ERC998 Composable Token
    IERC20 public dividendToken;            // ERC20 Token used for distributing dividends
    uint256 public totalDividends;          // Total dividends available for distribution

    mapping(uint256 => uint256) public claimedDividends;  // Track claimed dividends for each parent token ID
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public claimedChildDividends; // Track claimed dividends for child assets
    mapping(address => bool) public approvedDistributors; // Approved distributors for dividend distribution

    event DividendsDistributed(uint256 amount);
    event DividendsClaimed(uint256 indexed tokenId, uint256 amount);
    event ChildDividendsClaimed(uint256 indexed tokenId, address indexed childContract, uint256 childTokenId, uint256 amount);
    event DistributorApproved(address distributor);
    event DistributorRevoked(address distributor);

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

    // Approve a distributor for dividend distribution
    function approveDistributor(address distributor) external onlyOwner {
        approvedDistributors[distributor] = true;
        emit DistributorApproved(distributor);
    }

    // Revoke a distributor
    function revokeDistributor(address distributor) external onlyOwner {
        approvedDistributors[distributor] = false;
        emit DistributorRevoked(distributor);
    }

    // Distribute dividends to all composable token holders
    function distributeDividends(uint256 amount) external onlyApprovedDistributor nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(dividendToken.balanceOf(msg.sender) >= amount, "Insufficient dividend token balance");

        totalDividends = totalDividends.add(amount);
        require(dividendToken.transferFrom(msg.sender, address(this), amount), "Dividend transfer failed");

        emit DividendsDistributed(amount);
    }

    // Claim dividends for parent token
    function claimDividends(uint256 tokenId) external nonReentrant {
        require(composableToken.ownerOf(tokenId) == msg.sender, "Not token owner");

        uint256 unclaimedDividends = getUnclaimedDividends(tokenId);
        require(unclaimedDividends > 0, "No unclaimed dividends");

        claimedDividends[tokenId] = claimedDividends[tokenId].add(unclaimedDividends);
        require(dividendToken.transfer(msg.sender, unclaimedDividends), "Dividend claim transfer failed");

        emit DividendsClaimed(tokenId, unclaimedDividends);
    }

    // Claim dividends for child assets
    function claimChildDividends(uint256 tokenId, address childContract, uint256 childTokenId) external nonReentrant {
        require(composableToken.ownerOf(tokenId) == msg.sender, "Not token owner");

        uint256 unclaimedChildDividends = getUnclaimedChildDividends(tokenId, childContract, childTokenId);
        require(unclaimedChildDividends > 0, "No unclaimed child dividends");

        claimedChildDividends[tokenId][childContract][childTokenId] = claimedChildDividends[tokenId][childContract][childTokenId].add(unclaimedChildDividends);
        require(dividendToken.transfer(msg.sender, unclaimedChildDividends), "Dividend claim transfer failed");

        emit ChildDividendsClaimed(tokenId, childContract, childTokenId, unclaimedChildDividends);
    }

    // Get unclaimed dividends for parent token
    function getUnclaimedDividends(uint256 tokenId) public view returns (uint256) {
        uint256 totalValue = composableToken.totalSupply(); // Example function, replace with actual total value
        uint256 entitledDividends = (totalDividends.mul(1)).div(totalValue); // Example formula, replace with actual calculation
        uint256 claimedAmount = claimedDividends[tokenId];

        return entitledDividends > claimedAmount ? entitledDividends.sub(claimedAmount) : 0;
    }

    // Get unclaimed dividends for child assets
    function getUnclaimedChildDividends(uint256 tokenId, address childContract, uint256 childTokenId) public view returns (uint256) {
        uint256 totalChildValue = composableToken.childTokenBalance(tokenId, childContract, childTokenId); // Example function, replace with actual child value
        uint256 entitledChildDividends = (totalDividends.mul(1)).div(totalChildValue); // Example formula, replace with actual calculation
        uint256 claimedAmount = claimedChildDividends[tokenId][childContract][childTokenId];

        return entitledChildDividends > claimedAmount ? entitledChildDividends.sub(claimedAmount) : 0;
    }

    // Withdraw remaining dividends
    function withdrawRemainingDividends() external onlyOwner nonReentrant {
        uint256 remainingDividends = dividendToken.balanceOf(address(this));
        require(remainingDividends > 0, "No remaining dividends");

        totalDividends = 0; // Reset total dividends
        require(dividendToken.transfer(owner(), remainingDividends), "Withdrawal transfer failed");
    }
}
