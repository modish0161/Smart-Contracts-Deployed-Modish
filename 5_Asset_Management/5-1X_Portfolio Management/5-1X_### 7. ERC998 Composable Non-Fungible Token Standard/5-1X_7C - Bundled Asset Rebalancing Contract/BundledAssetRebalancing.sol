// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998TopDown.sol";

contract BundledAssetRebalancing is ERC998TopDown, ERC721Enumerable, Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // Counter for tracking token IDs
    Counters.Counter private _tokenIdCounter;

    // Struct to represent a rebalancing strategy for bundled assets
    struct RebalancingStrategy {
        uint256 targetAllocation; // Target allocation percentage in basis points (1% = 100)
        address asset;            // Address of the asset to be rebalanced
        bool isActive;            // Status of the strategy
    }

    // Mapping from token ID to portfolio strategies
    mapping(uint256 => RebalancingStrategy[]) public portfolioStrategies;

    // Events
    event PortfolioCreated(uint256 indexed tokenId, address indexed owner);
    event StrategyAdded(uint256 indexed tokenId, uint256 indexed strategyId, address indexed asset, uint256 targetAllocation);
    event StrategyRemoved(uint256 indexed tokenId, uint256 indexed strategyId);
    event Rebalanced(uint256 indexed tokenId, address indexed initiator);

    // Constructor
    constructor() ERC721("BundledAssetPortfolio", "BAP") {}

    // Modifier to validate total allocation
    modifier validAllocation(uint256 tokenId) {
        uint256 totalAllocation = 0;
        for (uint256 i = 0; i < portfolioStrategies[tokenId].length; i++) {
            if (portfolioStrategies[tokenId][i].isActive) {
                totalAllocation = totalAllocation.add(portfolioStrategies[tokenId][i].targetAllocation);
            }
        }
        require(totalAllocation <= 10000, "Total allocation must be <= 100%");
        _;
    }

    // Create a new bundled asset portfolio
    function createPortfolio() external whenNotPaused nonReentrant returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _mint(msg.sender, newTokenId);
        emit PortfolioCreated(newTokenId, msg.sender);
        return newTokenId;
    }

    // Add a rebalancing strategy to a portfolio
    function addStrategy(uint256 tokenId, address _asset, uint256 _targetAllocation)
        external
        onlyOwnerOf(tokenId)
        validAllocation(tokenId)
    {
        portfolioStrategies[tokenId].push(RebalancingStrategy({
            targetAllocation: _targetAllocation,
            asset: _asset,
            isActive: true
        }));
        emit StrategyAdded(tokenId, portfolioStrategies[tokenId].length - 1, _asset, _targetAllocation);
    }

    // Remove a rebalancing strategy from a portfolio
    function removeStrategy(uint256 tokenId, uint256 strategyId) external onlyOwnerOf(tokenId) {
        require(strategyId < portfolioStrategies[tokenId].length, "Invalid strategy ID");
        portfolioStrategies[tokenId][strategyId].isActive = false;
        emit StrategyRemoved(tokenId, strategyId);
    }

    // Rebalance the portfolio based on predefined strategies
    function rebalance(uint256 tokenId) external onlyOwnerOf(tokenId) nonReentrant whenNotPaused {
        require(_exists(tokenId), "Nonexistent portfolio");
        uint256 totalValue = totalAssets(tokenId);
        for (uint256 i = 0; i < portfolioStrategies[tokenId].length; i++) {
            if (portfolioStrategies[tokenId][i].isActive) {
                uint256 targetValue = totalValue.mul(portfolioStrategies[tokenId][i].targetAllocation).div(10000);
                _adjustAssetAllocation(tokenId, portfolioStrategies[tokenId][i].asset, targetValue);
            }
        }
        emit Rebalanced(tokenId, msg.sender);
    }

    // Internal function to adjust asset allocation
    function _adjustAssetAllocation(uint256 tokenId, address _asset, uint256 _targetValue) internal {
        // Custom logic to adjust asset allocation
        // Implement strategies to buy/sell assets or interact with DeFi protocols
    }

    // Return the total assets value of a portfolio
    function totalAssets(uint256 tokenId) public view returns (uint256) {
        // Implement logic to calculate the total value of assets in the portfolio
        return 0; // Placeholder value, should be replaced with actual logic
    }

    // Modifier to check if the caller is the owner of the token
    modifier onlyOwnerOf(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Caller is not the owner");
        _;
    }

    // Pause and unpause functions
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Override functions for ERC721Enumerable compatibility
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
