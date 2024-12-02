// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BasicHedgeFundToken is ERC20, Ownable, ReentrancyGuard {
    uint256 public maxSupply;
    mapping(address => bool) private accreditedInvestors;

    event InvestorAccredited(address indexed investor);
    event InvestorDe-accredited(address indexed investor);

    constructor(string memory name, string memory symbol, uint256 _maxSupply) 
        ERC20(name, symbol) {
        maxSupply = _maxSupply * (10 ** decimals());
    }

    modifier onlyAccredited() {
        require(accreditedInvestors[msg.sender], "Not an accredited investor");
        _;
    }

    function mint(uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        _mint(msg.sender, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override onlyAccredited returns (bool) {
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override onlyAccredited returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    function setAccreditedInvestor(address investor, bool status) external onlyOwner {
        accreditedInvestors[investor] = status;
        if (status) {
            emit InvestorAccredited(investor);
        } else {
            emit InvestorDe-accredited(investor);
        }
    }

    function isAccreditedInvestor(address investor) external view returns (bool) {
        return accreditedInvestors[investor];
    }
}
