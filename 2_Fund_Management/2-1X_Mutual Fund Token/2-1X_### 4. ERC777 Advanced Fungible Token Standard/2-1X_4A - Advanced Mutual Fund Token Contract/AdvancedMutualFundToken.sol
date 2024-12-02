// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AdvancedMutualFundToken is ERC777, Ownable, Pausable, ReentrancyGuard, AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    event TokensMinted(address indexed operator, address indexed to, uint256 amount);
    event TokensBurned(address indexed operator, address indexed from, uint256 amount);
    event TokensSentByOperator(address indexed operator, address indexed from, address indexed to, uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators
    ) ERC777(name, symbol, defaultOperators) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    // Override required by Solidity for ERC777 and AccessControl.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal override(ERC777) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, amount);
    }

    // Operator Mint function to mint tokens on behalf of the fund.
    function mint(
        address to,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public nonReentrant onlyRole(OPERATOR_ROLE) {
        _mint(to, amount, data, operatorData);
        emit TokensMinted(msg.sender, to, amount);
    }

    // Operator Burn function to burn tokens on behalf of the fund.
    function burn(
        address from,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public nonReentrant onlyRole(OPERATOR_ROLE) {
        _burn(from, amount, data, operatorData);
        emit TokensBurned(msg.sender, from, amount);
    }

    // Operator function to send tokens on behalf of the token holder.
    function operatorSend(
        address from,
        address to,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public override nonReentrant onlyRole(OPERATOR_ROLE) {
        super.operatorSend(from, to, amount, data, operatorData);
        emit TokensSentByOperator(msg.sender, from, to, amount);
    }

    // Pause the contract
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // Grant role function with checks
    function grantOperatorRole(address account) external onlyRole(ADMIN_ROLE) {
        grantRole(OPERATOR_ROLE, account);
    }

    // Revoke role function with checks
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
