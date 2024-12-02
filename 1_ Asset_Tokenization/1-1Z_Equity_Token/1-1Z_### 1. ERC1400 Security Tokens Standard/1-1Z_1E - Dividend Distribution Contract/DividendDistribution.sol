// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

/// @title Dividend Distribution Contract
/// @notice This contract automatically distributes dividends to equity token holders based on their shareholdings in an ERC1400 compliant security token.
contract DividendDistribution is AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

    IERC1400 public equityToken;
    IERC20 public stablecoin;

    mapping(address => uint256) public dividendsBalance;
    uint256 public totalDividendsDistributed;

    event DividendDeposited(address indexed sender, uint256 amount);
    event DividendClaimed(address indexed holder, uint256 amount);

    /// @notice Constructor to initialize the contract
    /// @param _equityToken Address of the ERC1400 token representing the equity
    /// @param _stablecoin Address of the ERC20 stablecoin used for dividend distribution
    constructor(address _equityToken, address _stablecoin) {
        require(_equityToken != address(0), "Invalid equity token address");
        require(_stablecoin != address(0), "Invalid stablecoin address");

        equityToken = IERC1400(_equityToken);
        stablecoin = IERC20(_stablecoin);

        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DISTRIBUTOR_ROLE, msg.sender);
    }

    /// @notice Deposits dividends into the contract for distribution
    /// @param amount Amount of stablecoin to deposit as dividends
    function depositDividends(uint256 amount) external onlyRole(DISTRIBUTOR_ROLE) nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        stablecoin.transferFrom(msg.sender, address(this), amount);

        uint256 totalSupply = equityToken.totalSupply();
        require(totalSupply > 0, "No equity tokens in circulation");

        for (uint256 i = 0; i < totalSupply; i++) {
            address holder = equityToken.holderAt(i);
            uint256 holderBalance = equityToken.balanceOf(holder);
            uint256 holderShare = (holderBalance * amount) / totalSupply;

            dividendsBalance[holder] += holderShare;
        }

        totalDividendsDistributed += amount;
        emit DividendDeposited(msg.sender, amount);
    }

    /// @notice Claims dividends for the caller
    function claimDividends() external nonReentrant {
        uint256 dividends = dividendsBalance[msg.sender];
        require(dividends > 0, "No dividends available for claim");

        dividendsBalance[msg.sender] = 0;
        stablecoin.transfer(msg.sender, dividends);

        emit DividendClaimed(msg.sender, dividends);
    }

    /// @notice Returns the available dividends for the caller
    /// @return amount of dividends available to claim
    function getAvailableDividends() external view returns (uint256) {
        return dividendsBalance[msg.sender];
    }

    /// @notice Adds a new admin to the contract
    /// @dev Only callable by an existing admin
    /// @param newAdmin Address of the new admin
    function addAdmin(address newAdmin) external onlyRole(ADMIN_ROLE) {
        grantRole(ADMIN_ROLE, newAdmin);
    }

    /// @notice Removes an admin from the contract
    /// @dev Only callable by an existing admin
    /// @param admin Address of the admin to remove
    function removeAdmin(address admin) external onlyRole(ADMIN_ROLE) {
        revokeRole(ADMIN_ROLE, admin);
    }

    /// @notice Adds a new distributor to the contract
    /// @dev Only callable by an admin
    /// @param newDistributor Address of the new distributor
    function addDistributor(address newDistributor) external onlyRole(ADMIN_ROLE) {
        grantRole(DISTRIBUTOR_ROLE, newDistributor);
    }

    /// @notice Removes a distributor from the contract
    /// @dev Only callable by an admin
    /// @param distributor Address of the distributor to remove
    function removeDistributor(address distributor) external onlyRole(ADMIN_ROLE) {
        revokeRole(DISTRIBUTOR_ROLE, distributor);
    }

    /// @notice Emergency withdrawal of all stablecoins by admin
    /// @dev Only callable by an admin in case of emergency
    function emergencyWithdraw() external onlyRole(ADMIN_ROLE) {
        uint256 contractBalance = stablecoin.balanceOf(address(this));
        stablecoin.transfer(msg.sender, contractBalance);
    }
}
