// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1400/ERC1400.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MutualFundTokenIssuance is ERC1400, Ownable, Pausable, ReentrancyGuard, AccessControl {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Variables for the token issuance
    uint256 public tokenPrice;
    uint256 public minInvestment;
    uint256 public maxInvestment;
    uint256 public totalRaised;
    bool public saleActive;

    // Whitelist mapping to track KYC approved investors
    mapping(address => bool) public whitelistedInvestors;

    // Events
    event TokensIssued(address indexed investor, uint256 amount);
    event SaleStarted();
    event SaleEnded();
    event InvestorWhitelisted(address indexed investor);
    event InvestmentReceived(address indexed investor, uint256 amount);

    modifier onlyIssuer() {
        require(hasRole(ISSUER_ROLE, msg.sender), "Caller is not an issuer");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint256 _tokenPrice,
        uint256 _minInvestment,
        uint256 _maxInvestment
    )
        ERC1400(name, symbol, new address )
    {
        tokenPrice = _tokenPrice;
        minInvestment = _minInvestment;
        maxInvestment = _maxInvestment;
        saleActive = false;
        _mint(msg.sender, initialSupply, "", "");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(ISSUER_ROLE, msg.sender);
    }

    // Whitelist investor after KYC approval
    function whitelistInvestor(address investor) external onlyIssuer {
        require(investor != address(0), "Invalid address");
        whitelistedInvestors[investor] = true;
        emit InvestorWhitelisted(investor);
    }

    // Start token sale
    function startSale() external onlyOwner {
        require(!saleActive, "Sale is already active");
        saleActive = true;
        emit SaleStarted();
    }

    // End token sale
    function endSale() external onlyOwner {
        require(saleActive, "Sale is not active");
        saleActive = false;
        emit SaleEnded();
    }

    // Invest function to buy tokens
    function invest() external payable nonReentrant whenNotPaused {
        require(saleActive, "Sale is not active");
        require(whitelistedInvestors[msg.sender], "Investor is not whitelisted");
        require(msg.value >= minInvestment && msg.value <= maxInvestment, "Investment out of bounds");

        uint256 tokenAmount = (msg.value * 10**decimals()) / tokenPrice;
        _mint(msg.sender, tokenAmount, "", "");

        totalRaised += msg.value;

        emit InvestmentReceived(msg.sender, msg.value);
        emit TokensIssued(msg.sender, tokenAmount);
    }

    // Withdraw funds collected in the contract
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);
    }

    // Fallback function to handle direct ETH transfers
    receive() external payable {
        invest();
    }

    // Pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    // Transfer Ownership Override
    function transferOwnership(address newOwner) public override onlyOwner {
        _setupRole(ADMIN_ROLE, newOwner);
        _setupRole(ISSUER_ROLE, newOwner);
        _setupRole(DEFAULT_ADMIN_ROLE, newOwner);
        super.transferOwnership(newOwner);
    }
}
