// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

contract ETFTokenIssuance is Ownable {
    // Token details
    string public name = "ETF Token";
    string public symbol = "ETFT";
    uint256 public totalSupply;
    mapping(address => uint256) private balances;
    mapping(address => bool) private accreditedInvestors;

    event TokensIssued(address indexed investor, uint256 amount);
    event InvestorVerified(address indexed investor);
    event InvestorDeVerified(address indexed investor);

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

    // Additional functionality for ERC1400 compliance can be added here
}
