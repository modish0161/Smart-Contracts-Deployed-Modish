// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title AnonymousEscrowContract
 * @dev Privacy-preserving escrow contract using AnonCreds concept with Merkle Proofs for verification.
 */
contract AnonymousEscrowContract is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Address for address;

    struct Escrow {
        bytes32 hashedParticipant; // Hashed identifier for the participant
        bytes32 merkleRoot; // Merkle root for verifying identity without revealing details
        uint256 amount; // Amount held in escrow
        uint256 releaseTime; // Time when funds can be released
        bool isReleased; // Status of fund release
    }

    mapping(uint256 => Escrow) public escrows;
    uint256 public nextEscrowId;
    uint256 public serviceFeePercentage = 1; // 1% service fee

    event FundsDeposited(
        uint256 indexed escrowId,
        bytes32 indexed hashedParticipant,
        uint256 amount,
        uint256 releaseTime
    );
    event FundsReleased(
        uint256 indexed escrowId,
        bytes32 indexed hashedParticipant,
        uint256 amount
    );
    event EscrowCancelled(uint256 indexed escrowId, uint256 amountRefunded);
    event ServiceFeeUpdated(uint256 newFeePercentage);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);

    modifier onlyParticipant(uint256 escrowId, bytes32[] calldata merkleProof) {
        require(
            _verifyMerkleProof(escrowId, merkleProof),
            "Caller is not authorized or invalid proof"
        );
        _;
    }

    /**
     * @dev Deposit funds into the escrow contract with a hashed participant identifier and a merkle root for privacy-preserving verification.
     * @param hashedParticipant The hashed identifier of the participant.
     * @param merkleRoot The merkle root for verifying the participant.
     * @param releaseTime The time when the funds can be released.
     */
    function depositFunds(
        bytes32 hashedParticipant,
        bytes32 merkleRoot,
        uint256 releaseTime
    ) external payable whenNotPaused nonReentrant {
        require(hashedParticipant != bytes32(0), "Invalid hashed participant");
        require(merkleRoot != bytes32(0), "Invalid merkle root");
        require(
            releaseTime > block.timestamp,
            "Release time must be in the future"
        );
        require(msg.value > 0, "Escrow amount must be greater than zero");

        uint256 escrowId = nextEscrowId++;
        escrows[escrowId] = Escrow({
            hashedParticipant: hashedParticipant,
            merkleRoot: merkleRoot,
            amount: msg.value,
            releaseTime: releaseTime,
            isReleased: false
        });

        emit FundsDeposited(escrowId, hashedParticipant, msg.value, releaseTime);
    }

    /**
     * @dev Release the escrowed funds to the participant using a valid Merkle proof.
     * @param escrowId ID of the escrow to be released.
     * @param merkleProof Array of the Merkle proof.
     */
    function releaseFunds(uint256 escrowId, bytes32[] calldata merkleProof)
        external
        nonReentrant
        onlyParticipant(escrowId, merkleProof)
    {
        Escrow storage escrow = escrows[escrowId];
        require(!escrow.isReleased, "Funds already released");
        require(
            escrow.releaseTime <= block.timestamp,
            "Funds are not yet available for release"
        );

        escrow.isReleased = true;

        uint256 serviceFee = escrow.amount.mul(serviceFeePercentage).div(100);
        uint256 releaseAmount = escrow.amount.sub(serviceFee);

        // Transfer funds to the participant
        (bool success, ) = msg.sender.call{value: releaseAmount}("");
        require(success, "Transfer failed");

        // Transfer service fee to the contract owner
        (success, ) = owner().call{value: serviceFee}("");
        require(success, "Service fee transfer failed");

        emit FundsReleased(escrowId, escrow.hashedParticipant, releaseAmount);
    }

    /**
     * @dev Cancel the escrow and refund the funds to the contract owner.
     * @param escrowId ID of the escrow to be cancelled.
     */
    function cancelEscrow(uint256 escrowId) external onlyOwner whenPaused {
        Escrow storage escrow = escrows[escrowId];
        require(!escrow.isReleased, "Funds already released");

        uint256 refundAmount = escrow.amount;
        escrow.amount = 0;

        (bool success, ) = owner().call{value: refundAmount}("");
        require(success, "Refund transfer failed");

        emit EscrowCancelled(escrowId, refundAmount);
    }

    /**
     * @dev Update the service fee percentage.
     * @param newFeePercentage New service fee percentage.
     */
    function updateServiceFee(uint256 newFeePercentage) external onlyOwner {
        require(
            newFeePercentage <= 10,
            "Service fee must be less than or equal to 10%"
        );
        serviceFeePercentage = newFeePercentage;

        emit ServiceFeeUpdated(newFeePercentage);
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
     * @dev Verify the Merkle proof for the participant.
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
     * @dev Receive function to allow contract to accept ETH deposits.
     */
    receive() external payable {}

    /**
     * @dev Fallback function.
     */
    fallback() external payable {}
}
