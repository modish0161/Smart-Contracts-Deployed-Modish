// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

/**
 * @title DividendEscrowContract
 * @dev Escrow contract for holding and distributing security token dividends.
 */
contract DividendEscrowContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Address for address;

    IERC1400 public securityToken;

    struct Dividend {
        uint256 amount;
        uint256 releaseTime;
        bool isDistributed;
    }

    struct Escrow {
        uint256 dividendId;
        address shareholder;
        uint256 amount;
        bool isClaimed;
    }

    uint256 public nextDividendId;
    uint256 public nextEscrowId;
    mapping(uint256 => Dividend) public dividends;
    mapping(uint256 => Escrow) public escrows;
    mapping(address => uint256[]) public shareholderEscrows;

    event DividendCreated(uint256 indexed dividendId, uint256 amount, uint256 releaseTime);
    event DividendEscrowed(uint256 indexed escrowId, uint256 indexed dividendId, address indexed shareholder, uint256 amount);
    event DividendClaimed(uint256 indexed escrowId, address indexed shareholder, uint256 amount);
    event DividendRefunded(uint256 indexed dividendId, uint256 amount);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);

    modifier onlyWhitelisted(address account) {
        require(securityToken.isOperatorFor(account, account), "Account is not whitelisted");
        _;
    }

    constructor(address _securityToken) {
        require(_securityToken != address(0), "Invalid security token address");
        securityToken = IERC1400(_securityToken);
    }

    /**
     * @dev Create a new dividend to be held in escrow.
     * @param amount Amount of tokens to be distributed as dividends.
     * @param releaseTime Time when the dividends can be released.
     */
    function createDividend(uint256 amount, uint256 releaseTime) external onlyOwner whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(releaseTime > block.timestamp, "Release time must be in the future");

        uint256 dividendId = nextDividendId++;
        dividends[dividendId] = Dividend({
            amount: amount,
            releaseTime: releaseTime,
            isDistributed: false
        });

        emit DividendCreated(dividendId, amount, releaseTime);
    }

    /**
     * @dev Escrow dividend for a shareholder.
     * @param dividendId ID of the dividend to be escrowed.
     * @param shareholder Address of the shareholder.
     * @param amount Amount of dividends to be escrowed.
     */
    function escrowDividend(uint256 dividendId, address shareholder, uint256 amount) external onlyOwner onlyWhitelisted(shareholder) whenNotPaused nonReentrant {
        require(dividends[dividendId].amount > 0, "Invalid dividend ID");
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= dividends[dividendId].amount, "Amount exceeds available dividends");

        uint256 escrowId = nextEscrowId++;
        escrows[escrowId] = Escrow({
            dividendId: dividendId,
            shareholder: shareholder,
            amount: amount,
            isClaimed: false
        });
        shareholderEscrows[shareholder].push(escrowId);

        dividends[dividendId].amount = dividends[dividendId].amount.sub(amount);

        emit DividendEscrowed(escrowId, dividendId, shareholder, amount);
    }

    /**
     * @dev Claim escrowed dividend by the shareholder.
     * @param escrowId ID of the escrow to be claimed.
     */
    function claimDividend(uint256 escrowId) external nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.shareholder == msg.sender, "Caller is not the shareholder");
        require(!escrow.isClaimed, "Dividend already claimed");
        require(dividends[escrow.dividendId].releaseTime <= block.timestamp, "Dividend is not yet available for release");

        escrow.isClaimed = true;
        securityToken.operatorTransferByPartition(bytes32(0), address(this), msg.sender, escrow.amount, "", "");

        emit DividendClaimed(escrowId, msg.sender, escrow.amount);
    }

    /**
     * @dev Refund unclaimed dividends back to the contract owner.
     * @param dividendId ID of the dividend to be refunded.
     */
    function refundDividend(uint256 dividendId) external onlyOwner nonReentrant {
        Dividend storage dividend = dividends[dividendId];
        require(dividend.amount > 0, "No dividends to refund");
        require(!dividend.isDistributed, "Dividends already distributed");

        dividend.isDistributed = true;
        securityToken.operatorTransferByPartition(bytes32(0), address(this), msg.sender, dividend.amount, "", "");

        emit DividendRefunded(dividendId, dividend.amount);
    }

    /**
     * @dev Emergency withdrawal of tokens from the contract by the owner.
     */
    function emergencyWithdraw() external onlyOwner whenPaused nonReentrant {
        uint256 contractBalance = securityToken.balanceOf(address(this));
        require(contractBalance > 0, "No funds to withdraw");

        securityToken.operatorTransferByPartition(bytes32(0), address(this), msg.sender, contractBalance, "", "");

        emit EmergencyWithdrawal(msg.sender, contractBalance);
    }

    /**
     * @dev Pause the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Returns all escrows for a specific shareholder.
     * @param shareholder Address of the shareholder.
     */
    function getShareholderEscrows(address shareholder) external view returns (uint256[] memory) {
        return shareholderEscrows[shareholder];
    }
}
