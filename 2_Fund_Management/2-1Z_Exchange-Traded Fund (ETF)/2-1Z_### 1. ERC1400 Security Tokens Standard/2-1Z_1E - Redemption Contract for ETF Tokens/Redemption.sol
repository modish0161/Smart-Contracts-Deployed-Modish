// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

contract RedemptionETF is Ownable {
    IERC1400 public securityToken;

    // Mapping to keep track of redeemable amounts
    mapping(address => uint256) public redeemableAmounts;

    event TokensRedeemed(address indexed investor, uint256 amount);
    
    constructor(address _securityToken) {
        securityToken = IERC1400(_securityToken);
    }

    // Function to set redeemable amount for an investor
    function setRedeemableAmount(address investor, uint256 amount) external onlyOwner {
        redeemableAmounts[investor] = amount;
    }

    // Function for investors to redeem their tokens
    function redeemTokens(uint256 amount) external {
        require(redeemableAmounts[msg.sender] >= amount, "Insufficient redeemable amount");

        // Here you can add the logic to transfer the underlying assets or cash value
        // For demonstration, we will just zero out the redeemable amount
        redeemableAmounts[msg.sender] -= amount;

        // Emit event after successful redemption
        emit TokensRedeemed(msg.sender, amount);
    }

    // Function to check redeemable amount for an investor
    function checkRedeemableAmount(address investor) external view returns (uint256) {
        return redeemableAmounts[investor];
    }
}
