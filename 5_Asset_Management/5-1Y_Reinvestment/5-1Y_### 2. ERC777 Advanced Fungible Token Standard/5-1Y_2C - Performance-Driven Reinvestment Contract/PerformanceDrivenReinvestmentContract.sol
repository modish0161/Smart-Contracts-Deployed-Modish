// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PerformanceDrivenReinvestmentContract is IERC777Recipient, IERC777Sender, Ownable, ReentrancyGuard, Pausable {
    using Address for address;

    // ERC777 Token Interface
    IERC777 public profitToken;

    // Performance Metrics Oracle Interface
    AggregatorV3Interface public performanceOracle;

    // Mapping for operator status
    mapping(address => bool) public isOperator;

    // Mapping to store user profit balances
    mapping(address => uint256) public userProfitBalances;

    // Minimum performance threshold for reinvestment
    uint256 public performanceThreshold;

    // Event declarations
    event ProfitsDeposited(address indexed user, uint256 amount);
    event ProfitsReinvested(address indexed user, uint256 amount, address investmentToken, uint256 performanceIndex);
    event OperatorUpdated(address indexed operator, bool status);
    event PerformanceThresholdUpdated(uint256 newThreshold);

    // Constructor to initialize the contract with the profit token and oracle address
    constructor(address _profitToken, address _performanceOracle, uint256 _performanceThreshold) {
        require(_profitToken != address(0), "Invalid profit token address");
        require(_performanceOracle != address(0), "Invalid oracle address");

        profitToken = IERC777(_profitToken);
        performanceOracle = AggregatorV3Interface(_performanceOracle);
        performanceThreshold = _performanceThreshold;

        // Register this contract as an ERC777 token recipient and sender
        IERC1820Registry(_getERC1820Registry()).setInterfaceImplementer(address(this), keccak256("ERC777TokensRecipient"), address(this));
        IERC1820Registry(_getERC1820Registry()).setInterfaceImplementer(address(this), keccak256("ERC777TokensSender"), address(this));
    }

    // Function to deposit profits (ERC777 tokens)
    function depositProfits(uint256 amount) external whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        profitToken.operatorSend(msg.sender, address(this), amount, "", "");
        userProfitBalances[msg.sender] += amount;

        emit ProfitsDeposited(msg.sender, amount);
    }

    // Function for operator to reinvest profits on behalf of users
    function reinvestProfits(address user, uint256 amount, address investmentToken) external whenNotPaused nonReentrant onlyOperator {
        require(userProfitBalances[user] >= amount, "Insufficient balance for reinvestment");
        require(investmentToken.isContract(), "Invalid investment token address");

        // Fetch performance index from oracle
        uint256 performanceIndex = getPerformanceIndex();
        require(performanceIndex >= performanceThreshold, "Performance below threshold");

        // Transfer the specified amount to the investment token contract
        profitToken.operatorSend(address(this), investmentToken, amount, "", "");

        // Update the user's balance
        userProfitBalances[user] -= amount;

        emit ProfitsReinvested(user, amount, investmentToken, performanceIndex);
    }

    // Function to update the performance threshold
    function updatePerformanceThreshold(uint256 newThreshold) external onlyOwner {
        performanceThreshold = newThreshold;
        emit PerformanceThresholdUpdated(newThreshold);
    }

    // Function to add or remove operators
    function updateOperator(address operator, bool status) external onlyOwner {
        require(operator != address(0), "Invalid operator address");
        isOperator[operator] = status;

        emit OperatorUpdated(operator, status);
    }

    // Function to pause the contract (admin only)
    function pause() external onlyOwner {
        _pause();
    }

    // Function to unpause the contract (admin only)
    function unpause() external onlyOwner {
        _unpause();
    }

    // Function to get the current performance index from the oracle
    function getPerformanceIndex() public view returns (uint256) {
        (, int256 index,,,) = performanceOracle.latestRoundData();
        require(index > 0, "Invalid performance index");
        return uint256(index);
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

    // Modifier to restrict functions to designated operators
    modifier onlyOperator() {
        require(isOperator[msg.sender], "Caller is not an operator");
        _;
    }
}
