// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC4626/ERC4626.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract YieldDrivenDividendDistribution is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    IERC4626 public vaultToken;          // ERC4626 Tokenized Vault
    IERC20 public yieldToken;            // Token used for distributing yields (e.g., stablecoin)

    uint256 public totalYields;          // Total yields available for distribution
    mapping(address => uint256) public claimedYields; // Track claimed yields for each investor

    event YieldsDistributed(uint256 amount);          // Event emitted when yields are distributed
    event YieldsClaimed(address indexed investor, uint256 amount); // Event emitted when yields are claimed

    constructor(address _vaultToken, address _yieldToken) {
        require(_vaultToken != address(0), "Invalid vault token address");
        require(_yieldToken != address(0), "Invalid yield token address");

        vaultToken = IERC4626(_vaultToken);
        yieldToken = IERC20(_yieldToken);
    }

    // Function to distribute yields to all vault participants
    function distributeYields(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(yieldToken.balanceOf(msg.sender) >= amount, "Insufficient yield token balance");

        totalYields = totalYields.add(amount);
        require(yieldToken.transferFrom(msg.sender, address(this), amount), "Yield transfer failed");

        emit YieldsDistributed(amount);
    }

    // Function to claim yields
    function claimYields() external nonReentrant {
        uint256 unclaimedYields = getUnclaimedYields(msg.sender);
        require(unclaimedYields > 0, "No unclaimed yields");

        claimedYields[msg.sender] = claimedYields[msg.sender].add(unclaimedYields);
        require(yieldToken.transfer(msg.sender, unclaimedYields), "Yield claim transfer failed");

        emit YieldsClaimed(msg.sender, unclaimedYields);
    }

    // Function to calculate unclaimed yields for an investor
    function getUnclaimedYields(address investor) public view returns (uint256) {
        uint256 vaultBalance = vaultToken.balanceOf(investor);
        uint256 totalVaultSupply = vaultToken.totalSupply();

        if (totalVaultSupply == 0) return 0;

        uint256 entitledYields = (totalYields.mul(vaultBalance)).div(totalVaultSupply);
        uint256 claimedAmount = claimedYields[investor];

        return entitledYields > claimedAmount ? entitledYields.sub(claimedAmount) : 0;
    }

    // Function to withdraw remaining yields (onlyOwner)
    function withdrawRemainingYields() external onlyOwner nonReentrant {
        uint256 remainingYields = yieldToken.balanceOf(address(this));
        require(remainingYields > 0, "No remaining yields");

        totalYields = 0; // Reset total yields
        require(yieldToken.transfer(owner(), remainingYields), "Withdrawal transfer failed");
    }
}
