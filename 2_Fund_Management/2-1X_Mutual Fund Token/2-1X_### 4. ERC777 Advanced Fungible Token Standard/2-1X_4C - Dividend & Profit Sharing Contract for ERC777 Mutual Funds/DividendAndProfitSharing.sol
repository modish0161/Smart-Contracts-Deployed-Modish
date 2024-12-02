// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DividendAndProfitSharing is ERC777, Ownable, Pausable, ReentrancyGuard, AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(address => uint256) public profitShares;

    event ProfitDistributed(address indexed operator, uint256 totalAmount, uint256 timestamp);
    event ProfitClaimed(address indexed holder, uint256 amount);

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

    // Function to distribute profits to all token holders
    function distributeProfits() external onlyAuthorizedOperator nonReentrant whenNotPaused {
        uint256 totalSupply = totalSupply();
        require(totalSupply > 0, "No tokens minted");

        uint256 totalProfit = address(this).balance;
        require(totalProfit > 0, "No profits available for distribution");

        for (uint256 i = 0; i < holders.length; i++) {
            address holder = holders[i];
            uint256 balance = balanceOf(holder);
            if (balance > 0) {
                uint256 share = (balance * totalProfit) / totalSupply;
                profitShares[holder] += share;
            }
        }

        emit ProfitDistributed(msg.sender, totalProfit, block.timestamp);
    }

    // Function for token holders to claim their profit shares
    function claimProfit() external nonReentrant whenNotPaused {
        uint256 amount = profitShares[msg.sender];
        require(amount > 0, "No profit available for claiming");

        profitShares[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit ProfitClaimed(msg.sender, amount);
    }

    // Function to add authorized operators
    function addOperator(address account) external onlyRole(ADMIN_ROLE) {
        grantRole(OPERATOR_ROLE, account);
    }

    // Function to remove authorized operators
    function removeOperator(address account) external onlyRole(ADMIN_ROLE) {
        revokeRole(OPERATOR_ROLE, account);
    }

    // Pause the contract
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // Function to receive Ether (profits)
    receive() external payable {}

    // Withdraw funds (only in case of emergency)
    function emergencyWithdraw() external onlyRole(ADMIN_ROLE) nonReentrant {
        payable(owner()).transfer(address(this).balance);
    }

    // Array to track all holders
    address[] private holders;

    // Override the _beforeTokenTransfer to track holders
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, amount);

        if (from == address(0)) {
            // Minting tokens
            if (balanceOf(to) == 0) {
                holders.push(to);
            }
        } else if (to == address(0)) {
            // Burning tokens
            if (balanceOf(from) == amount) {
                _removeHolder(from);
            }
        } else {
            // Transferring tokens
            if (balanceOf(to) == 0) {
                holders.push(to);
            }
            if (balanceOf(from) == amount) {
                _removeHolder(from);
            }
        }
    }

    // Internal function to remove a holder from the list
    function _removeHolder(address holder) internal {
        for (uint256 i = 0; i < holders.length; i++) {
            if (holders[i] == holder) {
                holders[i] = holders[holders.length - 1];
                holders.pop();
                break;
            }
        }
    }
}
