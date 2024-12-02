// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

contract RedemptionContract is Ownable, ReentrancyGuard {
    IERC1400 public token; // Reference to the ERC1400 token contract
    mapping(address => uint256) public redemptionShares;

    event RedemptionRequested(address indexed investor, uint256 shares);
    event RedemptionProcessed(address indexed investor, uint256 cashValue);
    
    constructor(address _tokenAddress) {
        token = IERC1400(_tokenAddress);
    }

    function requestRedemption(uint256 _shares) external nonReentrant {
        require(_shares > 0, "Shares must be greater than zero");
        require(token.balanceOf(msg.sender) >= _shares, "Insufficient token balance");

        redemptionShares[msg.sender] += _shares;
        emit RedemptionRequested(msg.sender, _shares);
    }

    function processRedemption(address _investor) external onlyOwner nonReentrant {
        uint256 shares = redemptionShares[_investor];
        require(shares > 0, "No shares to redeem");

        uint256 cashValue = calculateCashValue(shares); // Implement this function based on your fund's assets
        require(cashValue > 0, "Cash value must be positive");

        redemptionShares[_investor] = 0; // Reset shares to redeem

        // Here, implement the logic to transfer cashValue to the investor
        // For example, using a token transfer or a direct ETH transfer:
        // payable(_investor).transfer(cashValue);

        emit RedemptionProcessed(_investor, cashValue);
    }

    function calculateCashValue(uint256 shares) internal view returns (uint256) {
        // Implement your logic to calculate the cash value of the shares
        // This could be based on current NAV or other valuation metrics
        return shares * 1e18; // Example: 1 share = 1 ETH (replace with actual logic)
    }

    function withdraw() external onlyOwner {
        // Withdraw function for the owner to withdraw funds from the contract
        payable(owner()).transfer(address(this).balance);
    }

    // Fallback function to accept ETH
    receive() external payable {}
}
