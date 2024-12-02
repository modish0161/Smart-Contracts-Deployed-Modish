// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract OperatorControlledRebalancing is ERC777, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // Structure to hold asset details
    struct Asset {
        address token;
        uint256 targetAllocation; // Target percentage in basis points (1% = 100 bp)
        AggregatorV3Interface priceFeed; // Chainlink price feed for the asset
    }

    // Array to hold all assets in the portfolio
    Asset[] public assets;

    // Mapping to keep track of operator permissions
    mapping(address => bool) public operators;

    // Maximum allowed deviation before rebalancing, in basis points
    uint256 public rebalanceThreshold = 500; // 5%

    // Total value of the portfolio in USD
    uint256 public totalPortfolioValue;

    // Events
    event Rebalanced();
    event AssetAdded(address indexed token, uint256 targetAllocation, address priceFeed);
    event AssetUpdated(address indexed token, uint256 newTargetAllocation, address priceFeed);
    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);
    event RebalanceThresholdUpdated(uint256 newThreshold);

    modifier onlyOperator() {
        require(operators[msg.sender] || msg.sender == owner(), "Not an operator");
        _;
    }

    modifier validAllocation() {
        uint256 totalAllocation = 0;
        for (uint256 i = 0; i < assets.length; i++) {
            totalAllocation = totalAllocation.add(assets[i].targetAllocation);
        }
        require(totalAllocation == 10000, "Total allocation must be 100%");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators
    ) ERC777(name, symbol, defaultOperators) {
        // Initial setup
    }

    function setRebalanceThreshold(uint256 _newThreshold) external onlyOwner {
        require(_newThreshold > 0, "Threshold must be greater than 0");
        rebalanceThreshold = _newThreshold;
        emit RebalanceThresholdUpdated(_newThreshold);
    }

    function addAsset(address _token, uint256 _targetAllocation, address _priceFeed) external onlyOwner validAllocation {
        assets.push(Asset({
            token: _token,
            targetAllocation: _targetAllocation,
            priceFeed: AggregatorV3Interface(_priceFeed)
        }));
        emit AssetAdded(_token, _targetAllocation, _priceFeed);
    }

    function updateAsset(address _token, uint256 _newTargetAllocation, address _newPriceFeed) external onlyOwner validAllocation {
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].token == _token) {
                assets[i].targetAllocation = _newTargetAllocation;
                assets[i].priceFeed = AggregatorV3Interface(_newPriceFeed);
                emit AssetUpdated(_token, _newTargetAllocation, _newPriceFeed);
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

    function rebalance() external onlyOperator nonReentrant validAllocation {
        uint256 portfolioValueUSD = calculatePortfolioValue();

        for (uint256 i = 0; i < assets.length; i++) {
            uint256 targetValueUSD = portfolioValueUSD.mul(assets[i].targetAllocation).div(10000);
            uint256 currentValueUSD = getAssetValueUSD(assets[i]);

            if (currentValueUSD > targetValueUSD.add(targetValueUSD.mul(rebalanceThreshold).div(10000))) {
                // Sell excess tokens
                uint256 excessUSD = currentValueUSD.sub(targetValueUSD);
                uint256 excessTokens = excessUSD.mul(1e18).div(getLatestPrice(assets[i].priceFeed));
                IERC777(assets[i].token).operatorSend(owner(), address(this), excessTokens, "", "");
            } else if (currentValueUSD < targetValueUSD.sub(targetValueUSD.mul(rebalanceThreshold).div(10000))) {
                // Buy more tokens
                uint256 deficitUSD = targetValueUSD.sub(currentValueUSD);
                uint256 deficitTokens = deficitUSD.mul(1e18).div(getLatestPrice(assets[i].priceFeed));
                IERC777(assets[i].token).operatorSend(address(this), owner(), deficitTokens, "", "");
            }
        }

        totalPortfolioValue = portfolioValueUSD;
        emit Rebalanced();
    }

    function calculatePortfolioValue() public view returns (uint256) {
        uint256 portfolioValueUSD = 0;
        for (uint256 i = 0; i < assets.length; i++) {
            portfolioValueUSD = portfolioValueUSD.add(getAssetValueUSD(assets[i]));
        }
        return portfolioValueUSD;
    }

    function getAssetValueUSD(Asset memory _asset) internal view returns (uint256) {
        uint256 tokenBalance = IERC777(_asset.token).balanceOf(address(this));
        uint256 tokenPriceUSD = getLatestPrice(_asset.priceFeed);
        return tokenBalance.mul(tokenPriceUSD).div(1e18);
    }

    function getLatestPrice(AggregatorV3Interface _priceFeed) internal view returns (uint256) {
        (, int256 price, , ,) = _priceFeed.latestRoundData();
        return uint256(price).mul(1e10); // Convert to 18 decimal places
    }
}
