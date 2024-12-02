// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1404/IERC1404.sol";

contract AccreditedInvestorVerification is IERC1404, Ownable, ReentrancyGuard {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    // Whitelist of accredited investors
    mapping(address => bool) public accreditedInvestors; 

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event InvestorVerified(address indexed investor);
    event InvestorRevoked(address indexed investor);

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    modifier onlyAccredited() {
        require(accreditedInvestors[msg.sender], "Not an accredited investor");
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
        emit Transfer(msg.sender, _to, _value);
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
        emit Transfer(_from, _to, _value);
    }

    function verifyInvestor(address _investor) external onlyOwner {
        require(!accreditedInvestors[_investor], "Investor already verified");
        accreditedInvestors[_investor] = true;
        emit InvestorVerified(_investor);
    }

    function revokeInvestor(address _investor) external onlyOwner {
        require(accreditedInvestors[_investor], "Investor not verified");
        accreditedInvestors[_investor] = false;
        emit InvestorRevoked(_investor);
    }

    // Implement required functions from IERC1404
    function detectTransferRestriction(address from, address to) external view override returns (byte) {
        if (!accreditedInvestors[from] || !accreditedInvestors[to]) {
            return "1"; // Not an accredited investor
        }
        return "0"; // No restriction
    }

    function isTransferable(address from, address to) external view override returns (bool) {
        return accreditedInvestors[from] && accreditedInvestors[to];
    }
}
