// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

contract PerformanceFeeContract is Ownable, ReentrancyGuard {
    struct Investor {
        bool isAccredited;
        uint256 shares;
        uint256 lastClaimedProfit;
    }

    mapping(address => Investor) public investors;
    uint256 public totalShares;
    uint256 public performanceFeePercentage; // Performance fee as a percentage (e.g., 20 for 20%)
    uint256 public profitThreshold; // Profit threshold for performance fee calculation
    uint256 public totalProfits; // Total profits accrued by the fund

    event TokensIssued(address indexed investor, uint256 shares);
    event PerformanceFeeClaimed(address indexed manager, uint256 feeAmount);

    constructor(uint256 _performanceFeePercentage, uint256 _profitThreshold) {
        performanceFeePercentage = _performanceFeePercentage;
        profitThreshold = _profitThreshold;
    }

    modifier onlyAccredited() {
        require(investors[msg.sender].isAccredited, "Not an accredited investor");
        _;
    }

    function registerAccreditedInvestor(address _investor) external onlyOwner {
        require(_investor != address(0), "Invalid investor address");
        investors[_investor].isAccredited = true;
    }

    function issueTokens(uint256 _shares) external onlyAccredited nonReentrant {
        require(_shares > 0, "Shares must be greater than zero");

        investors[msg.sender].shares += _shares;
        totalShares += _shares;

        emit TokensIssued(msg.sender, _shares);
    }

    function recordProfits(uint256 _profit) external onlyOwner {
        require(_profit > 0, "Profit must be greater than zero");
        totalProfits += _profit;
    }

    function calculatePerformanceFee() internal view returns (uint256) {
        if (totalProfits > profitThreshold) {
            uint256 performanceFee = (totalProfits - profitThreshold) * performanceFeePercentage / 100;
            return performanceFee;
        }
        return 0;
    }

    function claimPerformanceFee() external onlyOwner nonReentrant {
        uint256 feeAmount = calculatePerformanceFee();
        require(feeAmount > 0, "No performance fee to claim");

        totalProfits -= feeAmount; // Deduct fee from total profits
        emit PerformanceFeeClaimed(msg.sender, feeAmount);
        
        // Here, you would implement the logic to transfer the fee to the fund manager's address
        // e.g., transfer(fundManagerAddress, feeAmount);
    }

    function withdrawTokens(uint256 _shares) external onlyAccredited nonReentrant {
        require(_shares > 0, "Shares must be greater than zero");
        require(investors[msg.sender].shares >= _shares, "Insufficient shares");

        investors[msg.sender].shares -= _shares;
        totalShares -= _shares;

        // Implement logic to transfer the underlying asset tokens to the investor
        // e.g., underlyingAsset.transfer(msg.sender, _shares);
    }

    function getInvestorShares(address _investor) external view returns (uint256) {
        return investors[_investor].shares;
    }

    function getTotalShares() external view returns (uint256) {
        return totalShares;
    }

    function getTotalProfits() external view returns (uint256) {
        return totalProfits;
    }
}
