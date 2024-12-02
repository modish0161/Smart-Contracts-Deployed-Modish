// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title Fungible Real Estate Tokenization Contract
/// @notice Tokenizes fractional ownership of real estate properties using the ERC20 standard.
/// @dev The contract includes compliance measures, advanced security, and modularity for future upgrades.
contract FungibleRealEstateToken is ERC20, Ownable, AccessControl, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // Define roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant REGULATOR_ROLE = keccak256("REGULATOR_ROLE");

    // Mapping for whitelisted addresses
    mapping(address => bool) private _whitelisted;

    // Mapping for vesting details
    mapping(address => uint256) private _vestedAmount;
    mapping(address => uint256) private _vestingEndTime;

    // Events
    event InvestorWhitelisted(address indexed investor);
    event InvestorRemoved(address indexed investor);
    event TokensVested(address indexed investor, uint256 amount, uint256 vestingEndTime);

    /// @dev Constructor that initializes the ERC20 token with name and symbol
    /// @param name Token name
    /// @param symbol Token symbol
    /// @param initialSupply Initial supply of tokens
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _mint(msg.sender, initialSupply);
    }

    /// @notice Adds an investor to the whitelist
    /// @param investor Address of the investor
    /// @dev Only ADMIN_ROLE can whitelist investors
    function addWhitelistedInvestor(address investor) external onlyRole(ADMIN_ROLE) {
        require(!_whitelisted[investor], "Investor already whitelisted");
        _whitelisted[investor] = true;
        emit InvestorWhitelisted(investor);
    }

    /// @notice Removes an investor from the whitelist
    /// @param investor Address of the investor
    /// @dev Only ADMIN_ROLE can remove investors from the whitelist
    function removeWhitelistedInvestor(address investor) external onlyRole(ADMIN_ROLE) {
        require(_whitelisted[investor], "Investor not whitelisted");
        _whitelisted[investor] = false;
        emit InvestorRemoved(investor);
    }

    /// @notice Checks if an investor is whitelisted
    /// @param investor Address of the investor
    /// @return Boolean indicating if the investor is whitelisted
    function isWhitelisted(address investor) public view returns (bool) {
        return _whitelisted[investor];
    }

    /// @notice Mints tokens to a specified address
    /// @param to Address to receive the minted tokens
    /// @param amount Number of tokens to mint
    /// @dev Only ADMIN_ROLE can mint tokens and recipient must be whitelisted
    function mint(address to, uint256 amount) external onlyRole(ADMIN_ROLE) nonReentrant whenNotPaused {
        require(_whitelisted[to], "Recipient must be whitelisted");
        _mint(to, amount);
    }

    /// @notice Burns tokens from a specified address
    /// @param from Address to burn the tokens from
    /// @param amount Number of tokens to burn
    /// @dev Only ADMIN_ROLE can burn tokens from whitelisted investors
    function burn(address from, uint256 amount) external onlyRole(ADMIN_ROLE) nonReentrant whenNotPaused {
        require(_whitelisted[from], "Address must be whitelisted");
        _burn(from, amount);
    }

    /// @notice Function to set vesting schedule for an investor
    /// @param investor Address of the investor
    /// @param amount Amount of tokens to vest
    /// @param vestingEndTime Vesting end time in UNIX timestamp
    /// @dev Only ADMIN_ROLE can set vesting schedule for investors
    function setVestingSchedule(address investor, uint256 amount, uint256 vestingEndTime) external onlyRole(ADMIN_ROLE) whenNotPaused {
        require(_whitelisted[investor], "Investor must be whitelisted");
        _vestedAmount[investor] = amount;
        _vestingEndTime[investor] = vestingEndTime;
        emit TokensVested(investor, amount, vestingEndTime);
    }

    /// @notice Gets the vesting schedule for an investor
    /// @param investor Address of the investor
    /// @return (amount, vestingEndTime) Number of vested tokens and the vesting end time
    function getVestingSchedule(address investor) external view returns (uint256, uint256) {
        return (_vestedAmount[investor], _vestingEndTime[investor]);
    }

    /// @notice Function to transfer tokens with vesting check
    /// @param recipient Address of the recipient
    /// @param amount Number of tokens to transfer
    /// @dev Overridden transfer function to check for vesting conditions
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_whitelisted[msg.sender], "Sender must be whitelisted");
        require(_whitelisted[recipient], "Recipient must be whitelisted");
        require(_vestingEndTime[msg.sender] <= block.timestamp, "Tokens are still vested");
        return super.transfer(recipient, amount);
    }

    /// @notice Pauses all token transfers
    /// @dev Only ADMIN_ROLE can pause the contract
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses all token transfers
    /// @dev Only ADMIN_ROLE can unpause the contract
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @dev Override for ERC20 transfer with pause functionality
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, amount);
    }

    /// @dev Override required by Solidity for multiple inheritance
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
