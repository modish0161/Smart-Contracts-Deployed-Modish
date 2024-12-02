// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

contract LockUpPeriodContract is Ownable, ReentrancyGuard {
    struct Investor {
        uint256 shares;
        uint256 lockUpEndTime;
        bool accredited;
    }

    mapping(address => Investor) public investors;

    event InvestorAdded(address indexed investor, uint256 shares, bool accredited, uint256 lockUpEndTime);
    event LockUpUpdated(address indexed investor, uint256 lockUpEndTime);
    event InvestorRemoved(address indexed investor);

    modifier onlyAccreditedInvestor() {
        require(investors[msg.sender].accredited, "Not an accredited investor");
        _;
    }

    modifier lockUpNotActive() {
        require(block.timestamp >= investors[msg.sender].lockUpEndTime, "Lock-up period active");
        _;
    }

    constructor() {}

    function addInvestor(address _investor, uint256 _shares, bool _accredited, uint256 _lockUpPeriod) external onlyOwner {
        require(_shares > 0, "Shares must be greater than zero");
        uint256 lockUpEndTime = block.timestamp + _lockUpPeriod;
        investors[_investor] = Investor(_shares, lockUpEndTime, _accredited);
        emit InvestorAdded(_investor, _shares, _accredited, lockUpEndTime);
    }

    function removeInvestor(address _investor) external onlyOwner {
        delete investors[_investor];
        emit InvestorRemoved(_investor);
    }

    function updateLockUpPeriod(address _investor, uint256 _newLockUpPeriod) external onlyOwner {
        investors[_investor].lockUpEndTime = block.timestamp + _newLockUpPeriod;
        emit LockUpUpdated(_investor, investors[_investor].lockUpEndTime);
    }

    function transfer(address _to, uint256 _value) external nonReentrant onlyAccreditedInvestor lockUpNotActive {
        require(investors[msg.sender].shares >= _value, "Insufficient shares");
        require(investors[_to].accredited, "Recipient not accredited");

        investors[msg.sender].shares -= _value;
        investors[_to].shares += _value;

        // Emit an event or call the actual token transfer function here if integrated with a token contract
    }

    function getInvestorLockUpEndTime(address _investor) external view returns (uint256) {
        return investors[_investor].lockUpEndTime;
    }

    function isAccredited(address _investor) external view returns (bool) {
        return investors[_investor].accredited;
    }

    function getInvestorShares(address _investor) external view returns (uint256) {
        return investors[_investor].shares;
    }
}
