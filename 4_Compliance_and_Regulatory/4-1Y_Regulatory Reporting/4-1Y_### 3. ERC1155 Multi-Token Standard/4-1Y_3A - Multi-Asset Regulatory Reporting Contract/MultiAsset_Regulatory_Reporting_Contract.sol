// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract MultiAssetRegulatoryReporting is ERC1155, Pausable, AccessControl, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");
    bytes32 public constant REPORTER_ROLE = keccak256("REPORTER_ROLE");

    EnumerableSet.AddressSet private compliantUsers;
    mapping(address => bool) public hasPassedKYC;
    mapping(uint256 => mapping(address => uint256)) private userHoldings;

    event UserKYCUpdated(address indexed user, bool status);
    event TransactionReported(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId,
        uint256 amount,
        string assetType,
        uint256 timestamp
    );
    event HoldingReported(address indexed user, uint256 indexed tokenId, uint256 amount);

    modifier onlyComplianceOfficer() {
        require(hasRole(COMPLIANCE_OFFICER_ROLE, _msgSender()), "Caller is not a compliance officer");
        _;
    }

    modifier onlyReporter() {
        require(hasRole(REPORTER_ROLE, _msgSender()), "Caller is not a reporter");
        _;
    }

    constructor(string memory uri) ERC1155(uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_OFFICER_ROLE, msg.sender);
        _setupRole(REPORTER_ROLE, msg.sender);
    }

    /**
     * @notice Updates the KYC status of a user.
     * @param user The address of the user.
     * @param status The KYC status (true for passed, false for not passed).
     */
    function updateKYCStatus(address user, bool status) external onlyComplianceOfficer {
        hasPassedKYC[user] = status;
        if (status) {
            compliantUsers.add(user);
        } else {
            compliantUsers.remove(user);
        }
        emit UserKYCUpdated(user, status);
    }

    /**
     * @notice Mints tokens to a user.
     * @param to The address to mint tokens to.
     * @param id The token id to mint.
     * @param amount The amount of tokens to mint.
     * @param data Additional data.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyComplianceOfficer {
        require(hasPassedKYC[to], "User has not passed KYC");
        _mint(to, id, amount, data);
        userHoldings[id][to] += amount;
    }

    /**
     * @notice Burns tokens from a user.
     * @param from The address to burn tokens from.
     * @param id The token id to burn.
     * @param amount The amount of tokens to burn.
     */
    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public onlyComplianceOfficer {
        _burn(from, id, amount);
        userHoldings[id][from] -= amount;
    }

    /**
     * @notice Records a token transfer and reports it if necessary.
     * @param from The address of the sender.
     * @param to The address of the receiver.
     * @param id The token id being transferred.
     * @param amount The amount of tokens being transferred.
     * @param data Additional data.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            if (from != address(0)) {
                userHoldings[id][from] -= amount;
                emit TransactionReported(from, to, id, amount, _getAssetType(id), block.timestamp);
            }
            if (to != address(0)) {
                userHoldings[id][to] += amount;
            }
        }
    }

    /**
     * @notice Reports the holdings of all compliant users.
     */
    function reportHoldings() external onlyReporter {
        for (uint256 i = 0; i < compliantUsers.length(); i++) {
            address user = compliantUsers.at(i);
            for (uint256 j = 0; j < ids.length; j++) {
                uint256 tokenId = ids[j];
                uint256 amount = userHoldings[tokenId][user];
                if (amount > 0) {
                    emit HoldingReported(user, tokenId, amount);
                }
            }
        }
    }

    /**
     * @notice Pauses all token transfers. Can only be called by a compliance officer.
     */
    function pause() external onlyComplianceOfficer {
        _pause();
    }

    /**
     * @notice Unpauses all token transfers. Can only be called by a compliance officer.
     */
    function unpause() external onlyComplianceOfficer {
        _unpause();
    }

    /**
     * @notice Gets the asset type for a given token ID.
     * @param id The token ID.
     * @return The asset type as a string.
     */
    function _getAssetType(uint256 id) internal pure returns (string memory) {
        // Define logic to categorize asset types based on ID, e.g., "Fungible", "NFT", etc.
        if (id >= 1000000) {
            return "NFT";
        } else {
            return "Fungible";
        }
    }
}
