// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1404/IERC1404.sol";

contract ComplianceReporting is IERC1404, Ownable, ReentrancyGuard {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    // Compliance records
    struct ComplianceRecord {
        uint256 timestamp;
        address from;
        address to;
        uint256 value;
    }

    ComplianceRecord[] public complianceReports;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event ComplianceReported(address indexed from, address indexed to, uint256 value);

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    modifier onlyAccredited() {
        // Check if the sender is an accredited investor
        require(isAccredited(msg.sender), "Not an accredited investor");
        _;
    }

    function mint(address _to, uint256 _value) external onlyOwner {
        require(_to != address(0), "Cannot mint to zero address");
        totalSupply += _value;
        balances[_to] += _value;
        emit Transfer(address(0), _to, _value);
    }

    function transfer(address _to, uint256 _value) external onlyAccredited {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        
        // Report compliance
        complianceReports.push(ComplianceRecord(block.timestamp, msg.sender, _to, _value));
        emit Transfer(msg.sender, _to, _value);
        emit ComplianceReported(msg.sender, _to, _value);
    }

    function approve(address _spender, uint256 _value) external {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) external onlyAccredited {
        require(balances[_from] >= _value, "Insufficient balance");
        require(allowances[_from][msg.sender] >= _value, "Allowance exceeded");

        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;

        // Report compliance
        complianceReports.push(ComplianceRecord(block.timestamp, _from, _to, _value));
        emit Transfer(_from, _to, _value);
        emit ComplianceReported(_from, _to, _value);
    }

    function isAccredited(address _investor) public view returns (bool) {
        // Implement your accreditation check logic here
        return true; // Placeholder, replace with actual logic
    }

    // Implement required functions from IERC1404
    function detectTransferRestriction(address from, address to) external view override returns (byte) {
        if (!isAccredited(from) || !isAccredited(to)) {
            return "1"; // Not an accredited investor
        }
        return "0"; // No restriction
    }

    function isTransferable(address from, address to) external view override returns (bool) {
        return isAccredited(from) && isAccredited(to);
    }

    function getComplianceReports() external view returns (ComplianceRecord[] memory) {
        return complianceReports;
    }
}
