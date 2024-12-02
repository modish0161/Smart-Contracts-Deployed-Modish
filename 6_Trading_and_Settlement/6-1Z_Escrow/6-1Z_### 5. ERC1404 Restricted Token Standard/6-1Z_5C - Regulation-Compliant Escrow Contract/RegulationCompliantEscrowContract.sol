// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IERC1404.sol";

/**
 * @title RegulationCompliantEscrowContract
 * @dev Escrow contract for holding and releasing restricted tokens based on regulatory compliance.
 */
contract RegulationCompliantEscrowContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Address for address;

    IERC1404 public restrictedToken;
    address public complianceAuthority;

    struct Escrow {
        address sender;
        address recipient;
        uint256 amount;
        uint256 releaseTime;
        bool isClaimed;
        bool isApproved;
    }

    uint256 public nextEscrowId;
    mapping(uint256 => Escrow) public escrows;
    mapping(address => uint256[]) public userEscrows;

    event TokensEscrowed(uint256 indexed escrowId, address indexed sender, address indexed recipient, uint256 amount, uint256 releaseTime);
    event TokensClaimed(uint256 indexed escrowId, address indexed recipient, uint256 amount);
    event EscrowApproved(uint256 indexed escrowId);
    event ComplianceAuthorityChanged(address indexed newAuthority);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);

    modifier onlyAuthorized(address account) {
        require(restrictedToken.detectTransferRestriction(account, account) == 0, "Account is not authorized");
        _;
    }

    modifier onlyComplianceAuthority() {
        require(msg.sender == complianceAuthority, "Caller is not the compliance authority");
        _;
    }

    constructor(address _restrictedToken, address _complianceAuthority) {
        require(_restrictedToken != address(0), "Invalid token address");
        require(_complianceAuthority != address(0), "Invalid compliance authority address");
        restrictedToken = IERC1404(_restrictedToken);
        complianceAuthority = _complianceAuthority;
    }

    /**
     * @dev Escrow tokens for a specified recipient.
     * @param recipient Address of the recipient.
     * @param amount Amount of tokens to be escrowed.
     * @param releaseTime Time when the tokens can be claimed.
     */
    function escrowTokens(address recipient, uint256 amount, uint256 releaseTime) external whenNotPaused onlyAuthorized(msg.sender) nonReentrant {
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than zero");
        require(releaseTime > block.timestamp, "Release time must be in the future");
        require(restrictedToken.detectTransferRestriction(msg.sender, recipient) == 0, "Transfer restricted");

        uint256 escrowId = nextEscrowId++;
        escrows[escrowId] = Escrow({
            sender: msg.sender,
            recipient: recipient,
            amount: amount,
            releaseTime: releaseTime,
            isClaimed: false,
            isApproved: false
        });
        userEscrows[recipient].push(escrowId);

        restrictedToken.transferFrom(msg.sender, address(this), amount);

        emit TokensEscrowed(escrowId, msg.sender, recipient, amount, releaseTime);
    }

    /**
     * @dev Approve the escrow for release once regulatory checks are satisfied.
     * @param escrowId ID of the escrow to be approved.
     */
    function approveEscrow(uint256 escrowId) external onlyComplianceAuthority {
        Escrow storage escrow = escrows[escrowId];
        require(!escrow.isApproved, "Escrow already approved");
        require(restrictedToken.detectTransferRestriction(address(this), escrow.recipient) == 0, "Recipient is not compliant");

        escrow.isApproved = true;

        emit EscrowApproved(escrowId);
    }

    /**
     * @dev Claim escrowed tokens.
     * @param escrowId ID of the escrow to be claimed.
     */
    function claimTokens(uint256 escrowId) external nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.recipient == msg.sender, "Caller is not the recipient");
        require(!escrow.isClaimed, "Tokens already claimed");
        require(escrow.releaseTime <= block.timestamp, "Tokens are not yet available for release");
        require(escrow.isApproved, "Escrow not approved");

        escrow.isClaimed = true;
        restrictedToken.transfer(msg.sender, escrow.amount);

        emit TokensClaimed(escrowId, msg.sender, escrow.amount);
    }

    /**
     * @dev Set a new compliance authority.
     * @param _complianceAuthority Address of the new compliance authority.
     */
    function setComplianceAuthority(address _complianceAuthority) external onlyOwner {
        require(_complianceAuthority != address(0), "Invalid compliance authority address");
        complianceAuthority = _complianceAuthority;
        emit ComplianceAuthorityChanged(_complianceAuthority);
    }

    /**
     * @dev Emergency withdrawal of tokens from the contract by the owner.
     */
    function emergencyWithdraw() external onlyOwner whenPaused nonReentrant {
        uint256 contractBalance = restrictedToken.balanceOf(address(this));
        require(contractBalance > 0, "No funds to withdraw");

        restrictedToken.transfer(msg.sender, contractBalance);

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
     * @dev Returns all escrows for a specific user.
     * @param user Address of the user.
     */
    function getUserEscrows(address user) external view returns (uint256[] memory) {
        return userEscrows[user];
    }
}

