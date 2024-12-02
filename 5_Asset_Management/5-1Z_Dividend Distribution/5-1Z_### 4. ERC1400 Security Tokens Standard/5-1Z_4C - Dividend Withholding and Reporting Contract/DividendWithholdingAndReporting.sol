// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

interface ITaxWithholding {
    function calculateWithholding(address investor, uint256 amount) external view returns (uint256);
}

interface ICompliance {
    function isCompliant(address investor) external view returns (bool);
}

contract DividendWithholdingAndReporting is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    // ERC1400 Security Token contract
    IERC1400 public securityToken;

    // ERC20 token used for dividend distribution (e.g., stablecoin)
    IERC20 public dividendToken;

    // Tax withholding contract
    ITaxWithholding public taxWithholdingContract;

    // Compliance contract
    ICompliance public complianceContract;

    // Set of compliant investors
    EnumerableSet.AddressSet private compliantInvestors;

    // Total dividends available for distribution
    uint256 public totalDividends;

    // Mapping to track claimed dividends
    mapping(address => uint256) public claimedDividends;

    // Event emitted when dividends are distributed
    event DividendsDistributed(uint256 amount);

    // Event emitted when dividends are claimed
    event DividendsClaimed(address indexed investor, uint256 grossAmount, uint256 netAmount, uint256 withheldTax);

    // Event emitted when tax withholding contract is updated
    event TaxWithholdingContractUpdated(address indexed taxWithholdingContract);

    // Event emitted when compliance contract is updated
    event ComplianceContractUpdated(address indexed complianceContract);

    constructor(
        address _securityToken,
        address _dividendToken,
        address _taxWithholdingContract,
        address _complianceContract
    ) {
        require(_securityToken != address(0), "Invalid security token address");
        require(_dividendToken != address(0), "Invalid dividend token address");
        require(_taxWithholdingContract != address(0), "Invalid tax withholding contract address");
        require(_complianceContract != address(0), "Invalid compliance contract address");

        securityToken = IERC1400(_securityToken);
        dividendToken = IERC20(_dividendToken);
        taxWithholdingContract = ITaxWithholding(_taxWithholdingContract);
        complianceContract = ICompliance(_complianceContract);
    }

    // Function to distribute dividends to all compliant investors
    function distributeDividends(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(dividendToken.balanceOf(msg.sender) >= amount, "Insufficient dividend token balance");

        totalDividends = totalDividends.add(amount);
        require(dividendToken.transferFrom(msg.sender, address(this), amount), "Dividend transfer failed");

        emit DividendsDistributed(amount);
    }

    // Function to claim dividends
    function claimDividends() external nonReentrant {
        require(complianceContract.isCompliant(msg.sender), "Investor is not compliant");

        uint256 unclaimedDividends = getUnclaimedDividends(msg.sender);
        require(unclaimedDividends > 0, "No unclaimed dividends");

        uint256 withheldTax = taxWithholdingContract.calculateWithholding(msg.sender, unclaimedDividends);
        uint256 netDividends = unclaimedDividends.sub(withheldTax);

        claimedDividends[msg.sender] = claimedDividends[msg.sender].add(unclaimedDividends);
        require(dividendToken.transfer(msg.sender, netDividends), "Dividend claim transfer failed");
        require(dividendToken.transfer(owner(), withheldTax), "Tax withholding transfer failed");

        emit DividendsClaimed(msg.sender, unclaimedDividends, netDividends, withheldTax);
    }

    // Function to calculate unclaimed dividends
    function getUnclaimedDividends(address investor) public view returns (uint256) {
        uint256 holderBalance = securityToken.balanceOf(investor);
        uint256 totalSupply = securityToken.totalSupply();

        if (totalSupply == 0) return 0;

        uint256 entitledDividends = (totalDividends.mul(holderBalance)).div(totalSupply);
        uint256 claimedAmount = claimedDividends[investor];

        return entitledDividends > claimedAmount ? entitledDividends.sub(claimedAmount) : 0;
    }

    // Function to update tax withholding contract
    function updateTaxWithholdingContract(address _taxWithholdingContract) external onlyOwner {
        require(_taxWithholdingContract != address(0), "Invalid tax withholding contract address");
        taxWithholdingContract = ITaxWithholding(_taxWithholdingContract);
        emit TaxWithholdingContractUpdated(_taxWithholdingContract);
    }

    // Function to update compliance contract
    function updateComplianceContract(address _complianceContract) external onlyOwner {
        require(_complianceContract != address(0), "Invalid compliance contract address");
        complianceContract = ICompliance(_complianceContract);
        emit ComplianceContractUpdated(_complianceContract);
    }

    // Function to withdraw remaining dividends (onlyOwner)
    function withdrawRemainingDividends() external onlyOwner nonReentrant {
        uint256 remainingDividends = dividendToken.balanceOf(address(this));
        require(remainingDividends > 0, "No remaining dividends");

        totalDividends = 0; // Reset total dividends
        require(dividendToken.transfer(owner(), remainingDividends), "Withdrawal transfer failed");
    }
}
