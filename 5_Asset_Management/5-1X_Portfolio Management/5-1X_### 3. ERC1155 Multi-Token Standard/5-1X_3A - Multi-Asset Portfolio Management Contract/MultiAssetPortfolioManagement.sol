// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MultiAssetPortfolioManagement is ERC1155, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // Structure to hold asset details
    struct Asset {
        address tokenAddress;      // Address of the ERC20/ERC721 token
        bool isFungible;           // True for ERC20, false for ERC721
        uint256 targetAllocation;  // Target percentage in basis points (1% = 100 bp)
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
    event AssetAdded(address indexed tokenAddress, bool isFungible, uint256 targetAllocation, address priceFeed);
    event AssetUpdated(address indexed tokenAddress, bool isFungible, uint256 newTargetAllocation, address priceFeed);
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

    constructor(string memory uri) ERC1155(uri) {
        // Initial setup
    }

    function setRebalanceThreshold(uint256 _newThreshold) external onlyOwner {
        require(_newThreshold > 0, "Threshold must be greater than 0");
        rebalanceThreshold = _newThreshold;
        emit RebalanceThresholdUpdated(_newThreshold);
    }

    function addAsset(
        address _tokenAddress,
        bool _isFungible,
        uint256 _targetAllocation,
        address _priceFeed
    ) external onlyOwner validAllocation {
        assets.push(Asset({
            tokenAddress: _tokenAddress,
            isFungible: _isFungible,
            targetAllocation: _targetAllocation,
            priceFeed: AggregatorV3Interface(_priceFeed)
        }));
        emit AssetAdded(_tokenAddress, _isFungible, _targetAllocation, _priceFeed);
    }

    function updateAsset(
        address _tokenAddress,
        bool _isFungible,
        uint256 _newTargetAllocation,
        address _newPriceFeed
    ) external onlyOwner validAllocation {
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].tokenAddress == _tokenAddress && assets[i].isFungible == _isFungible) {
                assets[i].targetAllocation = _newTargetAllocation;
                assets[i].priceFeed = AggregatorV3Interface(_newPriceFeed);
                emit AssetUpdated(_tokenAddress, _isFungible, _newTargetAllocation, _newPriceFeed);
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
                // Sell excess tokens or NFTs
                uint256 excessUSD = currentValueUSD.sub(targetValueUSD);
                if (assets[i].isFungible) {
                    uint256 excessTokens = excessUSD.mul(1e18).div(getLatestPrice(assets[i].priceFeed));
                    IERC20(assets[i].tokenAddress).transfer(owner(), excessTokens);
                } else {
                    // Logic for selling NFTs (needs custom implementation based on use case)
                    revert("NFT selling not implemented");
                }
            } else if (currentValueUSD < targetValueUSD.sub(targetValueUSD.mul(rebalanceThreshold).div(10000))) {
                // Buy more tokens or NFTs
                uint256 deficitUSD = targetValueUSD.sub(currentValueUSD);
                if (assets[i].isFungible) {
                    uint256 deficitTokens = deficitUSD.mul(1e18).div(getLatestPrice(assets[i].priceFeed));
                    IERC20(assets[i].tokenAddress).transferFrom(owner(), address(this), deficitTokens);
                } else {
                    // Logic for buying NFTs (needs custom implementation based on use case)
                    revert("NFT purchasing not implemented");
                }
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
        uint256 tokenBalance;
        if (_asset.isFungible) {
            tokenBalance = IERC20(_asset.tokenAddress).balanceOf(address(this));
        } else {
            tokenBalance = IERC721(_asset.tokenAddress).balanceOf(address(this)); // Example logic for NFTs
        }
        uint256 tokenPriceUSD = getLatestPrice(_asset.priceFeed);
        return tokenBalance.mul(tokenPriceUSD).div(1e18);
    }

    function getLatestPrice(AggregatorV3Interface _priceFeed) internal view returns (uint256) {
        (, int256 price, , ,) = _priceFeed.latestRoundData();
        return uint256(price).mul(1e10); // Convert to 18 decimal places
    }
}
