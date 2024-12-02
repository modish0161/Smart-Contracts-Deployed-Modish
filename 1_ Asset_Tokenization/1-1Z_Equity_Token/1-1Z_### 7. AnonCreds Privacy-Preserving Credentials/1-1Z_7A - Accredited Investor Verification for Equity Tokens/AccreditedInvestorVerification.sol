// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract AccreditedInvestorVerification is Ownable, ReentrancyGuard, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private accreditedInvestors;

    event InvestorVerified(address indexed investor);
    event InvestorRevoked(address indexed investor);
    event VerificationRequested(address indexed investor);

    // Placeholder for AnonCreds integration point for credential verification
    struct AnonCred {
        bytes32 proof;
        bytes32 publicKey;
    }

    mapping(address => AnonCred) private investorCredentials;

    // Modifier to check if the caller is an accredited investor
    modifier onlyAccredited() {
        require(isAccredited(msg.sender), "Not an accredited investor");
        _;
    }

    constructor() {}

    /**
     * @dev Request verification as an accredited investor.
     * This is a placeholder function to integrate AnonCreds in a real-world scenario.
     * @param proof The proof of accreditation.
     * @param publicKey The public key linked to the proof.
     */
    function requestVerification(bytes32 proof, bytes32 publicKey) external whenNotPaused {
        investorCredentials[msg.sender] = AnonCred(proof, publicKey);
        emit VerificationRequested(msg.sender);
    }

    /**
     * @dev Verify an investor manually. Only owner can call this.
     * This is a simplified manual verification function.
     * @param investor The address of the investor to be verified.
     */
    function verifyInvestor(address investor) external onlyOwner whenNotPaused {
        accreditedInvestors.add(investor);
        emit InvestorVerified(investor);
    }

    /**
     * @dev Revoke an investor's accredited status. Only owner can call this.
     * @param investor The address of the investor to be revoked.
     */
    function revokeInvestor(address investor) external onlyOwner whenNotPaused {
        accreditedInvestors.remove(investor);
        emit InvestorRevoked(investor);
    }

    /**
     * @dev Check if an address is an accredited investor.
     * @param investor The address to check.
     * @return True if the address is accredited, false otherwise.
     */
    function isAccredited(address investor) public view returns (bool) {
        return accreditedInvestors.contains(investor);
    }

    /**
     * @dev Pause the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
