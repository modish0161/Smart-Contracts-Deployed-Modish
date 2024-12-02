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
 * @title PooledAssetEscrowContract
 * @dev Escrow contract for holding ERC4626 pooled vault shares until conditions are met.
 */
contract PooledAssetEscrowContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Address for address;

    IERC4626 public vaultToken;

    struct Escrow {
        address depositor;
        address[] beneficiaries;
        uint256 shares;
        uint256[] allocations;
        uint256 releaseTime;
        bool isClaimed;
        bool isApproved;
    }

    uint256 public nextEscrowId;
    mapping(uint256 => Escrow) public escrows;
    mapping(address => uint256[]) public userEscrows;

    event SharesEscrowed(uint256 indexed escrowId, address indexed depositor, address[] beneficiaries, uint256 shares, uint256[] allocations, uint256 releaseTime);
    event SharesClaimed(uint256 indexed escrowId, address indexed beneficiary, uint256 amount);
    event EscrowApproved(uint256 indexed escrowId);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);

    modifier onlyDepositor(uint256 escrowId) {
        require(escrows[escrowId].depositor == msg.sender, "Caller is not the depositor");
        _;
    }

    modifier onlyBeneficiary(uint256 escrowId) {
        bool isBeneficiary = false;
        for (uint256 i = 0; i < escrows[escrowId].beneficiaries.length; i++) {
            if (escrows[escrowId].beneficiaries[i] == msg.sender) {
                isBeneficiary = true;
                break;
            }
        }
        require(isBeneficiary, "Caller is not a beneficiary");
        _;
    }

    constructor(address _vaultToken) {
        require(_vaultToken != address(0), "Invalid vault token address");
        vaultToken = IERC4626(_vaultToken);
    }

    /**
     * @dev Escrow vault shares for multiple beneficiaries with specified allocations.
     * @param beneficiaries Array of beneficiary addresses.
     * @param shares Amount of vault shares to be escrowed.
     * @param allocations Array of allocations corresponding to each beneficiary.
     * @param releaseTime Time when the shares can be claimed.
     */
    function escrowShares(address[] calldata beneficiaries, uint256 shares, uint256[] calldata allocations, uint256 releaseTime) external whenNotPaused nonReentrant {
        require(beneficiaries.length == allocations.length, "Beneficiaries and allocations length mismatch");
        require(beneficiaries.length > 0, "No beneficiaries specified");
        require(shares > 0, "Shares must be greater than zero");
        require(releaseTime > block.timestamp, "Release time must be in the future");

        uint256 totalAllocation;
        for (uint256 i = 0; i < allocations.length; i++) {
            totalAllocation = totalAllocation.add(allocations[i]);
        }
        require(totalAllocation == shares, "Allocations must sum up to total shares");

        uint256 escrowId = nextEscrowId++;
        escrows[escrowId] = Escrow({
            depositor: msg.sender,
            beneficiaries: beneficiaries,
            shares: shares,
            allocations: allocations,
            releaseTime: releaseTime,
            isClaimed: false,
            isApproved: false
        });
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            userEscrows[beneficiaries[i]].push(escrowId);
        }

        vaultToken.transferFrom(msg.sender, address(this), shares);

        emit SharesEscrowed(escrowId, msg.sender, beneficiaries, shares, allocations, releaseTime);
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

        for (uint256 i = 0; i < escrow.beneficiaries.length; i++) {
            if (escrow.beneficiaries[i] == msg.sender) {
                uint256 allocation = escrow.allocations[i];
                vaultToken.transfer(msg.sender, allocation);
                emit SharesClaimed(escrowId, msg.sender, allocation);
                break;
            }
        }
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
