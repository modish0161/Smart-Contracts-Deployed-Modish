// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TimeLockedEscrowContract is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // Events
    event FundsDeposited(address indexed depositor, uint256 amount, uint256 releaseTime);
    event FundsReleased(address indexed beneficiary, uint256 amount);
    event FundsRefunded(address indexed depositor, uint256 amount);

    // Escrow struct to hold details of the escrowed funds
    struct Escrow {
        uint256 amount;           // Amount of ERC20 tokens held in escrow
        uint256 releaseTime;      // Time when the escrow can be released to beneficiary
        bool isReleased;          // Flag to check if the escrow has been released
        bool isRefunded;          // Flag to check if the funds have been refunded
    }

    // ERC20 token used for escrow
    IERC20 public escrowToken;

    // Address of the depositor
    address public depositor;

    // Address of the beneficiary
    address public beneficiary;

    // Escrow details
    Escrow public escrowDetails;

    // Modifier to check if the caller is the depositor
    modifier onlyDepositor() {
        require(msg.sender == depositor, "Caller is not the depositor");
        _;
    }

    // Modifier to check if the caller is the beneficiary
    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Caller is not the beneficiary");
        _;
    }

    // Modifier to check if the escrow can be released
    modifier canRelease() {
        require(block.timestamp >= escrowDetails.releaseTime, "Release time not reached");
        require(!escrowDetails.isReleased, "Funds already released");
        require(!escrowDetails.isRefunded, "Funds already refunded");
        _;
    }

    // Modifier to check if the escrow can be refunded
    modifier canRefund() {
        require(block.timestamp >= escrowDetails.releaseTime, "Release time not reached");
        require(!escrowDetails.isReleased, "Funds already released");
        require(!escrowDetails.isRefunded, "Funds already refunded");
        _;
    }

    constructor(
        address _depositor,
        address _beneficiary,
        IERC20 _tokenAddress,
        uint256 _amount,
        uint256 _releaseTime
    ) {
        require(_depositor != address(0), "Depositor address cannot be zero");
        require(_beneficiary != address(0), "Beneficiary address cannot be zero");
        require(_amount > 0, "Amount must be greater than zero");
        require(_releaseTime > block.timestamp, "Release time must be in the future");

        depositor = _depositor;
        beneficiary = _beneficiary;
        escrowToken = _tokenAddress;

        // Initialize escrow details
        escrowDetails = Escrow({
            amount: _amount,
            releaseTime: _releaseTime,
            isReleased: false,
            isRefunded: false
        });

        // Transfer tokens from depositor to the contract
        require(escrowToken.transferFrom(depositor, address(this), _amount), "Token transfer failed");
        emit FundsDeposited(depositor, _amount, _releaseTime);
    }

    /**
     * @dev Release funds to the beneficiary.
     */
    function releaseFunds() external onlyBeneficiary canRelease nonReentrant {
        uint256 amount = escrowDetails.amount;
        escrowDetails.isReleased = true;

        require(escrowToken.transfer(beneficiary, amount), "Token transfer failed");
        emit FundsReleased(beneficiary, amount);
    }

    /**
     * @dev Refund funds back to the depositor if conditions are not met.
     */
    function refundFunds() external onlyDepositor canRefund nonReentrant {
        uint256 amount = escrowDetails.amount;
        escrowDetails.isRefunded = true;

        require(escrowToken.transfer(depositor, amount), "Token transfer failed");
        emit FundsRefunded(depositor, amount);
    }

    /**
     * @dev Get details of the escrow.
     */
    function getEscrowDetails() external view returns (uint256 amount, uint256 releaseTime, bool isReleased, bool isRefunded) {
        amount = escrowDetails.amount;
        releaseTime = escrowDetails.releaseTime;
        isReleased = escrowDetails.isReleased;
        isRefunded = escrowDetails.isRefunded;
    }
}
