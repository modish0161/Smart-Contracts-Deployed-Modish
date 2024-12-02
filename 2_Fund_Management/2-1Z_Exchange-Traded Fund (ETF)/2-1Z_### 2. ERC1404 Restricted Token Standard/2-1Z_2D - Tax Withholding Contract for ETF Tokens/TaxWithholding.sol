// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1404/IERC1404.sol";

contract TaxWithholding is IERC1404, Ownable {
    string public name = "Tax Withholding ETF Token";
    string public symbol = "TWET";
    uint8 public decimals = 18;

    uint256 private totalSupply_;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    // Tax rates (example: 15% for dividends, 20% for capital gains)
    uint256 public dividendTaxRate = 15; // in percentage
    uint256 public capitalGainsTaxRate = 20; // in percentage

    // Accreditation and blacklist mappings
    mapping(address => bool) public accredited;
    mapping(address => bool) public blacklist;

    // Events
    event TaxWithheld(address indexed from, uint256 amount, string taxType);
    event TaxRatesUpdated(uint256 newDividendTaxRate, uint256 newCapitalGainsTaxRate);

    constructor(uint256 initialSupply) {
        totalSupply_ = initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply_;
    }

    // Transfer function
    function transfer(address to, uint256 value) external returns (bool) {
        require(isTransferAllowed(msg.sender, to), "Transfer not allowed");
        uint256 taxAmount = calculateTax(value);
        uint256 netAmount = value - taxAmount;

        _transfer(msg.sender, to, netAmount);
        withholdTax(msg.sender, taxAmount);

        return true;
    }

    // Internal transfer function
    function _transfer(address from, address to, uint256 value) internal {
        require(balances[from] >= value, "Insufficient balance");
        balances[from] -= value;
        balances[to] += value;
    }

    // Check if the transfer is allowed
    function isTransferAllowed(address from, address to) internal view returns (bool) {
        return accredited[from] && accredited[to] && !blacklist[from] && !blacklist[to];
    }

    // Calculate the tax based on the transfer amount
    function calculateTax(uint256 amount) internal view returns (uint256) {
        // Here, assuming it's dividend for simplicity. Logic can be enhanced.
        return (amount * dividendTaxRate) / 100;
    }

    // Withhold tax and log the event
    function withholdTax(address from, uint256 amount) internal {
        emit TaxWithheld(from, amount, "dividend");
    }

    // Owner-only function to update tax rates
    function updateTaxRates(uint256 newDividendTaxRate, uint256 newCapitalGainsTaxRate) external onlyOwner {
        dividendTaxRate = newDividendTaxRate;
        capitalGainsTaxRate = newCapitalGainsTaxRate;
        emit TaxRatesUpdated(newDividendTaxRate, newCapitalGainsTaxRate);
    }

    // Owner-only function to accredit an address
    function accreditAddress(address account) external onlyOwner {
        accredited[account] = true;
    }

    // Owner-only function to remove accreditation from an address
    function removeAccreditation(address account) external onlyOwner {
        accredited[account] = false;
    }

    // Owner-only function to blacklist an address
    function addToBlacklist(address account) external onlyOwner {
        blacklist[account] = true;
    }

    // Owner-only function to remove an address from the blacklist
    function removeFromBlacklist(address account) external onlyOwner {
        blacklist[account] = false;
    }

    // Function to check the total supply
    function totalSupply() external view returns (uint256) {
        return totalSupply_;
    }

    // Function to check the balance of an address
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    // ERC1404 compliance methods
    function detectTransferRestriction(address from, address to) external view returns (uint8) {
        if (blacklist[from] || blacklist[to]) return 1; // Blacklisted
        if (!accredited[from] || !accredited[to]) return 2; // Not accredited
        return 0; // No restriction
    }
}
