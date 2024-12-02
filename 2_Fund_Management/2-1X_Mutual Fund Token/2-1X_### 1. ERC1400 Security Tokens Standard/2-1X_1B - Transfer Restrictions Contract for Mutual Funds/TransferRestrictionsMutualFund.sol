// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1400/ERC1400.sol";

contract TransferRestrictionsMutualFund is ERC1400, Ownable, Pausable, ReentrancyGuard, AccessControl {
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");
    bytes32 public constant INVESTOR_ROLE = keccak256("INVESTOR_ROLE");

    mapping(address => bool) private whitelistedInvestors;
    mapping(address => bool) private blacklistedInvestors;

    event InvestorWhitelisted(address indexed investor);
    event InvestorBlacklisted(address indexed investor);
    event TransferAttemptBlocked(address indexed from, address indexed to, uint256 amount);

    modifier onlyCompliance() {
        require(hasRole(COMPLIANCE_ROLE, msg.sender), "Caller is not the compliance officer");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    )
        ERC1400(name, symbol, new address )
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_ROLE, msg.sender);
        _mint(msg.sender, initialSupply, "", "");
    }

    // Whitelist investor after KYC approval
    function whitelistInvestor(address investor) external onlyCompliance {
        require(investor != address(0), "Invalid address");
        whitelistedInvestors[investor] = true;
        emit InvestorWhitelisted(investor);
    }

    // Blacklist investor for non-compliance
    function blacklistInvestor(address investor) external onlyCompliance {
        require(investor != address(0), "Invalid address");
        blacklistedInvestors[investor] = true;
        emit InvestorBlacklisted(investor);
    }

    // Override ERC1400 transfer function to add compliance checks
    function _transferWithData(
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal override whenNotPaused {
        require(whitelistedInvestors[from], "Sender not whitelisted");
        require(whitelistedInvestors[to], "Recipient not whitelisted");
        require(!blacklistedInvestors[from], "Sender is blacklisted");
        require(!blacklistedInvestors[to], "Recipient is blacklisted");
        
        super._transferWithData(from, to, value, data);
    }

    // Transfer ownership override to ensure role setup for new owner
    function transferOwnership(address newOwner) public override onlyOwner {
        _setupRole(COMPLIANCE_ROLE, newOwner);
        super.transferOwnership(newOwner);
    }

    // Pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    // Check if an investor is whitelisted
    function isWhitelisted(address investor) external view returns (bool) {
        return whitelistedInvestors[investor];
    }

    // Check if an investor is blacklisted
    function isBlacklisted(address investor) external view returns (bool) {
        return blacklistedInvestors[investor];
    }
}
