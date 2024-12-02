// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./ERC1404/ERC1404.sol";

contract RestrictedTokenPortfolioManagement is Ownable, ReentrancyGuard, Pausable, ERC1404 {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Data structure to hold asset details
    struct Asset {
        address tokenAddress;      // Address of the ERC1404 token
        uint256 targetAllocation;  // Target percentage in basis points (1% = 100 bp)
        uint256 complianceLimit;   // Compliance limit in basis points
        AggregatorV3Interface priceFeed; // Chainlink price feed for the asset
    }

    // Portfolio ID to assets mapping
    mapping(uint256 => Asset[]) public portfolios;

    // Set of accredited investors
    EnumerableSet.AddressSet private accreditedInvestors;

    // Events
    event Rebalanced(uint256 indexed portfolioId);
    event AssetAdded(uint256 indexed portfolioId, address indexed tokenAddress, uint256 targetAllocation, uint256 complianceLimit, address priceFeed);
    event ComplianceViolation(address indexed investor, uint256 portfolioId, address indexed tokenAddress, uint256 currentValue, uint256 complianceLimit);
    event InvestorAccredited(address indexed investor);
    event InvestorDeaccredited(address indexed investor);

    // Modifiers
    modifier onlyAccredited() {
        require(accreditedInvestors.contains(msg.sender), "Not an accredited investor");
        _;
    }

    modifier validAllocation(uint256 _portfolioId) {
        uint256 totalAllocation = 0;
        for (uint256 i = 0; i < portfolios[_portfolioId].length; i++) {
            totalAllocation = totalAllocation.add(portfolios[_portfolioId][i].targetAllocation);
        }
        require(totalAllocation <= 10000, "Total allocation must be <= 100%");
        _;
    }

    constructor() ERC1404("RestrictedToken", "RTKN") {
        // Initial setup
    }

    function addAsset(
        uint256 _portfolioId,
        address _tokenAddress,
        uint256 _targetAllocation,
        uint256 _complianceLimit,
        address _priceFeed
    ) external onlyOwner validAllocation(_portfolioId) {
        portfolios[_portfolioId].push(Asset({
            tokenAddress: _tokenAddress,
            targetAllocation: _targetAllocation,
            complianceLimit: _complianceLimit,
            priceFeed: AggregatorV3Interface(_priceFeed)
        }));
        emit AssetAdded(_portfolioId, _tokenAddress, _targetAllocation, _complianceLimit, _priceFeed);
    }

    function addAccreditedInvestor(address _investor) external onlyOwner {
        accreditedInvestors.add(_investor);
        emit InvestorAccredited(_investor);
    }

    function removeAccreditedInvestor(address _investor) external onlyOwner {
        accreditedInvestors.remove(_investor);
        emit InvestorDeaccredited(_investor);
    }

    function rebalance(uint256 _portfolioId) external onlyOwner nonReentrant validAllocation(_portfolioId) whenNotPaused {
        uint256 portfolioValueUSD = calculatePortfolioValue(_portfolioId);

        for (uint256 i = 0; i < portfolios[_portfolioId].length; i++) {
            uint256 targetValueUSD = portfolioValueUSD.mul(portfolios[_portfolioId][i].targetAllocation).div(10000);
            uint256 currentValueUSD = getAssetValueUSD(portfolios[_portfolioId][i]);
            uint256 complianceLimitUSD = portfolioValueUSD.mul(portfolios[_portfolioId][i].complianceLimit).div(10000);

            // Compliance Check
            if (currentValueUSD > complianceLimitUSD) {
                emit ComplianceViolation(msg.sender, _portfolioId, portfolios[_portfolioId][i].tokenAddress, currentValueUSD, complianceLimitUSD);
                // Rebalance by selling excess tokens or other adjustment mechanism
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

    // Overriding ERC1404 functions
    function detectTransferRestriction(address from, address to, uint256 value) public view override returns (uint8) {
        if (!accreditedInvestors.contains(to)) {
            return 1; // Transfer restricted to non-accredited investors
        }
        return 0; // No restriction
    }

    function messageForTransferRestriction(uint8 restrictionCode) public view override returns (string memory) {
        if (restrictionCode == 1) {
            return "Transfer restricted to non-accredited investors";
        }
        return "No restriction";
    }
}
