// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AdvancedDividendDistributionContract is Ownable, ReentrancyGuard {
    ERC777 public dividendToken; // ERC777 token used for dividend distribution
    uint256 public totalDividends; // Total dividends available for distribution
    mapping(address => uint256) public dividends; // Mapping of dividends for each holder
    mapping(address => bool) public isOperator; // Mapping of approved operators

    event DividendsDeposited(address indexed from, uint256 amount);
    event DividendsDistributed(address indexed operator, uint256 amount);
    event DividendsClaimed(address indexed holder, uint256 amount);
    event OperatorApproved(address indexed operator);
    event OperatorRevoked(address indexed operator);

    modifier onlyOperator() {
        require(isOperator[msg.sender] || msg.sender == owner(), "Caller is not an operator");
        _;
    }

    constructor(address _dividendToken, address[] memory _operators) {
        require(_dividendToken != address(0), "Invalid dividend token address");
        dividendToken = ERC777(_dividendToken);
        
        // Approve initial operators
        for (uint256 i = 0; i < _operators.length; i++) {
            isOperator[_operators[i]] = true;
            emit OperatorApproved(_operators[i]);
        }
    }

    // Function to deposit dividends into the contract
    function depositDividends(uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(dividendToken.balanceOf(msg.sender) >= _amount, "Insufficient token balance");

        dividendToken.send(address(this), _amount, "");
        totalDividends += _amount;

        emit DividendsDeposited(msg.sender, _amount);
    }

    // Function to distribute dividends to all token holders
    function distributeDividends() external onlyOperator nonReentrant {
        require(totalDividends > 0, "No dividends to distribute");
        uint256 totalSupply = dividendToken.totalSupply();
        
        // Distribute dividends proportionally to all token holders
        for (uint256 i = 0; i < totalSupply; i++) {
            address holder = address(uint160(i)); // Placeholder logic for token holder retrieval
            uint256 holderBalance = dividendToken.balanceOf(holder);

            if (holderBalance > 0) {
                uint256 share = (totalDividends * holderBalance) / totalSupply;
                dividends[holder] += share;
            }
        }

        emit DividendsDistributed(msg.sender, totalDividends);
        totalDividends = 0; // Reset total dividends after distribution
    }

    // Function to claim dividends by a token holder
    function claimDividends() external nonReentrant {
        uint256 amount = dividends[msg.sender];
        require(amount > 0, "No dividends to claim");

        dividends[msg.sender] = 0;
        dividendToken.send(msg.sender, amount, "");

        emit DividendsClaimed(msg.sender, amount);
    }

    // Function to approve a new operator
    function approveOperator(address _operator) external onlyOwner {
        require(!isOperator[_operator], "Already an operator");
        isOperator[_operator] = true;
        emit OperatorApproved(_operator);
    }

    // Function to revoke an operator
    function revokeOperator(address _operator) external onlyOwner {
        require(isOperator[_operator], "Not an operator");
        isOperator[_operator] = false;
        emit OperatorRevoked(_operator);
    }

    // Function to get dividends of a holder
    function getDividends(address _holder) external view returns (uint256) {
        return dividends[_holder];
    }

    // Function to get total dividends available for distribution
    function getTotalDividends() external view returns (uint256) {
        return totalDividends;
    }
}
