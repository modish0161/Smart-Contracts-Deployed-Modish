// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

contract ProfitDistributionContract is Ownable, ReentrancyGuard {
    struct Investor {
        uint256 shares;
        uint256 lastClaimedProfit;
    }

    mapping(address => Investor) public investors;
    uint256 public totalShares;
    uint256 public totalProfits; // Total profits available for distribution
    uint256 public profitPerShare; // Calculated profit per share for distribution

    event TokensIssued(address indexed investor, uint256 shares);
    event ProfitsRecorded(uint256 profit);
    event ProfitsDistributed(address indexed investor, uint256 profit);

    constructor() {}

    modifier onlyInvestor() {
        require(investors[msg.sender].shares > 0, "Not an investor");
        _;
    }

    function issueTokens(uint256 _shares) external onlyOwner {
        require(_shares > 0, "Shares must be greater than zero");

        investors[msg.sender].shares += _shares;
        totalShares += _shares;

        emit TokensIssued(msg.sender, _shares);
    }

    function recordProfits(uint256 _profit) external onlyOwner {
        require(_profit > 0, "Profit must be greater than zero");

        totalProfits += _profit;
        profitPerShare = totalProfits / totalShares; // Calculate profit per share

        emit ProfitsRecorded(_profit);
    }

    function distributeProfits() external onlyInvestor nonReentrant {
        uint256 investorProfit = (investors[msg.sender].shares * profitPerShare) - investors[msg.sender].lastClaimedProfit;
        require(investorProfit > 0, "No profits to distribute");

        investors[msg.sender].lastClaimedProfit += investorProfit;
        totalProfits -= investorProfit; // Deduct the distributed profit

        // Here, you would implement the logic to transfer the profit to the investor's address
        // e.g., transfer(msg.sender, investorProfit);

        emit ProfitsDistributed(msg.sender, investorProfit);
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
