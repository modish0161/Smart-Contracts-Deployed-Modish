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

contract ComplianceReportingMutualFund is IERC20, IERC1404, Ownable, Pausable, ReentrancyGuard, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    uint256 private _totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Compliance data mappings
    struct ComplianceData {
        uint256 totalTransfers;
        uint256 totalHoldings;
        uint256 restrictedTransfers;
        bool isVerified;
    }

    mapping(address => ComplianceData) public complianceReports;
    mapping(address => bool) public whitelisted;

    event ComplianceReportGenerated(address indexed investor, uint256 totalTransfers, uint256 totalHoldings, uint256 restrictedTransfers);
    event AddressWhitelisted(address indexed account);
    event AddressRemovedFromWhitelist(address indexed account);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = 18;
        _totalSupply = initialSupply;
        _balances[msg.sender] = initialSupply;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_ROLE, msg.sender);

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

    // Internal transfer function with restriction checks and compliance tracking
    function _transfer(address sender, address recipient, uint256 amount) internal whenNotPaused {
        require(sender != address(0), "Transfer from zero address");
        require(recipient != address(0), "Transfer to zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint8 restrictionCode = detectTransferRestriction(sender, recipient, amount);
        if (restrictionCode != 0) {
            complianceReports[sender].restrictedTransfers = complianceReports[sender].restrictedTransfers.add(1);
            emit ComplianceReportGenerated(sender, complianceReports[sender].totalTransfers, _balances[sender], complianceReports[sender].restrictedTransfers);
            revert(messageForTransferRestriction(restrictionCode));
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient balance");
        _balances[recipient] = _balances[recipient].add(amount);

        complianceReports[sender].totalTransfers = complianceReports[sender].totalTransfers.add(1);
        complianceReports[sender].totalHoldings = _balances[sender];
        complianceReports[recipient].totalHoldings = _balances[recipient];

        emit Transfer(sender, recipient, amount);
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

    // Generate compliance report for an address
    function generateComplianceReport(address account) external view returns (uint256 totalTransfers, uint256 totalHoldings, uint256 restrictedTransfers) {
        ComplianceData storage report = complianceReports[account];
        return (report.totalTransfers, report.totalHoldings, report.restrictedTransfers);
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
