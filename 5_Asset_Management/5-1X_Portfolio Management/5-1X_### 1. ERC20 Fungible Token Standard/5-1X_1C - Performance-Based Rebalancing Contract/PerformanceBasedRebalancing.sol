// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PerformanceBasedRebalancing is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // Structure to hold asset details
    struct Asset {
        IERC20 token;
        uint256 targetAllocation; // Target percentage in basis points (1% = 100 bp)
        uint256 lastPerformance;  // Store last performance metric for comparison
        AggregatorV3Interface priceFeed; // Chainlink price feed for the asset
    }

    // Array to hold all assets in the portfolio
    Asset[] public assets;

    // Maximum allowed deviation before rebalancing, in basis points
    uint256 public rebalanceThreshold = 500; // 5%

    // Total value of the portfolio in USD
    uint256 public totalPortfolioValue;

    // Investor balances in ETH
    mapping(address => uint256) public balances;

    // Events
    event Invested(address indexed investor, uint256 amount);
    event Withdrawn(address indexed investor, uint256 amount);
    event Rebalanced();
    event AssetAdded(IERC20 indexed token, uint256 targetAllocation, address priceFeed);
    event AssetUpdated(IERC20 indexed token, uint256 newTargetAllocation, address priceFeed);
    event RebalanceThresholdUpdated(uint256 newThreshold);

    modifier validAllocation() {
        uint256 totalAllocation = 0;
        for (uint256 i = 0; i < assets.length; i++) {
            totalAllocation = totalAllocation.add(assets[i].targetAllocation);
        }
        require(totalAllocation == 10000, "Total allocation must be 100%");
        _;
    }

    function setRebalanceThreshold(uint256 _newThreshold) external onlyOwner {
        require(_newThreshold > 0, "Threshold must be greater than 0");
        rebalanceThreshold = _newThreshold;
        emit RebalanceThresholdUpdated(_newThreshold);
    }

    function addAsset(IERC20 _token, uint256 _targetAllocation, address _priceFeed) external onlyOwner validAllocation {
        assets.push(Asset({
            token: _token,
            targetAllocation: _targetAllocation,
            lastPerformance: 0,
            priceFeed: AggregatorV3Interface(_priceFeed)
        }));
        emit AssetAdded(_token, _targetAllocation, _priceFeed);
    }

    function updateAsset(IERC20 _token, uint256 _newTargetAllocation, address _newPriceFeed) external onlyOwner validAllocation {
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].token == _token) {
                assets[i].targetAllocation = _newTargetAllocation;
                assets[i].priceFeed = AggregatorV3Interface(_newPriceFeed);
                emit AssetUpdated(_token, _newTargetAllocation, _newPriceFeed);
                return;
            }
        }
    }

    function invest() external payable nonReentrant {
        require(msg.value > 0, "Investment must be greater than zero");
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        totalPortfolioValue = totalPortfolioValue.add(msg.value);
        emit Invested(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external nonReentrant {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        totalPortfolioValue = totalPortfolioValue.sub(_amount);
        payable(msg.sender).transfer(_amount);
        emit Withdrawn(msg.sender, _amount);
    }

    function rebalance() external onlyOwner nonReentrant validAllocation {
        uint256 portfolioValueUSD = calculatePortfolioValue();
        uint256[] memory performances = calculatePerformance();

        for (uint256 i = 0; i < assets.length; i++) {
            uint256 targetValueUSD = portfolioValueUSD.mul(assets[i].targetAllocation).div(10000);
            uint256 currentValueUSD = getAssetValueUSD(assets[i]);

            if (performances[i] > assets[i].lastPerformance) {
                // Increase exposure to better-performing assets
                uint256 excessUSD = targetValueUSD.mul(performances[i].sub(assets[i].lastPerformance)).div(performances[i]);
                uint256 excessTokens = excessUSD.mul(1e18).div(getLatestPrice(assets[i].priceFeed));
                assets[i].token.transferFrom(owner(), address(this), excessTokens);
            } else if (performances[i] < assets[i].lastPerformance) {
                // Decrease exposure to underperforming assets
                uint256 deficitUSD = targetValueUSD.mul(assets[i].lastPerformance.sub(performances[i])).div(performances[i]);
                uint256 deficitTokens = deficitUSD.mul(1e18).div(getLatestPrice(assets[i].priceFeed));
                assets[i].token.transfer(owner(), deficitTokens);
            }

            assets[i].lastPerformance = performances[i];
        }

        totalPortfolioValue = portfolioValueUSD;
        emit Rebalanced();
    }

    function calculatePerformance() public view returns (uint256[] memory) {
        uint256[] memory performances = new uint256[](assets.length);

        for (uint256 i = 0; i < assets.length; i++) {
            uint256 currentValueUSD = getAssetValueUSD(assets[i]);
            performances[i] = currentValueUSD.mul(1e18).div(assets[i].token.balanceOf(address(this)));
        }

        return performances;
    }

    function calculatePortfolioValue() public view returns (uint256) {
        uint256 portfolioValueUSD = 0;
        for (uint256 i = 0; i < assets.length; i++) {
            portfolioValueUSD = portfolioValueUSD.add(getAssetValueUSD(assets[i]));
        }
        return portfolioValueUSD;
    }

    function getAssetValueUSD(Asset memory _asset) internal view returns (uint256) {
        uint256 tokenBalance = _asset.token.balanceOf(address(this));
        uint256 tokenPriceUSD = getLatestPrice(_asset.priceFeed);
        return tokenBalance.mul(tokenPriceUSD).div(1e18);
    }

    function getLatestPrice(AggregatorV3Interface _priceFeed) internal view returns (uint256) {
        (, int256 price, , ,) = _priceFeed.latestRoundData();
        return uint256(price).mul(1e10); // Convert to 18 decimal places
    }

    receive() external payable {
        invest();
    }
}
