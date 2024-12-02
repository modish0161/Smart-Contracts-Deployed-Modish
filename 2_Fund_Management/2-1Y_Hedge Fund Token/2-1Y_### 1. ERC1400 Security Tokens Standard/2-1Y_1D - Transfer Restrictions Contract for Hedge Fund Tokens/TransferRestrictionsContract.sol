// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";

contract TransferRestrictionsContract is Ownable, ReentrancyGuard {
    struct Investor {
        uint256 shares;
        bool accredited;
    }

    mapping(address => Investor) public investors;
    mapping(address => mapping(address => uint256)) private _allowed;

    event InvestorAdded(address indexed investor, uint256 shares, bool accredited);
    event InvestorRemoved(address indexed investor);
    event TransferRestrictionsUpdated(address indexed investor, bool accredited);

    modifier onlyAccreditedInvestor() {
        require(investors[msg.sender].accredited, "Not an accredited investor");
        _;
    }

    constructor() {}

    function addInvestor(address _investor, uint256 _shares, bool _accredited) external onlyOwner {
        require(_shares > 0, "Shares must be greater than zero");
        investors[_investor] = Investor(_shares, _accredited);
        emit InvestorAdded(_investor, _shares, _accredited);
    }

    function removeInvestor(address _investor) external onlyOwner {
        delete investors[_investor];
        emit InvestorRemoved(_investor);
    }

    function updateAccreditationStatus(address _investor, bool _accredited) external onlyOwner {
        investors[_investor].accredited = _accredited;
        emit TransferRestrictionsUpdated(_investor, _accredited);
    }

    function transfer(address _to, uint256 _value) external nonReentrant onlyAccreditedInvestor {
        require(investors[msg.sender].shares >= _value, "Insufficient shares");
        require(investors[_to].accredited, "Recipient not accredited");

        investors[msg.sender].shares -= _value;
        investors[_to].shares += _value;

        // Emit an event or call the actual token transfer function here if integrated with a token contract
    }

    function approve(address _spender, uint256 _value) external onlyAccreditedInvestor {
        _allowed[msg.sender][_spender] = _value;
    }

    function transferFrom(address _from, address _to, uint256 _value) external nonReentrant onlyAccreditedInvestor {
        require(investors[_from].shares >= _value, "Insufficient shares");
        require(investors[_to].accredited, "Recipient not accredited");
        require(_allowed[_from][msg.sender] >= _value, "Allowance exceeded");

        investors[_from].shares -= _value;
        investors[_to].shares += _value;
        _allowed[_from][msg.sender] -= _value;

        // Emit an event or call the actual token transfer function here if integrated with a token contract
    }

    function isAccredited(address _investor) external view returns (bool) {
        return investors[_investor].accredited;
    }

    function getInvestorShares(address _investor) external view returns (uint256) {
        return investors[_investor].shares;
    }
}
