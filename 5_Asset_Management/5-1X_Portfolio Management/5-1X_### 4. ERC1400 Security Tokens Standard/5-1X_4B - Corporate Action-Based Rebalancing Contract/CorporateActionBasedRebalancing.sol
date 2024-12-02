// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ERC1400/ERC1400.sol";

contract CorporateActionBasedRebalancing is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Asset {
        address tokenAddress;      // Address of the ERC1400 token
        uint256 targetAllocation;  // Target percentage in basis points (1% = 100 bp)
        AggregatorV3Interface priceFeed; // Chainlink price feed for the asset
    }

    // Portfolio ID to assets mapping
    mapping(uint256 => Asset[]) public portfolios;

    // Operators mapping
    mapping(address => bool) public operators;

    // Set of authorized investors
    EnumerableSet.AddressSet private authorizedInvestors;

    // Maximum allowed deviation before rebalancing, in basis points
    uint256 public rebalanceThreshold = 500; // 5%

    // Events
    event Rebalanced(uint256 indexed portfolioId);
    event AssetAdded(uint256 indexed portfolioId, address indexed tokenAddress, uint256 targetAllocation, address priceFeed);
    event CorporateActionProcessed(uint256 indexed portfolioId, address indexed tokenAddress, string actionType, uint256 adjustedValue);
    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);
    event RebalanceThresholdUpdated(uint256 newThreshold);
    event InvestorAuthorized(address indexed investor);
    event InvestorDeauthorized(address indexed investor);

    modifier onlyOperator() {
        require(operators[msg.sender] || msg.sender == owner(), "Not an operator");
        _;
    }

    modifier validAllocation(uint256 _portfolioId) {
        uint256 totalAllocation = 0;
        for (uint256 i = 0; i < portfolios[_portfolioId].length; i++) {
            totalAllocation = totalAllocation.add(portfolios[_portfolioId][i].targetAllocation);
        }
        require(totalAllocation == 10000, "Total allocation must be 100%");
        _;
    }

    modifier onlyAuthorizedInvestor() {
        require(authorizedInvestors.contains(msg.sender), "Not an authorized investor");
        _;
    }

    constructor() {
        // Initial setup
    }

    function setRebalanceThreshold(uint256 _newThreshold) external onlyOwner {
        require(_newThreshold > 0, "Threshold must be greater than 0");
        rebalanceThreshold = _newThreshold;
        emit RebalanceThresholdUpdated(_newThreshold);
    }

    function addAsset(
        uint256 _portfolioId,
        address _tokenAddress,
        uint256 _targetAllocation,
        address _priceFeed
    ) external onlyOwner validAllocation(_portfolioId) {
        portfolios[_portfolioId].push(Asset({
            tokenAddress: _tokenAddress,
            targetAllocation: _targetAllocation,
            priceFeed: AggregatorV3Interface(_priceFeed)
        }));
        emit AssetAdded(_portfolioId, _tokenAddress, _targetAllocation, _priceFeed);
    }

    function processCorporateAction(
        uint256 _portfolioId,
        address _tokenAddress,
        string memory _actionType,
        uint256 _adjustedValue
    ) external onlyOperator {
        for (uint256 i = 0; i < portfolios[_portfolioId].length; i++) {
            if (portfolios[_portfolioId][i].tokenAddress == _tokenAddress) {
                // Adjust allocation based on corporate action type
                if (keccak256(abi.encodePacked(_actionType)) == keccak256(abi.encodePacked("stockSplit"))) {
                    portfolios[_portfolioId][i].targetAllocation = _adjustedValue;
                } else if (keccak256(abi.encodePacked(_actionType)) == keccak256(abi.encodePacked("dividend"))) {
                    portfolios[_portfolioId][i].targetAllocation = _adjustedValue;
                } else if (keccak256(abi.encodePacked(_actionType)) == keccak256(abi.encodePacked("merger"))) {
                    portfolios[_portfolioId][i].targetAllocation = _adjustedValue;
                }
                emit CorporateActionProcessed(_portfolioId, _tokenAddress, _actionType, _adjustedValue);
                return;
            }
        }
    }

    function addOperator(address _operator) external onlyOwner {
        operators[_operator] = true;
        emit OperatorAdded(_operator);
    }

    function removeOperator(address _operator) external onlyOwner {
        operators[_operator] = false;
        emit OperatorRemoved(_operator);
    }

    function authorizeInvestor(address _investor) external onlyOwner {
        authorizedInvestors.add(_investor);
        emit InvestorAuthorized(_investor);
    }

    function deauthorizeInvestor(address _investor) external onlyOwner {
        authorizedInvestors.remove(_investor);
        emit InvestorDeauthorized(_investor);
    }

    function rebalance(uint256 _portfolioId) external onlyOperator nonReentrant validAllocation(_portfolioId) whenNotPaused {
        uint256 portfolioValueUSD = calculatePortfolioValue(_portfolioId);

        for (uint256 i = 0; i < portfolios[_portfolioId].length; i++) {
            uint256 targetValueUSD = portfolioValueUSD.mul(portfolios[_portfolioId][i].targetAllocation).div(10000);
            uint256 currentValueUSD = getAssetValueUSD(portfolios[_portfolioId][i]);

            if (currentValueUSD > targetValueUSD.add(targetValueUSD.mul(rebalanceThreshold).div(10000))) {
                // Sell excess tokens
                uint256 excessUSD = currentValueUSD.sub(targetValueUSD);
                uint256 excessTokens = excessUSD.mul(1e18).div(getLatestPrice(portfolios[_portfolioId][i].priceFeed));
                IERC20(portfolios[_portfolioId][i].tokenAddress).transfer(owner(), excessTokens);
            } else if (currentValueUSD < targetValueUSD.sub(targetValueUSD.mul(rebalanceThreshold).div(10000))) {
                // Buy more tokens
                uint256 deficitUSD = targetValueUSD.sub(currentValueUSD);
                uint256 deficitTokens = deficitUSD.mul(1e18).div(getLatestPrice(portfolios[_portfolioId][i].priceFeed));
                IERC20(portfolios[_portfolioId][i].tokenAddress).transferFrom(owner(), address(this), deficitTokens);
            }
        }

        emit Rebalanced(_portfolioId);
    }

    function calculatePortfolioValue(uint256 _portfolioId) public view returns (uint256) {
        uint256 portfolioValueUSD = 0;
        for (uint256 i = 0; i < portfolios[_portfolioId].length; i++) {
            portfolioValueUSD = portfolioValueUSD.add(getAssetValueUSD(portfolios[_portfolioId][i]));
        }
        return portfolioValueUSD;
    }

    function getAssetValueUSD(Asset memory _asset) internal view returns (uint256) {
        uint256 tokenBalance = IERC20(_asset.tokenAddress).balanceOf(address(this));
        uint256 tokenPriceUSD = getLatestPrice(_asset.priceFeed);
        return tokenBalance.mul(tokenPriceUSD).div(1e18);
    }

    function getLatestPrice(AggregatorV3Interface _priceFeed) internal view returns (uint256) {
        (, int256 price, , ,) = _priceFeed.latestRoundData();
        return uint256(price).mul(1e10); // Convert to 18 decimal places
    }

    // Emergency function to pause all operations
    function pause() external onlyOwner {
        _pause();
    }

    // Unpause all operations
    function unpause() external onlyOwner {
        _unpause();
    }
}
