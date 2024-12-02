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

contract InvestorVerificationMutualFund is IERC20, IERC1404, Ownable, Pausable, ReentrancyGuard, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    uint256 private _totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Investor verification mappings
    mapping(address => bool) public accreditedInvestors;
    mapping(address => bool) public verifiedInvestors;

    event InvestorVerified(address indexed account);
    event InvestorUnverified(address indexed account);
    event InvestorAccredited(address indexed account);
    event InvestorUnaccredited(address indexed account);

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

    // Internal transfer function with restriction checks
    function _transfer(address sender, address recipient, uint256 amount) internal whenNotPaused {
        require(sender != address(0), "Transfer from zero address");
        require(recipient != address(0), "Transfer to zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint8 restrictionCode = detectTransferRestriction(sender, recipient, amount);
        require(restrictionCode == 0, messageForTransferRestriction(restrictionCode));

        _balances[sender] = _balances[sender].sub(amount, "Insufficient balance");
        _balances[recipient] = _balances[recipient].add(amount);

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
        if (!verifiedInvestors[from] || !verifiedInvestors[to]) {
            return 1; // Investor not verified
        }
        if (!accreditedInvestors[from] || !accreditedInvestors[to]) {
            return 2; // Investor not accredited
        }
        return 0; // No restrictions
    }

    function messageForTransferRestriction(uint8 restrictionCode) public view override returns (string memory) {
        if (restrictionCode == 1) {
            return "Investor not verified";
        }
        if (restrictionCode == 2) {
            return "Investor not accredited";
        }
        return "No restrictions";
    }

    // Investor verification functions
    function verifyInvestor(address account) external onlyRole(COMPLIANCE_ROLE) {
        require(account != address(0), "Invalid address");
        require(!verifiedInvestors[account], "Investor already verified");
        verifiedInvestors[account] = true;
        emit InvestorVerified(account);
    }

    function unverifyInvestor(address account) external onlyRole(COMPLIANCE_ROLE) {
        require(account != address(0), "Invalid address");
        require(verifiedInvestors[account], "Investor not verified");
        verifiedInvestors[account] = false;
        emit InvestorUnverified(account);
    }

    function accreditInvestor(address account) external onlyRole(COMPLIANCE_ROLE) {
        require(account != address(0), "Invalid address");
        require(!accreditedInvestors[account], "Investor already accredited");
        accreditedInvestors[account] = true;
        emit InvestorAccredited(account);
    }

    function unaccreditInvestor(address account) external onlyRole(COMPLIANCE_ROLE) {
        require(account != address(0), "Invalid address");
        require(accreditedInvestors[account], "Investor not accredited");
        accreditedInvestors[account] = false;
        emit InvestorUnaccredited(account);
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
