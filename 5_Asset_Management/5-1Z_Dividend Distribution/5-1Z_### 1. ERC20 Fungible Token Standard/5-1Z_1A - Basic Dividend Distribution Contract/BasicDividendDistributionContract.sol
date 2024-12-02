// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BasicDividendDistributionContract is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public dividendToken; // ERC20 token used for dividend distribution
    IERC20 public rewardToken; // ERC20 token representing share ownership
    uint256 public totalDividends; // Total dividends available for distribution
    uint256 public totalDistributed; // Total dividends already distributed
    uint256 public totalShares; // Total shares issued
    mapping(address => uint256) public shareholderDividends; // Track dividends owed to each shareholder
    mapping(address => uint256) public shareholderWithdrawn; // Track dividends already withdrawn by each shareholder

    event DividendsDeposited(address indexed from, uint256 amount);
    event DividendWithdrawn(address indexed shareholder, uint256 amount);
    event DividendsClaimed(address indexed shareholder, uint256 amount);

    constructor(address _dividendToken, address _rewardToken) {
        require(_dividendToken != address(0), "Invalid dividend token address");
        require(_rewardToken != address(0), "Invalid reward token address");
        dividendToken = IERC20(_dividendToken);
        rewardToken = IERC20(_rewardToken);
    }

    // Function to deposit dividends into the contract for distribution
    function depositDividends(uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(dividendToken.balanceOf(msg.sender) >= _amount, "Insufficient token balance");

        // Transfer the dividends to the contract
        dividendToken.safeTransferFrom(msg.sender, address(this), _amount);

        // Update the total dividends and distribute to all shareholders
        totalDividends = totalDividends + _amount;
        emit DividendsDeposited(msg.sender, _amount);
    }

    // Function to calculate and allocate dividends to each shareholder
    function distributeDividends() external onlyOwner nonReentrant {
        require(totalDividends > totalDistributed, "No new dividends to distribute");

        uint256 undistributedDividends = totalDividends - totalDistributed;

        for (uint256 i = 0; i < rewardToken.totalSupply(); i++) {
            address shareholder = rewardToken.ownerOf(i);
            uint256 shares = rewardToken.balanceOf(shareholder);
            uint256 sharePercentage = shares * 1e18 / totalShares; // Calculate share percentage in 18 decimal places
            uint256 owedDividends = undistributedDividends * sharePercentage / 1e18;

            shareholderDividends[shareholder] += owedDividends;
        }

        totalDistributed = totalDividends;
    }

    // Function to claim dividends for a shareholder
    function claimDividends() external nonReentrant {
        uint256 owedDividends = shareholderDividends[msg.sender];
        require(owedDividends > 0, "No dividends to claim");

        // Transfer the owed dividends to the shareholder
        dividendToken.safeTransfer(msg.sender, owedDividends);
        shareholderWithdrawn[msg.sender] += owedDividends;
        shareholderDividends[msg.sender] = 0;

        emit DividendWithdrawn(msg.sender, owedDividends);
    }

    // Function to get dividends available to withdraw for a shareholder
    function availableDividends(address shareholder) external view returns (uint256) {
        return shareholderDividends[shareholder];
    }

    // Function to withdraw dividends manually by contract owner
    function withdrawDividends(uint256 _amount) external onlyOwner nonReentrant {
        require(_amount <= dividendToken.balanceOf(address(this)), "Insufficient dividends available");
        dividendToken.safeTransfer(owner(), _amount);
    }

    // Function to update the dividend token
    function updateDividendToken(address _newToken) external onlyOwner {
        require(_newToken != address(0), "Invalid token address");
        dividendToken = IERC20(_newToken);
    }

    // Function to update the reward token
    function updateRewardToken(address _newToken) external onlyOwner {
        require(_newToken != address(0), "Invalid token address");
        rewardToken = IERC20(_newToken);
    }
}
