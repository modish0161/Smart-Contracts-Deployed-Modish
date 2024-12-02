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

// LockUpPeriodContract based on ERC1400 standard
contract LockUpPeriodContract is IERC1400, Ownable, AccessControl, Pausable, ReentrancyGuard {
    // Define roles for access control
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant LOCKUP_MANAGER_ROLE = keccak256("LOCKUP_MANAGER_ROLE");

    // ERC1400 compliance details
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(bytes32 => mapping(address => uint256)) private _partitionBalances;
    mapping(address => mapping(address => uint256)) private _allowed;

    // Lock-up structure to store lock-up details for each investor
    struct LockUp {
        uint256 amount;
        uint256 releaseTime;
    }
    mapping(address => LockUp[]) private _lockUps;

    // Constructor for initial contract setup
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 initialSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _mint(msg.sender, initialSupply_);
        
        // Setup roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(LOCKUP_MANAGER_ROLE, msg.sender);
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

    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        _checkLockUp(msg.sender, amount);
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
        _checkLockUp(sender, amount);
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

    // Function to add lock-up periods for an investor
    function addLockUp(address account, uint256 amount, uint256 releaseTime) public onlyRole(LOCKUP_MANAGER_ROLE) {
        require(releaseTime > block.timestamp, "LockUpPeriodContract: release time is before current time");
        require(amount <= _balances[account], "LockUpPeriodContract: amount exceeds balance");

        _lockUps[account].push(LockUp(amount, releaseTime));
        emit LockUpAdded(account, amount, releaseTime);
    }

    // Function to remove lock-up periods for an investor
    function removeLockUp(address account, uint256 index) public onlyRole(LOCKUP_MANAGER_ROLE) {
        require(index < _lockUps[account].length, "LockUpPeriodContract: index out of bounds");

        _lockUps[account][index] = _lockUps[account][_lockUps[account].length - 1];
        _lockUps[account].pop();
        emit LockUpRemoved(account, index);
    }

    // Function to check lock-up periods before transfer
    function _checkLockUp(address account, uint256 amount) internal view {
        uint256 lockedAmount = 0;
        for (uint256 i = 0; i < _lockUps[account].length; i++) {
            if (block.timestamp < _lockUps[account][i].releaseTime) {
                lockedAmount += _lockUps[account][i].amount;
            }
        }
        require(_balances[account] - lockedAmount >= amount, "LockUpPeriodContract: amount exceeds unlocked balance");
    }

    // Pause contract functions in case of emergency
    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    // Unpause contract functions
    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // Events for lock-up management
    event LockUpAdded(address indexed account, uint256 amount, uint256 releaseTime);
    event LockUpRemoved(address indexed account, uint256 index);
}
