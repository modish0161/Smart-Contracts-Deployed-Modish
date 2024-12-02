// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ERC1404/ERC1404.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract AccreditedInvestorPortfolioRebalancing is ERC1404, Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct PortfolioAsset {
        address tokenAddress;       // Address of the ERC1404 token
        uint256 targetAllocation;   // Target percentage in basis points (1% = 100 bp)
        uint256 complianceLimit;    // Compliance limit in basis points
        AggregatorV3Interface priceFeed; // Chainlink price feed for the asset
    }

    struct InvestorPortfolio {
        uint256 totalInvestment;    // Total amount invested by the investor
        mapping(address => uint256) allocations; // Token address to allocation
    }

    // Mapping from investor address to their portfolio
    mapping(address => InvestorPortfolio) public investorPortfolios;

    // Mapping from portfolio ID to assets
    mapping(uint256 => PortfolioAsset[]) public portfolios;

    // Set of accredited investors
    EnumerableSet.AddressSet private accreditedInvestors;

    // Events
    event Rebalanced(address indexed investor);
    event PortfolioAssetAdded(uint256 indexed portfolioId, address indexed tokenAddress, uint256 targetAllocation, uint256 complianceLimit, address priceFeed);
    event ComplianceViolation(address indexed investor, uint256 indexed portfolioId, address indexed tokenAddress, uint256 currentValue, uint256 complianceLimit);
    event InvestorAccredited(address indexed investor);
    event InvestorDeaccredited(address indexed investor);
    event InvestmentReceived(address indexed investor, uint256 amount);

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

    constructor() ERC1404("AccreditedInvestorToken", "AIT") {
        // Initial setup if needed
    }

    function addPortfolioAsset(
        uint256 _portfolioId,
        address _tokenAddress,
        uint256 _targetAllocation,
        uint256 _complianceLimit,
        address _priceFeed
    ) external onlyOwner validAllocation(_portfolioId) {
        portfolios[_portfolioId].push(PortfolioAsset({
            tokenAddress: _tokenAddress,
            targetAllocation: _targetAllocation,
            complianceLimit: _complianceLimit,
            priceFeed: AggregatorV3Interface(_priceFeed)
        }));
        emit PortfolioAssetAdded(_portfolioId, _tokenAddress, _targetAllocation, _complianceLimit, _priceFeed);
    }

    function addAccreditedInvestor(address _investor) external onlyOwner {
        accreditedInvestors.add(_investor);
        emit InvestorAccredited(_investor);
    }

    function removeAccreditedInvestor(address _investor) external onlyOwner {
        accreditedInvestors.remove(_investor);
        emit InvestorDeaccredited(_investor);
    }

    function invest(uint256 _portfolioId) external payable onlyAccredited whenNotPaused {
        require(msg.value > 0, "Investment amount must be greater than zero");
        investorPortfolios[msg.sender].totalInvestment = investorPortfolios[msg.sender].totalInvestment.add(msg.value);

        emit InvestmentReceived(msg.sender, msg.value);
        rebalance(msg.sender, _portfolioId);
    }

    function rebalance(address _investor, uint256 _portfolioId) public onlyAccredited nonReentrant validAllocation(_portfolioId) whenNotPaused {
        uint256 portfolioValueUSD = calculatePortfolioValue(_portfolioId);
        InvestorPortfolio storage portfolio = investorPortfolios[_investor];

        for (uint256 i = 0; i < portfolios[_portfolioId].length; i++) {
            PortfolioAsset memory asset = portfolios[_portfolioId][i];
            uint256 targetValueUSD = portfolioValueUSD.mul(asset.targetAllocation).div(10000);
            uint256 currentValueUSD = getAssetValueUSD(_investor, asset);
            uint256 complianceLimitUSD = portfolioValueUSD.mul(asset.complianceLimit).div(10000);

            // Compliance Check
            if (currentValueUSD > complianceLimitUSD) {
                emit ComplianceViolation(_investor, _portfolioId, asset.tokenAddress, currentValueUSD, complianceLimitUSD);
                // Logic for rebalancing if necessary
            }

            portfolio.allocations[asset.tokenAddress] = targetValueUSD;
        }

        emit Rebalanced(_investor);
    }

    function calculatePortfolioValue(uint256 _portfolioId) public view returns (uint256) {
        uint256 portfolioValueUSD = 0;
        for (uint256 i = 0; i < portfolios[_portfolioId].length; i++) {
            portfolioValueUSD = portfolioValueUSD.add(getAssetValueUSD(address(this), portfolios[_portfolioId][i]));
        }
        return portfolioValueUSD;
    }

    function getAssetValueUSD(address _investor, PortfolioAsset memory _asset) internal view returns (uint256) {
        uint256 tokenBalance = IERC20(_asset.tokenAddress).balanceOf(_investor);
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

    function withdraw() external onlyAccredited nonReentrant {
        uint256 amount = investorPortfolios[msg.sender].totalInvestment;
        require(amount > 0, "No funds to withdraw");

        investorPortfolios[msg.sender].totalInvestment = 0;
        payable(msg.sender).transfer(amount);
    }
}
