// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FungibleMutualFundToken is ERC20, Ownable, AccessControl, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FUND_MANAGER_ROLE = keccak256("FUND_MANAGER_ROLE");

    uint256 public initialSupply;
    uint256 public tokenPrice; // Token price in wei
    uint256 public fundraisingGoal;
    uint256 public totalRaised;
    bool public saleActive = false;

    mapping(address => bool) public whitelisted;

    event TokensPurchased(address indexed purchaser, uint256 amount);
    event SaleStarted(uint256 tokenPrice, uint256 fundraisingGoal);
    event SaleEnded(uint256 totalRaised);

    constructor(
        string memory name,
        string memory symbol,
        uint256 _initialSupply,
        uint256 _tokenPrice,
        uint256 _fundraisingGoal
    ) ERC20(name, symbol) {
        initialSupply = _initialSupply;
        tokenPrice = _tokenPrice;
        fundraisingGoal = _fundraisingGoal;

        _mint(address(this), _initialSupply); // Mint initial supply to contract
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(FUND_MANAGER_ROLE, msg.sender);
    }

    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "Address not whitelisted");
        _;
    }

    // Start the token sale
    function startSale() external onlyRole(ADMIN_ROLE) {
        require(!saleActive, "Sale already active");
        saleActive = true;
        emit SaleStarted(tokenPrice, fundraisingGoal);
    }

    // End the token sale
    function endSale() external onlyRole(ADMIN_ROLE) {
        require(saleActive, "Sale not active");
        saleActive = false;
        emit SaleEnded(totalRaised);
    }

    // Purchase tokens during the sale
    function purchaseTokens() external payable onlyWhitelisted whenNotPaused nonReentrant {
        require(saleActive, "Sale not active");
        require(msg.value > 0, "No Ether sent");

        uint256 tokensToBuy = msg.value.div(tokenPrice);
        require(tokensToBuy > 0, "Insufficient Ether for token purchase");
        require(balanceOf(address(this)) >= tokensToBuy, "Not enough tokens available");

        totalRaised = totalRaised.add(msg.value);
        _transfer(address(this), msg.sender, tokensToBuy);

        emit TokensPurchased(msg.sender, tokensToBuy);
    }

    // Withdraw Ether raised during the sale
    function withdrawFunds() external onlyRole(ADMIN_ROLE) nonReentrant {
        require(address(this).balance > 0, "No funds available for withdrawal");
        payable(owner()).transfer(address(this).balance);
    }

    // Whitelist management
    function addToWhitelist(address account) external onlyRole(ADMIN_ROLE) {
        require(account != address(0), "Invalid address");
        whitelisted[account] = true;
    }

    function removeFromWhitelist(address account) external onlyRole(ADMIN_ROLE) {
        require(account != address(0), "Invalid address");
        whitelisted[account] = false;
    }

    // Pause and unpause the contract
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // Emergency withdraw function for owner
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available for withdrawal");
        payable(owner()).transfer(balance);
    }

    // Fallback function to receive Ether
    receive() external payable {
        if (saleActive) {
            purchaseTokens();
        }
    }
}
