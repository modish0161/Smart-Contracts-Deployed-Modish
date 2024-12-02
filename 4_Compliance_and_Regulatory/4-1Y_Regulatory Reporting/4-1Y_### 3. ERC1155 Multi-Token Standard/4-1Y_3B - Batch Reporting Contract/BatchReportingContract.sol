// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract BatchReportingContract is ERC1155, Pausable, AccessControl, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");
    bytes32 public constant REPORTER_ROLE = keccak256("REPORTER_ROLE");

    struct Report {
        address from;
        address to;
        uint256 id;
        uint256 amount;
        string assetType;
        uint256 timestamp;
    }

    Report[] public batchReports;

    event BatchReportsSubmitted(uint256 indexed batchId, uint256 reportCount);
    event TransactionReported(address indexed from, address indexed to, uint256 indexed id, uint256 amount, string assetType, uint256 timestamp);
    event HoldingReported(address indexed user, uint256 indexed id, uint256 amount);

    EnumerableSet.AddressSet private compliantUsers;
    mapping(address => bool) public hasPassedKYC;

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
    }

    /**
     * @notice Batch submit reports for regulatory compliance.
     * @param from Array of addresses of senders.
     * @param to Array of addresses of receivers.
     * @param ids Array of token ids being transferred.
     * @param amounts Array of amounts being transferred.
     * @param assetTypes Array of asset types being transferred.
     */
    function submitBatchReports(
        address[] calldata from,
        address[] calldata to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        string[] calldata assetTypes
    ) external onlyReporter nonReentrant whenNotPaused {
        require(
            from.length == to.length &&
            to.length == ids.length &&
            ids.length == amounts.length &&
            amounts.length == assetTypes.length,
            "BatchReportingContract: Array lengths do not match"
        );

        for (uint256 i = 0; i < from.length; i++) {
            batchReports.push(Report({
                from: from[i],
                to: to[i],
                id: ids[i],
                amount: amounts[i],
                assetType: assetTypes[i],
                timestamp: block.timestamp
            }));
            emit TransactionReported(from[i], to[i], ids[i], amounts[i], assetTypes[i], block.timestamp);
        }

        emit BatchReportsSubmitted(batchReports.length, from.length);
    }

    /**
     * @notice Gets the number of reports in a batch.
     * @return The number of reports in the batch.
     */
    function getBatchReportsCount() external view returns (uint256) {
        return batchReports.length;
    }

    /**
     * @notice Pauses all batch reporting and token transfers. Can only be called by a compliance officer.
     */
    function pause() external onlyComplianceOfficer {
        _pause();
    }

    /**
     * @notice Unpauses all batch reporting and token transfers. Can only be called by a compliance officer.
     */
    function unpause() external onlyComplianceOfficer {
        _unpause();
    }

    /**
     * @notice Batch mint tokens to multiple users.
     * @param to The array of addresses to mint tokens to.
     * @param ids The array of token ids to mint.
     * @param amounts The array of amounts to mint.
     * @param data Additional data.
     */
    function mintBatch(
        address[] calldata to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) public onlyComplianceOfficer {
        require(
            to.length == ids.length && ids.length == amounts.length,
            "BatchReportingContract: Array lengths do not match"
        );

        for (uint256 i = 0; i < to.length; i++) {
            require(hasPassedKYC[to[i]], "User has not passed KYC");
            _mint(to[i], ids[i], amounts[i], data);
        }
    }

    /**
     * @notice Batch burn tokens from multiple users.
     * @param from The array of addresses to burn tokens from.
     * @param ids The array of token ids to burn.
     * @param amounts The array of amounts to burn.
     */
    function burnBatch(
        address[] calldata from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) public onlyComplianceOfficer {
        require(
            from.length == ids.length && ids.length == amounts.length,
            "BatchReportingContract: Array lengths do not match"
        );

        for (uint256 i = 0; i < from.length; i++) {
            _burn(from[i], ids[i], amounts[i]);
        }
    }

    /**
     * @notice A utility function to convert an array of `uint256` values into a string.
     * @param array The array of `uint256` values.
     * @return The concatenated string of all array values.
     */
    function arrayToString(uint256[] memory array) internal pure returns (string memory) {
        bytes memory result;
        for (uint256 i = 0; i < array.length; i++) {
            result = abi.encodePacked(result, uint2str(array[i]), ",");
        }
        return string(result);
    }

    /**
     * @notice A utility function to convert a `uint256` value into a string.
     * @param _i The `uint256` value.
     * @return The string representation of the `uint256` value.
     */
    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
