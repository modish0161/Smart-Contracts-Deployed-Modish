// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OperatorControlledRedemption is ERC777, Ownable, ReentrancyGuard {
    mapping(address => uint256) public contributions; // Track contributions of each investor
    uint256 public totalCapital; // Total capital managed by the hedge fund
    address public operator; // Address authorized to handle redemptions

    event TokensRedeemed(address indexed investor, uint256 amount, uint256 value);
    event OperatorChanged(address indexed newOperator);

    modifier onlyOperator() {
        require(msg.sender == operator, "Caller is not the operator");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators,
        address _operator
    ) ERC777(name, symbol, defaultOperators) {
        operator = _operator;
    }

    // Function to set a new operator
    function setOperator(address newOperator) external onlyOwner {
        operator = newOperator;
        emit OperatorChanged(newOperator);
    }

    // Function for investors to contribute and receive tokens
    function contribute(uint256 amount) external nonReentrant {
        require(amount > 0, "Contribution must be greater than 0");

        contributions[msg.sender] += amount;
        totalCapital += amount;
        _mint(msg.sender, amount, "", ""); // Mint new tokens proportional to contribution
    }

    // Function for the operator to handle token redemptions
    function redeemTokens(uint256 amount) external nonReentrant onlyOperator {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient token balance");

        contributions[msg.sender] -= amount; // Deduct contribution
        totalCapital -= amount; // Update total capital

        // Burn tokens on redemption
        _burn(msg.sender, amount, ""); 

        uint256 cashValue = amount; // Assume 1:1 redemption for simplicity
        emit TokensRedeemed(msg.sender, amount, cashValue);
    }

    // Function to view total capital
    function getTotalCapital() external view returns (uint256) {
        return totalCapital;
    }
}
