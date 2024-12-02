// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC4626/IERC4626.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title YieldDrivenEscrowContract
 * @dev Escrow contract for holding ERC4626 yield-generating vault shares until conditions are met.
 */
contract YieldDrivenEscrowContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Address for address;

    IERC4626 public vaultToken;

    struct Escrow {
        address depositor;
        address beneficiary;
        uint256 shares;
        uint256 principal;
        uint256 yield;
        uint256 releaseTime;
        bool isClaimed;
        bool isApproved;
    }

    uint256 public nextEscrowId;
    mapping(uint256 => Escrow) public escrows;
    mapping(address => uint256[]) public userEscrows;

    event SharesEscrowed(uint256 indexed escrowId, address indexed depositor, address indexed beneficiary, uint256 shares, uint256 principal, uint256 releaseTime);
    event SharesClaimed(uint256 indexed escrowId, address indexed beneficiary, uint256 principal, uint256 yield);
    event EscrowApproved(uint256 indexed escrowId);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);

    modifier onlyAuthorized(address account) {
        require(vaultToken.maxDeposit(account) > 0, "Account is not authorized to hold vault shares");
        _;
    }

    modifier onlyDepositor(uint256 escrowId) {
        require(escrows[escrowId].depositor == msg.sender, "Caller is not the depositor");
        _;
    }

    modifier onlyBeneficiary(uint256 escrowId) {
        require(escrows[escrowId].beneficiary == msg.sender, "Caller is not the beneficiary");
        _;
    }

    constructor(address _vaultToken) {
        require(_vaultToken != address(0), "Invalid vault token address");
        vaultToken = IERC4626(_vaultToken);
    }

    /**
     * @dev Escrow vault shares for a specified beneficiary.
     * @param beneficiary Address of the beneficiary.
     * @param shares Amount of vault shares to be escrowed.
     * @param releaseTime Time when the shares can be claimed.
     */
    function escrowShares(address beneficiary, uint256 shares, uint256 releaseTime) external whenNotPaused onlyAuthorized(msg.sender) nonReentrant {
        require(beneficiary != address(0), "Invalid beneficiary address");
        require(shares > 0, "Shares must be greater than zero");
        require(releaseTime > block.timestamp, "Release time must be in the future");

        uint256 principal = vaultToken.previewRedeem(shares);
        uint256 escrowId = nextEscrowId++;
        escrows[escrowId] = Escrow({
            depositor: msg.sender,
            beneficiary: beneficiary,
            shares: shares,
            principal: principal,
            yield: 0,
            releaseTime: releaseTime,
            isClaimed: false,
            isApproved: false
        });
        userEscrows[beneficiary].push(escrowId);

        vaultToken.transferFrom(msg.sender, address(this), shares);

        emit SharesEscrowed(escrowId, msg.sender, beneficiary, shares, principal, releaseTime);
    }

    /**
     * @dev Approve the escrow for release once the conditions are met.
     * @param escrowId ID of the escrow to be approved.
     */
    function approveEscrow(uint256 escrowId) external onlyOwner {
        Escrow storage escrow = escrows[escrowId];
        require(!escrow.isApproved, "Escrow already approved");

        escrow.isApproved = true;

        emit EscrowApproved(escrowId);
    }

    /**
     * @dev Claim escrowed shares and accrued yield.
     * @param escrowId ID of the escrow to be claimed.
     */
    function claimShares(uint256 escrowId) external nonReentrant onlyBeneficiary(escrowId) {
        Escrow storage escrow = escrows[escrowId];
        require(!escrow.isClaimed, "Shares already claimed");
        require(escrow.releaseTime <= block.timestamp, "Shares are not yet available for release");
        require(escrow.isApproved, "Escrow not approved");

        escrow.isClaimed = true;
        uint256 currentBalance = vaultToken.previewRedeem(escrow.shares);
        escrow.yield = currentBalance.sub(escrow.principal);

        vaultToken.transfer(msg.sender, escrow.shares);

        emit SharesClaimed(escrowId, msg.sender, escrow.principal, escrow.yield);
    }

    /**
     * @dev Emergency withdrawal of vault shares from the contract by the owner.
     */
    function emergencyWithdraw() external onlyOwner whenPaused nonReentrant {
        uint256 contractBalance = vaultToken.balanceOf(address(this));
        require(contractBalance > 0, "No shares to withdraw");

        vaultToken.transfer(msg.sender, contractBalance);

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
