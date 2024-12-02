// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1404/IERC1404.sol";

contract RestrictedHedgeFundToken is IERC1404, Ownable, ReentrancyGuard {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    // Whitelist and blacklist
    mapping(address => bool) public whitelist; // Whitelisted investors
    mapping(address => bool) public blacklist; // Blacklisted investors

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Whitelisted(address indexed investor);
    event Blacklisted(address indexed investor);
    event RemovedFromWhitelist(address indexed investor);
    event RemovedFromBlacklist(address indexed investor);

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Not an authorized investor");
        _;
    }

    modifier notBlacklisted() {
        require(!blacklist[msg.sender], "Investor is blacklisted");
        _;
    }

    function mint(address _to, uint256 _value) external onlyOwner {
        require(_to != address(0), "Cannot mint to zero address");
        totalSupply += _value;
        balances[_to] += _value;
        emit Transfer(address(0), _to, _value);
    }

    function transfer(address _to, uint256 _value) external notBlacklisted {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        require(whitelist[_to], "Recipient is not whitelisted");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }

    function approve(address _spender, uint256 _value) external {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) external notBlacklisted {
        require(balances[_from] >= _value, "Insufficient balance");
        require(allowances[_from][msg.sender] >= _value, "Allowance exceeded");
        require(whitelist[_to], "Recipient is not whitelisted");

        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
    }

    function addToWhitelist(address _investor) external onlyOwner {
        require(!whitelist[_investor], "Investor is already whitelisted");
        whitelist[_investor] = true;
        emit Whitelisted(_investor);
    }

    function removeFromWhitelist(address _investor) external onlyOwner {
        require(whitelist[_investor], "Investor is not whitelisted");
        whitelist[_investor] = false;
        emit RemovedFromWhitelist(_investor);
    }

    function addToBlacklist(address _investor) external onlyOwner {
        require(!blacklist[_investor], "Investor is already blacklisted");
        blacklist[_investor] = true;
        emit Blacklisted(_investor);
    }

    function removeFromBlacklist(address _investor) external onlyOwner {
        require(blacklist[_investor], "Investor is not blacklisted");
        blacklist[_investor] = false;
        emit RemovedFromBlacklist(_investor);
    }

    // Implement required functions from IERC1404
    function detectTransferRestriction(address from, address to) external view override returns (byte) {
        if (blacklist[from] || blacklist[to]) {
            return "5"; // Blacklisted
        }
        if (!whitelist[from] || !whitelist[to]) {
            return "1"; // Not whitelisted
        }
        return "0"; // No restriction
    }

    function isTransferable(address from, address to) external view override returns (bool) {
        return !blacklist[from] && !blacklist[to] && whitelist[from] && whitelist[to];
    }
}
