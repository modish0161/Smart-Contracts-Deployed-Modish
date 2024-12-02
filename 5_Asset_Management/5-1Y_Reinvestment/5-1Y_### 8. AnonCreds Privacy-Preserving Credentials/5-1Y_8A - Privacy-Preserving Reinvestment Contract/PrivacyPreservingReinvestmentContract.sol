// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PrivacyPreservingReinvestmentContract is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct Investor {
        bytes32 zkProof; // Zero-Knowledge Proof for identity verification
        uint256 allocation; // Allocation of profits to reinvest
        bool isWhitelisted; // Whitelist status
    }

    mapping(address => Investor) public investors;
    IERC20 public profitToken; // Token in which profits are distributed
    uint256 public totalAllocation; // Total allocation for reinvestment

    event InvestorWhitelisted(address indexed investor);
    event ProfitReinvested(address indexed investor, uint256 amount);
    event ProfitsDeposited(uint256 amount);

    constructor(address _profitToken) {
        require(_profitToken != address(0), "Invalid profit token address");
        profitToken = IERC20(_profitToken);
    }

    // Function to whitelist an investor with a zero-knowledge proof (ZKP)
    function whitelistInvestor(address _investor, bytes32 _zkProof, uint256 _allocation) external onlyOwner {
        require(_investor != address(0), "Invalid investor address");
        require(_allocation > 0, "Allocation must be greater than zero");
        require(!investors[_investor].isWhitelisted, "Investor already whitelisted");

        investors[_investor] = Investor({
            zkProof: _zkProof,
            allocation: _allocation,
            isWhitelisted: true
        });
        
        totalAllocation = totalAllocation.add(_allocation);
        emit InvestorWhitelisted(_investor);
    }

    // Function to deposit profits into the contract
    function depositProfits(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(profitToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        emit ProfitsDeposited(_amount);
    }

    // Function to reinvest profits based on allocation percentages
    function reinvestProfits() external nonReentrant {
        uint256 profitAmount = profitToken.balanceOf(address(this));
        require(profitAmount > 0, "No profits to reinvest");

        for (address investorAddress : getWhitelistedInvestors()) {
            Investor storage investor = investors[investorAddress];
            uint256 reinvestAmount = profitAmount.mul(investor.allocation).div(totalAllocation);

            // Transfer reinvest amount to the investor
            profitToken.transfer(investorAddress, reinvestAmount);
            emit ProfitReinvested(investorAddress, reinvestAmount);
        }
    }

    // Internal function to get all whitelisted investors
    function getWhitelistedInvestors() internal view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < investors.length; i++) {
            if (investors[i].isWhitelisted) {
                count++;
            }
        }
        address[] memory whitelisted = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < investors.length; i++) {
            if (investors[i].isWhitelisted) {
                whitelisted[index] = investors[i];
                index++;
            }
        }
        return whitelisted;
    }

    // Function to verify zero-knowledge proof before reinvestment (stub for integration with AnonCreds)
    function verifyZKProof(bytes32 zkProof) internal pure returns (bool) {
        // In a real scenario, this function would interact with a ZKP verification library or protocol
        // Here we assume all proofs are valid for demonstration purposes
        return zkProof != bytes32(0);
    }

    // Function to withdraw profits from the contract
    function withdrawProfits(uint256 _amount) external onlyOwner nonReentrant {
        require(_amount <= profitToken.balanceOf(address(this)), "Insufficient balance");
        profitToken.transfer(owner(), _amount);
    }

    // Function to update the profit token
    function updateProfitToken(address _newProfitToken) external onlyOwner {
        require(_newProfitToken != address(0), "Invalid profit token address");
        profitToken = IERC20(_newProfitToken);
    }

    // Function to remove an investor from the whitelist
    function removeInvestor(address _investor) external onlyOwner {
        require(_investor != address(0), "Invalid investor address");
        require(investors[_investor].isWhitelisted, "Investor is not whitelisted");

        totalAllocation = totalAllocation.sub(investors[_investor].allocation);
        delete investors[_investor];
    }
}
