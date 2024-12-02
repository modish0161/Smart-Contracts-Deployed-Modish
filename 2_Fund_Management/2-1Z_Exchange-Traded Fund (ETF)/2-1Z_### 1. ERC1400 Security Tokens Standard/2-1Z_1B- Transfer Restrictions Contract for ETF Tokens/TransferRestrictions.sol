// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

contract TransferRestrictionsETF is Ownable {
    // Token details
    string public name = "ETF Token";
    string public symbol = "ETFT";
    uint256 public totalSupply;

    // Mapping to store balances
    mapping(address => uint256) private balances;

    // Mapping for accredited investors
    mapping(address => bool) private accreditedInvestors;

    event TokensIssued(address indexed investor, uint256 amount);
    event InvestorVerified(address indexed investor);
    event InvestorDeVerified(address indexed investor);
    event TransferRestricted(address indexed from, address indexed to);

    modifier onlyAccredited() {
        require(accreditedInvestors[msg.sender], "Not an accredited investor");
        _;
    }

    // Function to issue tokens to an accredited investor
    function issueTokens(address investor, uint256 amount) external onlyOwner onlyAccredited {
        totalSupply += amount;
        balances[investor] += amount;
        emit TokensIssued(investor, amount);
    }

    // Function to verify an investor
    function verifyInvestor(address investor) external onlyOwner {
        accreditedInvestors[investor] = true;
        emit InvestorVerified(investor);
    }

    // Function to de-verify an investor
    function deVerifyInvestor(address investor) external onlyOwner {
        accreditedInvestors[investor] = false;
        emit InvestorDeVerified(investor);
    }

    // Function to check the balance of an investor
    function balanceOf(address investor) external view returns (uint256) {
        return balances[investor];
    }

    // Function to check if an investor is accredited
    function isAccredited(address investor) external view returns (bool) {
        return accreditedInvestors[investor];
    }

    // Override transfer function to enforce restrictions
    function transfer(address to, uint256 amount) external onlyAccredited {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit TransferRestricted(msg.sender, to);
    }

    // Additional ERC1400 features can be added here for compliance checks
}
