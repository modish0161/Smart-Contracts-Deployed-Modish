// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

contract SecurityTokenDividendDistribution is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // ERC1400 Security Token contract
    IERC1400 public securityToken;

    // ERC20 token used for dividend distribution (e.g., stablecoin)
    IERC20 public dividendToken;

    // Total dividends available for each tranche
    mapping(bytes32 => uint256) public totalDividends;

    // Dividends claimed by each address for each tranche
    mapping(address => mapping(bytes32 => uint256)) public claimedDividends;

    // Event emitted when dividends are distributed
    event DividendsDistributed(bytes32 indexed tranche, uint256 amount);

    // Event emitted when dividends are claimed
    event DividendsClaimed(address indexed holder, bytes32 indexed tranche, uint256 amount);

    constructor(address _securityToken, address _dividendToken) {
        require(_securityToken != address(0), "Invalid security token address");
        require(_dividendToken != address(0), "Invalid dividend token address");

        securityToken = IERC1400(_securityToken);
        dividendToken = IERC20(_dividendToken);
    }

    // Function to distribute dividends for a specific tranche
    function distributeDividends(bytes32 tranche, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(dividendToken.balanceOf(msg.sender) >= amount, "Insufficient dividend token balance");

        totalDividends[tranche] = totalDividends[tranche].add(amount);
        require(dividendToken.transferFrom(msg.sender, address(this), amount), "Dividend transfer failed");

        emit DividendsDistributed(tranche, amount);
    }

    // Function to claim dividends for a specific tranche
    function claimDividends(bytes32 tranche) external nonReentrant {
        uint256 holderBalance = securityToken.balanceOfByPartition(tranche, msg.sender);
        require(holderBalance > 0, "No tokens to claim dividends for");

        uint256 unclaimedDividends = getUnclaimedDividends(msg.sender, tranche);
        require(unclaimedDividends > 0, "No unclaimed dividends");

        claimedDividends[msg.sender][tranche] = claimedDividends[msg.sender][tranche].add(unclaimedDividends);
        require(dividendToken.transfer(msg.sender, unclaimedDividends), "Dividend claim transfer failed");

        emit DividendsClaimed(msg.sender, tranche, unclaimedDividends);
    }

    // Function to calculate unclaimed dividends for a holder and tranche
    function getUnclaimedDividends(address holder, bytes32 tranche) public view returns (uint256) {
        uint256 totalDividendsForTranche = totalDividends[tranche];
        uint256 holderBalance = securityToken.balanceOfByPartition(tranche, holder);
        uint256 totalSupply = securityToken.totalSupplyByPartition(tranche);

        if (totalSupply == 0) return 0;

        uint256 entitledDividends = (totalDividendsForTranche.mul(holderBalance)).div(totalSupply);
        uint256 claimedAmount = claimedDividends[holder][tranche];

        return entitledDividends > claimedAmount ? entitledDividends.sub(claimedAmount) : 0;
    }
}
