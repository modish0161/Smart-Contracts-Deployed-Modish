// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract TransactionVolumeReporting is ERC20, Ownable, Pausable, ReentrancyGuard, AccessControl {
    bytes32 public constant REPORTING_ROLE = keccak256("REPORTING_ROLE");

    struct TransactionVolume {
        address account;
        uint256 totalVolume;
    }

    mapping(address => uint256) private _transactionVolume;
    address[] private _reportedAddresses;

    event VolumeReported(address indexed reporter, uint256 timestamp, uint256 totalVolume);
    event TransactionTracked(address indexed from, address indexed to, uint256 amount);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(REPORTING_ROLE, msg.sender);
    }

    /**
     * @notice Override the transfer function to track transaction volumes.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override whenNotPaused {
        super._transfer(sender, recipient, amount);
        _trackTransactionVolume(sender, amount);
        _trackTransactionVolume(recipient, amount);
        emit TransactionTracked(sender, recipient, amount);
    }

    /**
     * @notice Tracks the transaction volume for a given address.
     * @param account The address to track volume for.
     * @param amount The transaction amount to add to the volume.
     */
    function _trackTransactionVolume(address account, uint256 amount) internal {
        if (_transactionVolume[account] == 0) {
            _reportedAddresses.push(account);
        }
        _transactionVolume[account] += amount;
    }

    /**
     * @notice Allows regulatory authorities to report transaction volumes.
     * @return TransactionVolume[] Array of all recorded transaction volumes.
     */
    function generateVolumeReport() external onlyRole(REPORTING_ROLE) nonReentrant returns (TransactionVolume[] memory) {
        uint256 length = _reportedAddresses.length;
        TransactionVolume[] memory volumes = new TransactionVolume[](length);

        for (uint256 i = 0; i < length; i++) {
            address account = _reportedAddresses[i];
            volumes[i] = TransactionVolume({
                account: account,
                totalVolume: _transactionVolume[account]
            });
        }
        
        emit VolumeReported(msg.sender, block.timestamp, length);
        return volumes;
    }

    /**
     * @notice Pauses all token transfers. Can only be called by the owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses all token transfers. Can only be called by the owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Grants reporting role to a new address.
     * @param account The address to grant the role to.
     */
    function grantReportingRole(address account) external onlyOwner {
        grantRole(REPORTING_ROLE, account);
    }

    /**
     * @notice Revokes reporting role from an address.
     * @param account The address to revoke the role from.
     */
    function revokeReportingRole(address account) external onlyOwner {
        revokeRole(REPORTING_ROLE, account);
    }
}
