// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title PrivacyPreservingEscrowContract
 * @dev Escrow contract for holding funds while preserving the privacy of the participants using AnonCreds (Merkle Proofs).
 */
contract PrivacyPreservingEscrowContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Address for address;

    struct Escrow {
        bytes32 hashedBeneficiary; // Hashed identifier for the beneficiary
        bytes32 merkleRoot; // Merkle root to verify eligibility
        uint256 amount; // Amount in escrow
        uint256 releaseTime; // Time when funds can be released
        bool isClaimed; // Status if the escrow has been claimed
        bool isApproved; // Status if the escrow is approved for release
    }

    mapping(uint256 => Escrow) public escrows;
    mapping(bytes32 => uint256[]) public userEscrows;
    uint256 public nextEscrowId;

    event FundsDeposited(
        uint256 indexed escrowId,
        bytes32 indexed hashedBeneficiary,
        uint256 amount,
        uint256 releaseTime
    );
    event FundsClaimed(
        uint256 indexed escrowId,
        bytes32 indexed hashedBeneficiary,
        uint256 amount
    );
    event EscrowApproved(uint256 indexed escrowId);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);

    modifier onlyBeneficiary(uint256 escrowId, bytes32[] calldata merkleProof) {
        require(
            _verifyMerkleProof(escrowId, merkleProof),
            "Caller is not the beneficiary or invalid proof"
        );
        _;
    }

    /**
     * @dev Deposit funds into the escrow contract with a hashed beneficiary and a merkle root for privacy-preserving verification.
     * @param hashedBeneficiary The hashed identifier of the beneficiary.
     * @param merkleRoot The merkle root for verifying the beneficiary.
     * @param releaseTime The time when the funds can be released.
     */
    function depositFunds(
        bytes32 hashedBeneficiary,
        bytes32 merkleRoot,
        uint256 releaseTime
    ) external payable whenNotPaused nonReentrant {
        require(hashedBeneficiary != bytes32(0), "Invalid hashed beneficiary");
        require(merkleRoot != bytes32(0), "Invalid merkle root");
        require(
            releaseTime > block.timestamp,
            "Release time must be in the future"
        );
        require(msg.value > 0, "Escrow amount must be greater than zero");

        uint256 escrowId = nextEscrowId++;
        escrows[escrowId] = Escrow({
            hashedBeneficiary: hashedBeneficiary,
            merkleRoot: merkleRoot,
            amount: msg.value,
            releaseTime: releaseTime,
            isClaimed: false,
            isApproved: false
        });

        userEscrows[hashedBeneficiary].push(escrowId);

        emit FundsDeposited(escrowId, hashedBeneficiary, msg.value, releaseTime);
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
     * @dev Claim the escrowed funds using a valid Merkle proof.
     * @param escrowId ID of the escrow to be claimed.
     * @param merkleProof Array of the Merkle proof.
     */
    function claimFunds(uint256 escrowId, bytes32[] calldata merkleProof)
        external
        nonReentrant
        onlyBeneficiary(escrowId, merkleProof)
    {
        Escrow storage escrow = escrows[escrowId];
        require(!escrow.isClaimed, "Funds already claimed");
        require(
            escrow.releaseTime <= block.timestamp,
            "Funds are not yet available for release"
        );
        require(escrow.isApproved, "Escrow not approved");

        escrow.isClaimed = true;

        // Transfer funds to the beneficiary
        (bool success, ) = msg.sender.call{value: escrow.amount}("");
        require(success, "Transfer failed");

        emit FundsClaimed(escrowId, escrow.hashedBeneficiary, escrow.amount);
    }

    /**
     * @dev Emergency withdrawal of funds from the contract by the owner.
     * @param amount Amount of funds to be withdrawn.
     */
    function emergencyWithdraw(uint256 amount)
        external
        onlyOwner
        whenPaused
        nonReentrant
    {
        require(amount <= address(this).balance, "Insufficient balance");

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit EmergencyWithdrawal(msg.sender, amount);
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
     * @dev Verify the Merkle proof for the beneficiary.
     * @param escrowId ID of the escrow.
     * @param merkleProof Array of the Merkle proof.
     */
    function _verifyMerkleProof(uint256 escrowId, bytes32[] calldata merkleProof)
        internal
        view
        returns (bool)
    {
        Escrow storage escrow = escrows[escrowId];
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(merkleProof, escrow.merkleRoot, leaf);
    }

    /**
     * @dev Returns all escrows for a specific user.
     * @param userHashed Hashed identifier of the user.
     */
    function getUserEscrows(bytes32 userHashed)
        external
        view
        returns (uint256[] memory)
    {
        return userEscrows[userHashed];
    }

    /**
     * @dev Receive function to allow contract to accept ETH deposits.
     */
    receive() external payable {}

    /**
     * @dev Fallback function.
     */
    fallback() external payable {}
}
