// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title ConditionalRealTimeEscrow
 * @dev Conditional Real-Time Escrow Contract using ERC777, supporting real-time monitoring of conditions for fund release.
 */
contract ConditionalRealTimeEscrow is IERC777Recipient, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    IERC1820Registry private constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    IERC777 public escrowToken;
    address public depositor;
    address public beneficiary;

    uint256 public escrowAmount;
    bool public fundsReleased;
    bool public fundsRefunded;

    string public escrowCondition; // The condition that needs to be met for releasing the funds
    mapping(string => bool) private conditionStatus;

    event FundsDeposited(address indexed from, uint256 amount);
    event FundsReleased(address indexed to, uint256 amount);
    event FundsRefunded(address indexed to, uint256 amount);
    event ConditionUpdated(string condition, bool status);

    modifier onlyDepositor() {
        require(msg.sender == depositor, "Caller is not the depositor");
        _;
    }

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Caller is not the beneficiary");
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
        uint256 _amount,
        string memory _escrowCondition
    ) {
        require(_escrowToken != address(0), "Invalid token address");
        require(_depositor != address(0), "Depositor address cannot be zero");
        require(_beneficiary != address(0), "Beneficiary address cannot be zero");
        require(_amount > 0, "Amount must be greater than zero");
        require(bytes(_escrowCondition).length > 0, "Condition cannot be empty");

        escrowToken = IERC777(_escrowToken);
        depositor = _depositor;
        beneficiary = _beneficiary;
        escrowAmount = _amount;
        escrowCondition = _escrowCondition;
        conditionStatus[_escrowCondition] = false;

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
     * @dev Updates the status of the escrow condition.
     * @param _condition The condition being updated.
     * @param _status The status of the condition.
     */
    function updateConditionStatus(string memory _condition, bool _status) external onlyOwner {
        require(bytes(_condition).length > 0, "Condition cannot be empty");
        require(keccak256(bytes(_condition)) == keccak256(bytes(escrowCondition)), "Condition mismatch");

        conditionStatus[_condition] = _status;
        emit ConditionUpdated(_condition, _status);

        if (_status) {
            releaseFunds();
        }
    }

    /**
     * @dev Releases the escrowed funds to the beneficiary when the condition is met.
     */
    function releaseFunds() internal nonReentrant fundsNotReleasedOrRefunded {
        require(conditionStatus[escrowCondition], "Condition not met");

        fundsReleased = true;
        escrowToken.send(beneficiary, escrowAmount, "");
        emit FundsReleased(beneficiary, escrowAmount);
    }

    /**
     * @dev Refunds the escrowed funds back to the depositor.
     */
    function refundFunds() external onlyDepositor nonReentrant fundsNotReleasedOrRefunded {
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
            bool _fundsRefunded,
            string memory _escrowCondition,
            bool _conditionStatus
        )
    {
        return (depositor, beneficiary, escrowAmount, fundsReleased, fundsRefunded, escrowCondition, conditionStatus[escrowCondition]);
    }
}
