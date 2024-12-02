// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1404/IERC1404.sol";

contract TaxWithholding is IERC1404, Ownable, ReentrancyGuard {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    // Tax rate (in basis points, e.g., 200 means 2%)
    uint256 public taxRate;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TaxWithheld(address indexed from, uint256 amount);
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _taxRate) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        taxRate = _taxRate; // Set the initial tax rate
    }

    modifier onlyAccredited() {
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
        uint256 taxAmount = calculateTax(_value);
        uint256 amountAfterTax = _value - taxAmount;

        balances[msg.sender] -= _value;
        balances[_to] += amountAfterTax;

        // Emit tax withholding event
        emit TaxWithheld(msg.sender, taxAmount);
        emit Transfer(msg.sender, _to, amountAfterTax);
    }

    function approve(address _spender, uint256 _value) external {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) external onlyAccredited {
        require(balances[_from] >= _value, "Insufficient balance");
        require(allowances[_from][msg.sender] >= _value, "Allowance exceeded");

        uint256 taxAmount = calculateTax(_value);
        uint256 amountAfterTax = _value - taxAmount;

        balances[_from] -= _value;
        balances[_to] += amountAfterTax;
        allowances[_from][msg.sender] -= _value;

        // Emit tax withholding event
        emit TaxWithheld(_from, taxAmount);
        emit Transfer(_from, _to, amountAfterTax);
    }

    function calculateTax(uint256 _amount) public view returns (uint256) {
        return (_amount * taxRate) / 10000; // Assuming taxRate is in basis points
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
}
