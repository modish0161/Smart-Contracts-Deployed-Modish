// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract OperatorControlledRedemption is ERC777, Ownable, Pausable, ReentrancyGuard, AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(address => uint256) public redemptionRequests;
    uint256 public totalRedeemed;

    event RedemptionRequested(address indexed holder, uint256 amount);
    event RedemptionProcessed(address indexed operator, address indexed holder, uint256 amount, string underlyingAssetDetails);

    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators
    ) ERC777(name, symbol, defaultOperators) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    // Modifier to check if the caller is an authorized operator
    modifier onlyAuthorizedOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Caller is not an authorized operator");
        _;
    }

    // Function to request redemption by token holder
    function requestRedemption(uint256 amount) external whenNotPaused {
        require(balanceOf(msg.sender) >= amount, "Insufficient token balance");
        redemptionRequests[msg.sender] += amount;
        emit RedemptionRequested(msg.sender, amount);
    }

    // Operator function to process redemption on behalf of token holders
    function processRedemption(
        address holder,
        uint256 amount,
        string memory underlyingAssetDetails
    ) external onlyAuthorizedOperator nonReentrant whenNotPaused {
        require(redemptionRequests[holder] >= amount, "Redemption amount exceeds request");
        redemptionRequests[holder] -= amount;
        totalRedeemed += amount;

        _burn(holder, amount, "", "");
        emit RedemptionProcessed(msg.sender, holder, amount, underlyingAssetDetails);
    }

    // Pause the contract
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // Grant operator role
    function grantOperatorRole(address account) external onlyRole(ADMIN_ROLE) {
        grantRole(OPERATOR_ROLE, account);
    }

    // Revoke operator role
    function revokeOperatorRole(address account) external onlyRole(ADMIN_ROLE) {
        revokeRole(OPERATOR_ROLE, account);
    }

    // Function to receive Ether
    receive() external payable {}

    // Withdraw Ether from the contract
    function withdrawFunds(uint256 amount) external onlyRole(ADMIN_ROLE) nonReentrant {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(owner()).transfer(amount);
    }
}
