// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

contract DividendDistributionETF is Ownable {
    // Token details
    IERC1400 public securityToken;
    uint256 public totalDividends;

    // Mapping to track dividends claimed by investors
    mapping(address => uint256) private dividendsClaimed;

    event DividendsDistributed(uint256 amount);
    event DividendClaimed(address indexed investor, uint256 amount);

    constructor(address _securityToken) {
        securityToken = IERC1400(_securityToken);
    }

    // Function to distribute dividends to token holders
    function distributeDividends(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        totalDividends += amount;

        // Transfer the specified amount to this contract
        // Assuming the contract holds enough funds for distribution
        emit DividendsDistributed(amount);
    }

    // Function to calculate the dividend for an investor
    function calculateDividend(address investor) public view returns (uint256) {
        uint256 totalSupply = securityToken.totalSupply();
        uint256 balance = securityToken.balanceOf(investor);
        if (totalSupply == 0 || balance == 0) {
            return 0;
        }
        uint256 dividend = (totalDividends * balance) / totalSupply;
        return dividend - dividendsClaimed[investor]; // Unclaimed dividend
    }

    // Function for investors to claim their dividends
    function claimDividends() external {
        uint256 dividend = calculateDividend(msg.sender);
        require(dividend > 0, "No dividends to claim");

        dividendsClaimed[msg.sender] += dividend;

        // Transfer the claimed dividends to the investor
        payable(msg.sender).transfer(dividend);

        emit DividendClaimed(msg.sender, dividend);
    }

    // Function to withdraw any accidental ether sent to this contract
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Fallback function to accept Ether
    receive() external payable {}
}
