// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RealTimeDividendDistribution is Ownable, ReentrancyGuard {
    ERC777 public dividendToken; // ERC777 token used for dividend distribution
    mapping(address => uint256) public tokenBalance; // Mapping of token balances for each holder
    uint256 public totalSupply; // Total supply of the dividend token

    event DividendsDistributed(address indexed holder, uint256 amount);
    event ProfitsReceived(uint256 amount);

    constructor(address _dividendToken) {
        require(_dividendToken != address(0), "Invalid dividend token address");
        dividendToken = ERC777(_dividendToken);
    }

    // Function to receive profits and distribute dividends in real-time
    function receiveProfits(uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(dividendToken.balanceOf(msg.sender) >= _amount, "Insufficient token balance");

        // Send profits to the contract
        dividendToken.send(address(this), _amount, "");
        emit ProfitsReceived(_amount);

        // Distribute dividends to all token holders
        for (uint256 i = 0; i < dividendToken.totalSupply(); i++) {
            address holder = dividendToken.holderAt(i);
            uint256 holderBalance = dividendToken.balanceOf(holder);
            uint256 dividendAmount = (holderBalance * _amount) / dividendToken.totalSupply();

            if (dividendAmount > 0) {
                dividendToken.send(holder, dividendAmount, "");
                emit DividendsDistributed(holder, dividendAmount);
            }
        }
    }

    // Function to update the token balance of a holder
    function updateTokenBalance(address holder, uint256 amount) external onlyOwner {
        tokenBalance[holder] = amount;
        totalSupply += amount;
    }

    // Function to get the total token balance
    function getTotalSupply() external view returns (uint256) {
        return totalSupply;
    }

    // Function to get the balance of a specific holder
    function getBalanceOf(address holder) external view returns (uint256) {
        return tokenBalance[holder];
    }

    // Function to withdraw dividends if there are any undistributed dividends
    function withdrawDividends() external nonReentrant {
        uint256 amount = dividendToken.balanceOf(address(this));
        require(amount > 0, "No dividends to withdraw");

        dividendToken.send(owner(), amount, "");
    }
}
