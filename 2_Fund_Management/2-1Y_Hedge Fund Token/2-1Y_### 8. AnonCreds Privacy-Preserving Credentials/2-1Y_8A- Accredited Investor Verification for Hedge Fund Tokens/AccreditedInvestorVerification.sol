// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AccreditedInvestorVerification is Ownable {
    mapping(address => bool) private accreditedInvestors; // Stores accreditation status

    event InvestorAccredited(address indexed investor);
    event InvestorDeAccredited(address indexed investor);

    // Function to verify if an investor is accredited
    function verifyInvestor(address investor) external onlyOwner {
        accreditedInvestors[investor] = true;
        emit InvestorAccredited(investor);
    }

    // Function to de-accredit an investor
    function deAccreditInvestor(address investor) external onlyOwner {
        accreditedInvestors[investor] = false;
        emit InvestorDeAccredited(investor);
    }

    // Function to check if an investor is accredited
    function isAccredited(address investor) external view returns (bool) {
        return accreditedInvestors[investor];
    }

    // Function for bulk accreditation
    function verifyMultipleInvestors(address[] calldata investors) external onlyOwner {
        for (uint256 i = 0; i < investors.length; i++) {
            verifyInvestor(investors[i]);
        }
    }
}
