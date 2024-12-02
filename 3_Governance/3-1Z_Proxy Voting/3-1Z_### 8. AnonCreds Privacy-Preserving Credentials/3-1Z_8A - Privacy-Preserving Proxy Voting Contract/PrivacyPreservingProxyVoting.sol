// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract PrivacyPreservingProxyVoting is Ownable {
    using ECDSA for bytes32;

    struct Delegation {
        address proxy;
        bytes32 credentialHash;
        bool isActive;
    }

    mapping(address => Delegation) public delegations;

    event VotesDelegated(address indexed delegator, address indexed proxy, bytes32 credentialHash);
    event VotesRevoked(address indexed delegator);

    /**
     * @dev Delegate voting rights to a proxy while maintaining privacy.
     * @param _proxy Address of the proxy to delegate votes to.
     * @param _credentialHash Hash of the privacy-preserving credential.
     */
    function delegateVotes(address _proxy, bytes32 _credentialHash) external {
        require(_proxy != address(0), "Proxy address cannot be zero");
        require(_proxy != msg.sender, "Cannot delegate to yourself");

        // Revoke previous delegation if active
        _revokeDelegation(msg.sender);

        // Update delegation
        delegations[msg.sender] = Delegation(_proxy, _credentialHash, true);

        emit VotesDelegated(msg.sender, _proxy, _credentialHash);
    }

    /**
     * @dev Revoke delegation and return voting rights.
     */
    function revokeDelegation() external {
        Delegation storage delegation = delegations[msg.sender];
        require(delegation.isActive, "No active delegation to revoke");

        // Reset delegation
        delete delegations[msg.sender];

        emit VotesRevoked(msg.sender);
    }

    /**
     * @dev View delegation details for a specific delegator.
     * @param _delegator Address to view delegation details for.
     * @return proxy Address of the proxy and credential hash.
     */
    function viewDelegation(address _delegator) external view returns (address, bytes32, bool) {
        Delegation storage delegation = delegations[_delegator];
        return (delegation.proxy, delegation.credentialHash, delegation.isActive);
    }

    /**
     * @dev Verify credential hash (pseudo-function for credential validation).
     * @param _credentialHash Hash of the credential to verify.
     */
    function verifyCredential(bytes32 _credentialHash) internal view returns (bool) {
        // Placeholder for actual credential verification logic
        return true;
    }
}
