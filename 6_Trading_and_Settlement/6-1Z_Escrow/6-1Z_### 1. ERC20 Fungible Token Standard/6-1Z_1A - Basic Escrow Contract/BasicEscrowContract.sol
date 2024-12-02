// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BasicEscrowContract is Ownable, ReentrancyGuard {
    // Events
    event FundsDeposited(address indexed depositor, address indexed beneficiary, uint256 amount, uint256 releaseTime);
    event FundsReleased(address indexed beneficiary, uint256 amount);
    event FundsRefunded(address indexed depositor, uint256 amount);

    // Escrow struct to hold details of each escrow
    struct Escrow {
        address depositor;
        address beneficiary;
        uint256 amount;
        uint256 releaseTime;
        bool isReleased;
    }

    // ERC20 token used for escrow
    IERC20 public escrowToken;

    // Mapping of escrow ID to Escrow details
    mapping(bytes32 => Escrow) public escrows;

    // Modifier to check if the escrow can be released
    modifier canBeReleased(bytes32 _escrowId) {
        require(block.timestamp >= escrows[_escrowId].releaseTime, "Release time not reached");
        require(escrows[_escrowId].amount > 0, "No funds to release");
        require(!escrows[_escrowId].isReleased, "Funds already released");
        _;
    }

    constructor(IERC20 _tokenAddress) {
        escrowToken = _tokenAddress;
    }

    /**
     * @dev Deposit funds into the escrow contract.
     * @param _escrowId The unique ID for the escrow.
     * @param _beneficiary The address to receive the funds upon release.
     * @param _amount The amount of ERC20 tokens to deposit.
     * @param _releaseTime The time when funds can be released.
     */
    function depositFunds(
        bytes32 _escrowId,
        address _beneficiary,
        uint256 _amount,
        uint256 _releaseTime
    ) external nonReentrant {
        require(_beneficiary != address(0), "Beneficiary address cannot be zero");
        require(_amount > 0, "Amount must be greater than zero");
        require(_releaseTime > block.timestamp, "Release time must be in the future");
        require(escrows[_escrowId].amount == 0, "Escrow ID already used");

        // Transfer tokens from depositor to contract
        require(escrowToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        // Store escrow details
        escrows[_escrowId] = Escrow({
            depositor: msg.sender,
            beneficiary: _beneficiary,
            amount: _amount,
            releaseTime: _releaseTime,
            isReleased: false
        });

        emit FundsDeposited(msg.sender, _beneficiary, _amount, _releaseTime);
    }

    /**
     * @dev Release funds to the beneficiary.
     * @param _escrowId The unique ID for the escrow.
     */
    function releaseFunds(bytes32 _escrowId) external nonReentrant canBeReleased(_escrowId) {
        Escrow storage escrow = escrows[_escrowId];
        
        // Mark escrow as released
        escrow.isReleased = true;

        // Transfer funds to beneficiary
        require(escrowToken.transfer(escrow.beneficiary, escrow.amount), "Token transfer failed");

        emit FundsReleased(escrow.beneficiary, escrow.amount);
    }

    /**
     * @dev Refund funds to the depositor if the escrow conditions are not met.
     * @param _escrowId The unique ID for the escrow.
     */
    function refundFunds(bytes32 _escrowId) external nonReentrant {
        Escrow storage escrow = escrows[_escrowId];
        require(msg.sender == escrow.depositor, "Only depositor can request refund");
        require(!escrow.isReleased, "Funds already released");

        // Transfer funds back to depositor
        uint256 amount = escrow.amount;
        escrow.amount = 0;

        require(escrowToken.transfer(escrow.depositor, amount), "Token transfer failed");

        emit FundsRefunded(escrow.depositor, amount);
    }

    /**
     * @dev View details of a specific escrow.
     * @param _escrowId The unique ID for the escrow.
     * @return The escrow details.
     */
    function viewEscrow(bytes32 _escrowId) external view returns (address, address, uint256, uint256, bool) {
        Escrow storage escrow = escrows[_escrowId];
        return (escrow.depositor, escrow.beneficiary, escrow.amount, escrow.releaseTime, escrow.isReleased);
    }
}
