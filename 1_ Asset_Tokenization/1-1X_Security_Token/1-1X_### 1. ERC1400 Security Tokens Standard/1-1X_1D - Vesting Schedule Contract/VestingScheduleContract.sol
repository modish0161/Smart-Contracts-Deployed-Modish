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

// VestingScheduleContract based on ERC1400 standard
contract VestingScheduleContract is IERC1400, Ownable, AccessControl, Pausable, ReentrancyGuard {
    // Define roles for access control
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VESTING_MANAGER_ROLE = keccak256("VESTING_MANAGER_ROLE");

    // ERC1400 compliance details
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(bytes32 => mapping(address => uint256)) private _partitionBalances;
    mapping(address => mapping(address => uint256)) private _allowed;

    // Vesting structure to store vesting details for each beneficiary
    struct Vesting {
        uint256 totalAmount;      // Total amount of tokens to be vested
        uint256 releasedAmount;   // Amount of tokens already released
        uint256 startTime;        // Start time of vesting
        uint256 cliffDuration;    // Cliff duration in seconds
        uint256 vestingDuration;  // Total vesting duration in seconds
    }
    mapping(address => Vesting) private _vestingSchedules;

    // Constructor for initial contract setup
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 initialSupply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _mint(msg.sender, initialSupply_);
        
        // Setup roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(VESTING_MANAGER_ROLE, msg.sender);
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
        _releaseVestedTokens(msg.sender);
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
        _releaseVestedTokens(sender);
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

    // Function to add a vesting schedule for a beneficiary
    function addVestingSchedule(
        address beneficiary,
        uint256 totalAmount,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 vestingDuration
    ) public onlyRole(VESTING_MANAGER_ROLE) {
        require(totalAmount > 0, "VestingScheduleContract: totalAmount must be greater than 0");
        require(vestingDuration > cliffDuration, "VestingScheduleContract: vestingDuration must be greater than cliffDuration");
        
        _vestingSchedules[beneficiary] = Vesting(
            totalAmount,
            0,
            startTime,
            cliffDuration,
            vestingDuration
        );
        emit VestingScheduleAdded(beneficiary, totalAmount, startTime, cliffDuration, vestingDuration);
    }

    // Function to release vested tokens for a beneficiary
    function _releaseVestedTokens(address beneficiary) internal {
        Vesting storage vesting = _vestingSchedules[beneficiary];
        uint256 vestedAmount = _vestedAmount(beneficiary);
        uint256 releasableAmount = vestedAmount - vesting.releasedAmount;

        if (releasableAmount > 0) {
            vesting.releasedAmount = vestedAmount;
            _transfer(address(this), beneficiary, releasableAmount);
            emit TokensReleased(beneficiary, releasableAmount);
        }
    }

    // Function to calculate the vested amount for a beneficiary
    function _vestedAmount(address beneficiary) internal view returns (uint256) {
        Vesting storage vesting = _vestingSchedules[beneficiary];

        if (block.timestamp < vesting.startTime + vesting.cliffDuration) {
            return 0;
        } else if (block.timestamp >= vesting.startTime + vesting.vestingDuration) {
            return vesting.totalAmount;
        } else {
            uint256 vestingTimeElapsed = block.timestamp - (vesting.startTime + vesting.cliffDuration);
            uint256 vestingPeriod = vesting.vestingDuration - vesting.cliffDuration;
            return (vesting.totalAmount * vestingTimeElapsed) / vestingPeriod;
        }
    }

    // Pause contract functions in case of emergency
    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    // Unpause contract functions
    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // Events for vesting management
    event VestingScheduleAdded(address indexed beneficiary, uint256 totalAmount, uint256 startTime, uint256 cliffDuration, uint256 vestingDuration);
    event TokensReleased(address indexed beneficiary, uint256 amount);
}
