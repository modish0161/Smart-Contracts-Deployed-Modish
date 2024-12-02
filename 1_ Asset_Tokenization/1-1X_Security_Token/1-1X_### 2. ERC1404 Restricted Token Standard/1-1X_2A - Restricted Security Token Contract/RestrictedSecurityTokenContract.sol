// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin libraries for modular security features
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Import ERC1404 interface and extensions
import "./IERC1404.sol";

// RestrictedSecurityTokenContract based on ERC1404 standard
contract RestrictedSecurityTokenContract is IERC1404, Ownable, AccessControl, Pausable, ReentrancyGuard {
    // Define roles for access control
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");

    // ERC1404 compliance details
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(bytes32 => mapping(address => uint256)) private _partitionBalances;
    mapping(address => mapping(address => uint256)) private _allowed;

    // Restrictions data structures
    mapping(address => bool) private _whitelisted;
    mapping(address => bool) private _blacklisted;
    mapping(address => bool) private _restricted;

    // Events for restriction management
    event AddressWhitelisted(address indexed account);
    event AddressBlacklisted(address indexed account);
    event AddressRestricted(address indexed account);
    event AddressUnrestricted(address indexed account);

    // Constructor for initial contract setup
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _mint(msg.sender, initialSupply_);

        // Setup roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_OFFICER_ROLE, msg.sender);
    }

    // ERC1404 Implementation
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

    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        _checkTransferRestrictions(msg.sender, recipient, amount);
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowed[owner][spender];
    }

    function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        _checkTransferRestrictions(sender, recipient, amount);
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
        require(sender != address(0), "ERC1404: transfer from the zero address");
        require(recipient != address(0), "ERC1404: transfer to the zero address");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    // Internal function to mint new tokens
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC1404: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    // Internal function to approve allowances
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC1404: approve from the zero address");
        require(spender != address(0), "ERC1404: approve to the zero address");

        _allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Function to add an address to the whitelist
    function addWhitelist(address account) public onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _whitelisted[account] = true;
        emit AddressWhitelisted(account);
    }

    // Function to add an address to the blacklist
    function addBlacklist(address account) public onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _blacklisted[account] = true;
        emit AddressBlacklisted(account);
    }

    // Function to add an address to the restricted list
    function addRestricted(address account) public onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _restricted[account] = true;
        emit AddressRestricted(account);
    }

    // Function to remove an address from the restricted list
    function removeRestricted(address account) public onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _restricted[account] = false;
        emit AddressUnrestricted(account);
    }

    // Function to check transfer restrictions
    function _checkTransferRestrictions(address sender, address recipient, uint256 amount) internal view {
        require(!_blacklisted[sender], "RestrictedSecurityTokenContract: sender is blacklisted");
        require(!_blacklisted[recipient], "RestrictedSecurityTokenContract: recipient is blacklisted");
        require(_whitelisted[sender], "RestrictedSecurityTokenContract: sender is not whitelisted");
        require(_whitelisted[recipient], "RestrictedSecurityTokenContract: recipient is not whitelisted");
        require(!_restricted[sender], "RestrictedSecurityTokenContract: sender is restricted from transfers");
    }

    // Function to get transfer restriction message code
    function detectTransferRestriction(address sender, address recipient, uint256 amount) public view returns (uint8) {
        if (_blacklisted[sender]) {
            return 1; // Sender is blacklisted
        }
        if (_blacklisted[recipient]) {
            return 2; // Recipient is blacklisted
        }
        if (!_whitelisted[sender]) {
            return 3; // Sender is not whitelisted
        }
        if (!_whitelisted[recipient]) {
            return 4; // Recipient is not whitelisted
        }
        if (_restricted[sender]) {
            return 5; // Sender is restricted from transfers
        }
        return 0; // No restriction
    }

    // Function to get transfer restriction message text
    function messageForTransferRestriction(uint8 restrictionCode) public pure returns (string memory) {
        if (restrictionCode == 1) {
            return "Sender is blacklisted";
        }
        if (restrictionCode == 2) {
            return "Recipient is blacklisted";
        }
        if (restrictionCode == 3) {
            return "Sender is not whitelisted";
        }
        if (restrictionCode == 4) {
            return "Recipient is not whitelisted";
        }
        if (restrictionCode == 5) {
            return "Sender is restricted from transfers";
        }
        return "No restriction";
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
