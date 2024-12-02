// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin libraries for ERC20 and security features
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Tokenized Bonds Contract
/// @notice This contract allows for the issuance of tokens that represent bonds, enabling fractional ownership and trading.
contract TokenizedBondsContract is ERC20, Ownable, AccessControl, Pausable, ReentrancyGuard {
    // Define roles for access control
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Bond maturity date in UNIX timestamp
    uint256 public maturityDate;

    // Event emitted when a new bond is issued
    event BondIssued(address indexed to, uint256 amount, uint256 maturityDate);

    // Event emitted when interest is paid
    event InterestPaid(address indexed to, uint256 amount);

    // Event emitted when bond principal is redeemed
    event PrincipalRedeemed(address indexed to, uint256 amount);

    /// @notice Constructor for initializing the contract
    /// @param name_ Token name
    /// @param symbol_ Token symbol
    /// @param initialSupply_ Initial supply of tokens
    /// @param maturityDate_ The maturity date of the bond in UNIX timestamp
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_,
        uint256 maturityDate_
    ) ERC20(name_, symbol_) {
        require(maturityDate_ > block.timestamp, "Maturity date must be in the future");
        maturityDate = maturityDate_;
        _mint(msg.sender, initialSupply_ * (10 ** uint256(decimals())));

        // Setup roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    /// @notice Mint new bond tokens
    /// @param to Address to receive the minted tokens
    /// @param amount Amount of tokens to mint
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) whenNotPaused {
        _mint(to, amount);
        emit BondIssued(to, amount, maturityDate);
    }

    /// @notice Pay interest to token holders
    /// @param to Address to receive the interest
    /// @param amount Amount of interest to pay
    function payInterest(address to, uint256 amount) public onlyRole(ADMIN_ROLE) whenNotPaused nonReentrant {
        require(balanceOf(to) > 0, "Address must hold bond tokens");
        _mint(to, amount);
        emit InterestPaid(to, amount);
    }

    /// @notice Redeem bond principal after maturity date
    /// @param to Address to redeem the principal
    function redeemPrincipal(address to) public onlyRole(ADMIN_ROLE) whenNotPaused nonReentrant {
        require(block.timestamp >= maturityDate, "Bonds cannot be redeemed before maturity date");
        uint256 principalAmount = balanceOf(to);
        require(principalAmount > 0, "No bonds to redeem");
        
        _burn(to, principalAmount);
        emit PrincipalRedeemed(to, principalAmount);
    }

    /// @notice Pause the contract
    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract
    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Override transfer function to include pausability
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
