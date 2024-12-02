// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract PooledAssetSettlement is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    ERC4626 public vaultToken;

    // Set of authorized participants who can trade pooled assets
    EnumerableSet.AddressSet private authorizedParticipants;

    struct Settlement {
        address participant;
        uint256 shares;
        uint256 settledAmount;
        bool isSettled;
    }

    mapping(bytes32 => Settlement) public settlements;

    event SettlementCreated(
        bytes32 indexed settlementId,
        address indexed participant,
        uint256 shares,
        uint256 settledAmount
    );

    event SettlementExecuted(
        bytes32 indexed settlementId,
        address indexed participant,
        uint256 settledAmount
    );

    modifier onlyAuthorized() {
        require(isAuthorizedParticipant(msg.sender), "Not an authorized participant");
        _;
    }

    constructor(address _vaultToken) {
        require(_vaultToken != address(0), "Invalid vault token address");
        vaultToken = ERC4626(_vaultToken);
    }

    /**
     * @dev Adds an address to the set of authorized participants.
     * @param participant The address to be added.
     */
    function addAuthorizedParticipant(address participant) external onlyOwner {
        require(participant != address(0), "Invalid address");
        authorizedParticipants.add(participant);
    }

    /**
     * @dev Removes an address from the set of authorized participants.
     * @param participant The address to be removed.
     */
    function removeAuthorizedParticipant(address participant) external onlyOwner {
        authorizedParticipants.remove(participant);
    }

    /**
     * @dev Checks if an address is an authorized participant.
     * @param participant The address to check.
     */
    function isAuthorizedParticipant(address participant) public view returns (bool) {
        return authorizedParticipants.contains(participant);
    }

    /**
     * @dev Creates a settlement agreement for a participant.
     * @param settlementId The unique identifier for the settlement.
     * @param participant The address of the participant.
     * @param shares The number of shares being settled.
     */
    function createSettlement(
        bytes32 settlementId,
        address participant,
        uint256 shares
    ) external onlyAuthorized whenNotPaused {
        require(participant != address(0), "Invalid participant address");
        require(settlements[settlementId].participant == address(0), "Settlement ID already exists");

        uint256 settledAmount = calculateSettledAmount(shares);

        settlements[settlementId] = Settlement({
            participant: participant,
            shares: shares,
            settledAmount: settledAmount,
            isSettled: false
        });

        emit SettlementCreated(settlementId, participant, shares, settledAmount);
    }

    /**
     * @dev Settles the trade by transferring the appropriate shares and amount to the participant.
     * @param settlementId The unique identifier for the settlement.
     */
    function executeSettlement(bytes32 settlementId) external nonReentrant whenNotPaused {
        Settlement storage settlement = settlements[settlementId];
        require(settlement.participant != address(0), "Settlement ID does not exist");
        require(!settlement.isSettled, "Settlement already executed");

        // Transfer the appropriate shares from the vault to the participant
        vaultToken.safeTransferFrom(address(this), settlement.participant, settlement.shares);

        // Transfer the settled amount of assets to the participant
        vaultToken.asset().safeTransfer(settlement.participant, settlement.settledAmount);

        settlement.isSettled = true;

        emit SettlementExecuted(settlementId, settlement.participant, settlement.settledAmount);
    }

    /**
     * @dev Pauses the contract, preventing settlement creation and execution.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing settlement creation and execution.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Fallback function to prevent accidental Ether transfer.
     */
    receive() external payable {
        revert("No Ether accepted");
    }

    /**
     * @dev Calculates the settled amount based on the number of shares.
     * @param shares The number of shares.
     * @return The calculated settled amount.
     */
    function calculateSettledAmount(uint256 shares) internal view returns (uint256) {
        // Placeholder logic for calculating the settled amount
        // Replace this with the actual logic based on vault's assets and share value
        return vaultToken.convertToAssets(shares);
    }
}
