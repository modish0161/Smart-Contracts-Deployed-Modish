// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title OperatorControlledEscrow
 * @dev Operator-Controlled Escrow Contract with ERC777 standard, supporting operator permissions for fund release.
 */
contract OperatorControlledEscrow is IERC777Recipient, ReentrancyGuard, Ownable {
    IERC1820Registry private constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    IERC777 public escrowToken;
    address public depositor;
    address public beneficiary;
    address public operator;

    uint256 public escrowAmount;
    bool public fundsReleased;
    bool public fundsRefunded;

    event FundsDeposited(address indexed from, uint256 amount);
    event FundsReleased(address indexed to, uint256 amount);
    event FundsRefunded(address indexed to, uint256 amount);
    event OperatorSet(address indexed operator);

    modifier onlyDepositor() {
        require(msg.sender == depositor, "Caller is not the depositor");
        _;
    }

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Caller is not the beneficiary");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Caller is not the operator");
        _;
    }

    modifier fundsNotReleasedOrRefunded() {
        require(!fundsReleased, "Funds already released");
        require(!fundsRefunded, "Funds already refunded");
        _;
    }

    constructor(
        address _escrowToken,
        address _depositor,
        address _beneficiary,
        uint256 _amount
    ) {
        require(_escrowToken != address(0), "Invalid token address");
        require(_depositor != address(0), "Depositor address cannot be zero");
        require(_beneficiary != address(0), "Beneficiary address cannot be zero");
        require(_amount > 0, "Amount must be greater than zero");

        escrowToken = IERC777(_escrowToken);
        depositor = _depositor;
        beneficiary = _beneficiary;
        escrowAmount = _amount;

        // Register the contract as a recipient of ERC777 tokens
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777TokensRecipient"), address(this));
    }

    /**
     * @dev Deposits the ERC777 tokens into escrow.
     */
    function depositFunds() external onlyDepositor nonReentrant fundsNotReleasedOrRefunded {
        require(escrowToken.balanceOf(depositor) >= escrowAmount, "Insufficient token balance");
        escrowToken.operatorSend(depositor, address(this), escrowAmount, "", "");
        emit FundsDeposited(depositor, escrowAmount);
    }

    /**
     * @dev Sets an operator with permissions to release the funds.
     * @param _operator The address of the operator.
     */
    function setOperator(address _operator) external onlyOwner {
        require(_operator != address(0), "Invalid operator address");
        operator = _operator;
        emit OperatorSet(_operator);
    }

    /**
     * @dev Releases the escrowed funds to the beneficiary.
     */
    function releaseFunds() external onlyOperator nonReentrant fundsNotReleasedOrRefunded {
        fundsReleased = true;
        escrowToken.send(beneficiary, escrowAmount, "");
        emit FundsReleased(beneficiary, escrowAmount);
    }

    /**
     * @dev Refunds the escrowed funds back to the depositor.
     */
    function refundFunds() external onlyOperator nonReentrant fundsNotReleasedOrRefunded {
        fundsRefunded = true;
        escrowToken.send(depositor, escrowAmount, "");
        emit FundsRefunded(depositor, escrowAmount);
    }

    /**
     * @dev IERC777Recipient hook implementation, called when the contract receives ERC777 tokens.
     */
    function tokensReceived(
        address /*operator*/,
        address from,
        address to,
        uint256 amount,
        bytes calldata /*data*/,
        bytes calldata /*operatorData*/
    ) external override {
        require(msg.sender == address(escrowToken), "Tokens received not from escrowToken");
        require(to == address(this), "Tokens not sent to this contract");
        require(from == depositor, "Tokens not sent from depositor");
        require(amount == escrowAmount, "Incorrect escrow amount received");
    }

    /**
     * @dev Get the escrow details.
     */
    function getEscrowDetails()
        external
        view
        returns (
            address _depositor,
            address _beneficiary,
            uint256 _escrowAmount,
            bool _fundsReleased,
            bool _fundsRefunded
        )
    {
        return (depositor, beneficiary, escrowAmount, fundsReleased, fundsRefunded);
    }
}
