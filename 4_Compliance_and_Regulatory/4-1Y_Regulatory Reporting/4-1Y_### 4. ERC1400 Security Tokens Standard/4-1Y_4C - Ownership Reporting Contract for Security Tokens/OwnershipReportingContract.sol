// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1400/ERC1400.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract OwnershipReportingContract is ERC1400, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    // Structure for ownership change reports
    struct OwnershipReport {
        uint256 reportId;
        address from;
        address to;
        uint256 value;
        uint256 timestamp;
        bytes32 partition;
    }

    // Event for reporting ownership changes
    event OwnershipChangeReported(
        uint256 indexed reportId,
        address indexed from,
        address indexed to,
        uint256 value,
        uint256 timestamp,
        bytes32 partition
    );

    // Counter for report IDs
    Counters.Counter private _reportIdCounter;

    // Compliance and reporting thresholds
    uint256 public reportingThreshold;

    // Mapping for storing ownership change reports
    mapping(uint256 => OwnershipReport) public ownershipReports;

    // Set for compliant addresses
    EnumerableSet.AddressSet private compliantAddresses;

    // Constructor for setting up the contract
    constructor(
        string memory name,
        string memory symbol,
        address[] memory controllers,
        bytes32[] memory partitions
    ) ERC1400(name, symbol, controllers, partitions) {
        reportingThreshold = 1000 * 10**18; // Example threshold of 1000 tokens
    }

    // Modifier to restrict access to compliant addresses
    modifier onlyCompliant() {
        require(isCompliant(msg.sender), "Caller is not compliant");
        _;
    }

    // Function to check if an address is compliant
    function isCompliant(address account) public view returns (bool) {
        return compliantAddresses.contains(account);
    }

    // Function to add compliant addresses
    function addCompliantAddress(address account) external onlyOwner {
        require(!compliantAddresses.contains(account), "Address is already compliant");
        compliantAddresses.add(account);
    }

    // Function to remove compliant addresses
    function removeCompliantAddress(address account) external onlyOwner {
        require(compliantAddresses.contains(account), "Address is not compliant");
        compliantAddresses.remove(account);
    }

    // Function to set the reporting threshold
    function setReportingThreshold(uint256 threshold) external onlyOwner {
        reportingThreshold = threshold;
    }

    // Function to report ownership changes
    function reportOwnershipChange(
        address from,
        address to,
        uint256 value,
        bytes32 partition
    ) internal whenNotPaused {
        uint256 newReportId = _reportIdCounter.current();

        OwnershipReport memory newReport = OwnershipReport({
            reportId: newReportId,
            from: from,
            to: to,
            value: value,
            timestamp: block.timestamp,
            partition: partition
        });

        ownershipReports[newReportId] = newReport;
        emit OwnershipChangeReported(newReportId, from, to, value, block.timestamp, partition);

        _reportIdCounter.increment();
    }

    // Override ERC1400 transferByPartition to include reporting logic
    function transferByPartition(
        bytes32 partition,
        address to,
        uint256 value,
        bytes calldata data
    ) public override onlyCompliant returns (bytes32) {
        bytes32 result = super.transferByPartition(partition, to, value, data);

        if (value >= reportingThreshold) {
            reportOwnershipChange(msg.sender, to, value, partition);
        }

        return result;
    }

    // Pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    // Unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    // Function to get the total number of reports
    function getTotalReports() external view returns (uint256) {
        return _reportIdCounter.current();
    }

    // Function to get a report by ID
    function getReportById(uint256 reportId) external view returns (OwnershipReport memory) {
        return ownershipReports[reportId];
    }
}
