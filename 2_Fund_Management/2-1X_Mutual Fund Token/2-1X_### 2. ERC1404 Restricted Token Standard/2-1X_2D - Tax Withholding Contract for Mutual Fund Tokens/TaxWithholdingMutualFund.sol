// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC1404 {
    function detectTransferRestriction(address from, address to, uint256 value) external view returns (uint8);
    function messageForTransferRestriction(uint8 restrictionCode) external view returns (string memory);
}

contract TaxWithholdingMutualFund is IERC20, IERC1404, Ownable, Pausable, ReentrancyGuard, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant TAX_OFFICER_ROLE = keccak256("TAX_OFFICER_ROLE");
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    uint256 private _totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public taxRate; // Tax rate in basis points (e.g., 500 = 5%)

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) public withheldTaxes; // Taxes withheld for each account
    mapping(address => bool) public whitelisted;

    event TaxWithheld(address indexed from, address indexed to, uint256 amount);
    event TaxRateUpdated(uint256 oldRate, uint256 newRate);
    event AddressWhitelisted(address indexed account);
    event AddressRemovedFromWhitelist(address indexed account);
    event TaxWithdrawn(address indexed account, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 initialSupply,
        uint256 _taxRate
    ) {
        require(_taxRate <= 10000, "Invalid tax rate"); // Max 100%
        name = _name;
        symbol = _symbol;
        decimals = 18;
        _totalSupply = initialSupply;
        taxRate = _taxRate;
        _balances[msg.sender] = initialSupply;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_ROLE, msg.sender);
        _setupRole(TAX_OFFICER_ROLE, msg.sender);

        emit Transfer(address(0), msg.sender, initialSupply);
    }

    // IERC20 Functions
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    // Internal transfer function with tax withholding
    function _transfer(address sender, address recipient, uint256 amount) internal whenNotPaused {
        require(sender != address(0), "Transfer from zero address");
        require(recipient != address(0), "Transfer to zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint8 restrictionCode = detectTransferRestriction(sender, recipient, amount);
        require(restrictionCode == 0, messageForTransferRestriction(restrictionCode));

        uint256 taxAmount = calculateTax(amount);
        uint256 netAmount = amount.sub(taxAmount);

        _balances[sender] = _balances[sender].sub(amount, "Insufficient balance");
        _balances[recipient] = _balances[recipient].add(netAmount);
        withheldTaxes[sender] = withheldTaxes[sender].add(taxAmount);

        emit Transfer(sender, recipient, netAmount);
        emit TaxWithheld(sender, recipient, taxAmount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from zero address");
        require(spender != address(0), "Approve to zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // ERC1404 Functions
    function detectTransferRestriction(address from, address to, uint256 value) public view override returns (uint8) {
        if (!whitelisted[from] || !whitelisted[to]) {
            return 1; // Address not whitelisted
        }
        return 0; // No restrictions
    }

    function messageForTransferRestriction(uint8 restrictionCode) public view override returns (string memory) {
        if (restrictionCode == 1) {
            return "Address is not whitelisted";
        }
        return "No restrictions";
    }

    // Tax calculation function
    function calculateTax(uint256 amount) public view returns (uint256) {
        return amount.mul(taxRate).div(10000);
    }

    // Update tax rate
    function updateTaxRate(uint256 newTaxRate) external onlyRole(TAX_OFFICER_ROLE) {
        require(newTaxRate <= 10000, "Invalid tax rate");
        uint256 oldRate = taxRate;
        taxRate = newTaxRate;
        emit TaxRateUpdated(oldRate, newTaxRate);
    }

    // Withdraw withheld taxes
    function withdrawWithheldTaxes() external nonReentrant {
        uint256 amount = withheldTaxes[msg.sender];
        require(amount > 0, "No taxes to withdraw");
        withheldTaxes[msg.sender] = 0;
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        emit TaxWithdrawn(msg.sender, amount);
    }

    // Whitelist management
    function whitelistAddress(address account) external onlyRole(COMPLIANCE_ROLE) {
        require(account != address(0), "Invalid address");
        require(!whitelisted[account], "Address already whitelisted");
        whitelisted[account] = true;
        emit AddressWhitelisted(account);
    }

    function removeWhitelistAddress(address account) external onlyRole(COMPLIANCE_ROLE) {
        require(account != address(0), "Invalid address");
        require(whitelisted[account], "Address not in whitelist");
        whitelisted[account] = false;
        emit AddressRemovedFromWhitelist(account);
    }

    // Pause and Unpause
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Emergency withdraw function for owner
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available for withdrawal");
        payable(owner()).transfer(balance);
    }
}
