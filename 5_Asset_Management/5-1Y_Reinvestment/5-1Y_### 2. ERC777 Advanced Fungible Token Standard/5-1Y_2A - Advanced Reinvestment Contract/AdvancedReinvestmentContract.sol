// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AdvancedReinvestmentContract is IERC777Recipient, IERC777Sender, Ownable, ReentrancyGuard, Pausable {
    using Address for address;

    // Interfaces for ERC777 tokens
    IERC777 public dividendToken;
    IERC777 public investmentToken;

    // Reinvestment Operator Address
    address public reinvestmentOperator;

    // Profit threshold for automatic reinvestment
    uint256 public profitThreshold;

    // Mapping to store user dividend balances
    mapping(address => uint256) public userDividendBalances;

    // Event declarations
    event DividendsDeposited(address indexed user, uint256 amount);
    event ProfitsReinvested(address indexed user, uint256 reinvestedAmount);
    event ProfitThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);
    event ReinvestmentOperatorUpdated(address oldOperator, address newOperator);

    // Constructor to initialize the contract with ERC777 tokens and a default profit threshold
    constructor(address _dividendToken, address _investmentToken, uint256 _profitThreshold, address _operator) {
        require(_profitThreshold > 0, "Profit threshold must be greater than zero");
        require(_operator != address(0), "Invalid operator address");

        dividendToken = IERC777(_dividendToken);
        investmentToken = IERC777(_investmentToken);
        profitThreshold = _profitThreshold;
        reinvestmentOperator = _operator;

        // Register this contract as an ERC777 token recipient
        IERC1820Registry(_getERC1820Registry()).setInterfaceImplementer(address(this), keccak256("ERC777TokensRecipient"), address(this));
        IERC1820Registry(_getERC1820Registry()).setInterfaceImplementer(address(this), keccak256("ERC777TokensSender"), address(this));
    }

    // Function to deposit dividends (ERC777 tokens)
    function depositDividends(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        dividendToken.operatorSend(msg.sender, address(this), amount, "", "");
        userDividendBalances[msg.sender] += amount;

        emit DividendsDeposited(msg.sender, amount);
    }

    // Function to reinvest profits if they exceed the profit threshold
    function reinvestProfits(address user) external whenNotPaused nonReentrant onlyReinvestmentOperator {
        uint256 dividendBalance = userDividendBalances[user];
        require(dividendBalance >= profitThreshold, "Insufficient profit for reinvestment");

        // Reinvest the dividend balance into the investment token
        dividendToken.operatorSend(address(this), address(investmentToken), dividendBalance, "", "");
        investmentToken.send(user, dividendBalance, "");

        emit ProfitsReinvested(user, dividendBalance);

        // Reset user balance after reinvestment
        userDividendBalances[user] = 0;
    }

    // Function to update the profit threshold (admin only)
    function updateProfitThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold > 0, "Threshold must be greater than zero");
        uint256 oldThreshold = profitThreshold;
        profitThreshold = newThreshold;

        emit ProfitThresholdUpdated(oldThreshold, newThreshold);
    }

    // Function to update the reinvestment operator (admin only)
    function updateReinvestmentOperator(address newOperator) external onlyOwner {
        require(newOperator != address(0), "Invalid operator address");
        address oldOperator = reinvestmentOperator;
        reinvestmentOperator = newOperator;

        emit ReinvestmentOperatorUpdated(oldOperator, newOperator);
    }

    // Function to pause the contract (admin only)
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract (admin only)
    function unpause() external onlyOwner {
        _unpause();
    }

    // ERC777 token recipient hook
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        // This function is called whenever the contract receives ERC777 tokens
        // Implement any necessary logic for handling received tokens here
    }

    // ERC777 token sender hook
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        // This function is called whenever the contract sends ERC777 tokens
        // Implement any necessary logic for handling sent tokens here
    }

    // Internal function to get the ERC1820 registry address
    function _getERC1820Registry() internal pure returns (address) {
        return 0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24;
    }

    // Modifier to restrict functions to the reinvestment operator
    modifier onlyReinvestmentOperator() {
        require(msg.sender == reinvestmentOperator, "Caller is not the reinvestment operator");
        _;
    }
}
