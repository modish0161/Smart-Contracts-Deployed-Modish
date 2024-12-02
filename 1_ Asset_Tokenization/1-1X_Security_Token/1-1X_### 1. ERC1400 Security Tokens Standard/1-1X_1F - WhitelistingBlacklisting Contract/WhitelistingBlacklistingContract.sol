// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin libraries for modular security features
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Import ERC1400 interface and extensions
import "./IERC1400.sol";
import "./IERC1400TokensValidator.sol";
import "./IERC1400TokensSender.sol";
import "./IERC1400TokensRecipient.sol";

// WhitelistingBlacklistingContract based on ERC1400 standard
contract WhitelistingBlacklistingContract is IERC1400, Ownable, AccessControl, Pausable, ReentrancyGuard {
    // Define roles for access control
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant WHITELIST_MANAGER_ROLE = keccak256("WHITELIST_MANAGER_ROLE");
    bytes32 public constant BLACKLIST_MANAGER_ROLE = keccak256("BLACKLIST_MANAGER_ROLE");

    // ERC1400 compliance details
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(bytes32 => mapping(address => uint256)) private _partitionBalances;
    mapping(address => mapping(address => uint256)) private _allowed;
    
    // Whitelist and blacklist mappings
    mapping(address => bool) private _whitelist;
    mapping(address => bool) private _blacklist;

    // Events for whitelisting and blacklisting
    event AddressWhitelisted(address indexed account);
    event AddressBlacklisted(address indexed account);
    event AddressRemovedFromWhitelist(address indexed account);
    event AddressRemovedFromBlacklist(address indexed account);

    // Constructor for initial contract setup
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 initialSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _mint(msg.sender, initialSupply_);
        
        // Setup roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(WHITELIST_MANAGER_ROLE, msg.sender);
        _setupRole(BLACKLIST_MANAGER_ROLE, msg.sender);
    }

    // ERC1400 Implementation
    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override whenNotPaused onlyWhitelisted(msg.sender) onlyWhitelisted(recipient) notBlacklisted(msg.sender) notBlacklisted(recipient) returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowed[owner][spender];
    }

    function approve(address spender, uint256 amount) public override whenNotPaused onlyWhitelisted(msg.sender) notBlacklisted(msg.sender) returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPaused onlyWhitelisted(sender) onlyWhitelisted(recipient) notBlacklisted(sender) notBlacklisted(recipient) returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowed[sender][msg.sender] - amount);
        return true;
    }

    // Function to mint new tokens
    function mint(address account, uint256 amount) public onlyRole(ADMIN_ROLE) whenNotPaused {
        _mint(account, amount);
    }

    // Internal function to handle token transfers
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC1400: transfer from the zero address");
        require(recipient != address(0), "ERC1400: transfer to the zero address");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    // Internal function to mint new tokens
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC1400: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    // Internal function to approve allowances
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC1400: approve from the zero address");
        require(spender != address(0), "ERC1400: approve to the zero address");

        _allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Function to add an address to the whitelist
    function addWhitelist(address account) public onlyRole(WHITELIST_MANAGER_ROLE) {
        _whitelist[account] = true;
        emit AddressWhitelisted(account);
    }

    // Function to remove an address from the whitelist
    function removeWhitelist(address account) public onlyRole(WHITELIST_MANAGER_ROLE) {
        _whitelist[account] = false;
        emit AddressRemovedFromWhitelist(account);
    }

    // Function to add an address to the blacklist
    function addBlacklist(address account) public onlyRole(BLACKLIST_MANAGER_ROLE) {
        _blacklist[account] = true;
        emit AddressBlacklisted(account);
    }

    // Function to remove an address from the blacklist
    function removeBlacklist(address account) public onlyRole(BLACKLIST_MANAGER_ROLE) {
        _blacklist[account] = false;
        emit AddressRemovedFromBlacklist(account);
    }

    // Modifier to check if an address is whitelisted
    modifier onlyWhitelisted(address account) {
        require(_whitelist[account], "WhitelistingBlacklistingContract: address is not whitelisted");
        _;
    }

    // Modifier to check if an address is not blacklisted
    modifier notBlacklisted(address account) {
        require(!_blacklist[account], "WhitelistingBlacklistingContract: address is blacklisted");
        _;
    }

    // Pause contract functions in case of emergency
    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    // Unpause contract functions
    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // Emergency withdrawal function
    function emergencyWithdraw() public onlyOwner whenPaused {
        payable(owner()).transfer(address(this).balance);
    }
}
