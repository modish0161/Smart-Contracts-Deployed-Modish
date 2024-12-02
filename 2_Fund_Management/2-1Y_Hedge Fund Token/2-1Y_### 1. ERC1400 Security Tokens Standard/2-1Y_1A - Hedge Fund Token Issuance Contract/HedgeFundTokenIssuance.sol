// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1400/IERC1400.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HedgeFundTokenIssuance is Ownable, ReentrancyGuard {
    // Struct to store investor information
    struct Investor {
        bool isAccredited;
        uint256 shares;
    }

    // Mapping from investor address to their information
    mapping(address => Investor) public investors;

    // Total shares issued
    uint256 public totalShares;
    
    // Event declarations
    event TokensIssued(address indexed investor, uint256 shares);
    event TokensWithdrawn(address indexed investor, uint256 shares);
    
    // Address of the underlying asset (e.g., hedge fund token)
    address public underlyingAsset;

    constructor(address _underlyingAsset) {
        require(_underlyingAsset != address(0), "Invalid underlying asset address");
        underlyingAsset = _underlyingAsset;
    }

    // Modifier to check if the caller is an accredited investor
    modifier onlyAccredited() {
        require(investors[msg.sender].isAccredited, "Not an accredited investor");
        _;
    }

    // Function to verify and register an accredited investor
    function registerAccreditedInvestor(address _investor) external onlyOwner {
        require(_investor != address(0), "Invalid investor address");
        investors[_investor].isAccredited = true;
    }

    // Function to issue tokens to accredited investors
    function issueTokens(uint256 _shares) external onlyAccredited nonReentrant {
        require(_shares > 0, "Shares must be greater than zero");

        // Update investor shares and total shares
        investors[msg.sender].shares += _shares;
        totalShares += _shares;

        emit TokensIssued(msg.sender, _shares);
    }

    // Function to withdraw shares (tokens) from the fund
    function withdrawTokens(uint256 _shares) external onlyAccredited nonReentrant {
        require(_shares > 0, "Shares must be greater than zero");
        require(investors[msg.sender].shares >= _shares, "Insufficient shares");

        // Update investor shares and total shares
        investors[msg.sender].shares -= _shares;
        totalShares -= _shares;

        // Transfer the underlying asset tokens to the investor
        IERC20(underlyingAsset).transfer(msg.sender, _shares);

        emit TokensWithdrawn(msg.sender, _shares);
    }

    // Function to check the investor's share balance
    function getInvestorShares(address _investor) external view returns (uint256) {
        return investors[_investor].shares;
    }

    // Function to get total shares issued
    function getTotalShares() external view returns (uint256) {
        return totalShares;
    }
}
