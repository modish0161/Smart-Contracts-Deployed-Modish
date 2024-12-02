// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC1404/ERC1404.sol";

interface IAccreditationCompliance {
    function isAccredited(address investor) external view returns (bool);
}

contract AccreditedInvestorDividendDistribution is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    // ERC1404 Security Token contract
    ERC1404 public restrictedToken;

    // ERC20 token used for dividend distribution (e.g., stablecoin)
    IERC20 public dividendToken;

    // Accreditation Compliance contract
    IAccreditationCompliance public accreditationComplianceContract;

    // Set of accredited investors
    EnumerableSet.AddressSet private accreditedInvestors;

    // Total dividends available for distribution
    uint256 public totalDividends;

    // Mapping to track claimed dividends
    mapping(address => uint256) public claimedDividends;

    // Event emitted when dividends are distributed
    event DividendsDistributed(uint256 amount);

    // Event emitted when dividends are claimed
    event DividendsClaimed(address indexed investor, uint256 amount);

    // Event emitted when accreditation compliance contract is updated
    event AccreditationComplianceContractUpdated(address indexed accreditationComplianceContract);

    constructor(
        address _restrictedToken,
        address _dividendToken,
        address _accreditationComplianceContract
    ) {
        require(_restrictedToken != address(0), "Invalid restricted token address");
        require(_dividendToken != address(0), "Invalid dividend token address");
        require(_accreditationComplianceContract != address(0), "Invalid accreditation compliance contract address");

        restrictedToken = ERC1404(_restrictedToken);
        dividendToken = IERC20(_dividendToken);
        accreditationComplianceContract = IAccreditationCompliance(_accreditationComplianceContract);
    }

    // Function to distribute dividends to all accredited investors
    function distributeDividends(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(dividendToken.balanceOf(msg.sender) >= amount, "Insufficient dividend token balance");

        totalDividends = totalDividends.add(amount);
        require(dividendToken.transferFrom(msg.sender, address(this), amount), "Dividend transfer failed");

        emit DividendsDistributed(amount);
    }

    // Function to claim dividends
    function claimDividends() external nonReentrant {
        require(accreditationComplianceContract.isAccredited(msg.sender), "Investor is not accredited");

        uint256 unclaimedDividends = getUnclaimedDividends(msg.sender);
        require(unclaimedDividends > 0, "No unclaimed dividends");

        claimedDividends[msg.sender] = claimedDividends[msg.sender].add(unclaimedDividends);
        require(dividendToken.transfer(msg.sender, unclaimedDividends), "Dividend claim transfer failed");

        emit DividendsClaimed(msg.sender, unclaimedDividends);
    }

    // Function to calculate unclaimed dividends
    function getUnclaimedDividends(address investor) public view returns (uint256) {
        uint256 holderBalance = restrictedToken.balanceOf(investor);
        uint256 totalSupply = restrictedToken.totalSupply();

        if (totalSupply == 0) return 0;

        uint256 entitledDividends = (totalDividends.mul(holderBalance)).div(totalSupply);
        uint256 claimedAmount = claimedDividends[investor];

        return entitledDividends > claimedAmount ? entitledDividends.sub(claimedAmount) : 0;
    }

    // Function to update accreditation compliance contract
    function updateAccreditationComplianceContract(address _accreditationComplianceContract) external onlyOwner {
        require(_accreditationComplianceContract != address(0), "Invalid accreditation compliance contract address");
        accreditationComplianceContract = IAccreditationCompliance(_accreditationComplianceContract);
        emit AccreditationComplianceContractUpdated(_accreditationComplianceContract);
    }

    // Function to withdraw remaining dividends (onlyOwner)
    function withdrawRemainingDividends() external onlyOwner nonReentrant {
        uint256 remainingDividends = dividendToken.balanceOf(address(this));
        require(remainingDividends > 0, "No remaining dividends");

        totalDividends = 0; // Reset total dividends
        require(dividendToken.transfer(owner(), remainingDividends), "Withdrawal transfer failed");
    }
}
