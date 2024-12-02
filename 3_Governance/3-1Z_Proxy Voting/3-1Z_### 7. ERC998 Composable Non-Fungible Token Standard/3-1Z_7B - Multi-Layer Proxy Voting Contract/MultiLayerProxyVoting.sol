// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC998/ERC998.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MultiLayerProxyVoting is ERC998, Ownable {
    using SafeMath for uint256;

    struct Delegation {
        address proxy;
        bool isActive;
        uint256 delegatedVotes;
    }

    mapping(address => Delegation) public delegations;
    mapping(address => mapping(address => uint256)) public tokenDelegations; // proxy => (token holder => amount)

    event VotesDelegated(address indexed delegator, address indexed proxy, uint256 votes);
    event VotesRevoked(address indexed delegator);
    event ProxyUpdated(address indexed proxy, uint256 votes);

    constructor(string memory name, string memory symbol) ERC998(name, symbol) {}

    /**
     * @dev Delegate voting rights to a proxy.
     * @param _proxy Address of the proxy to delegate votes to.
     */
    function delegateVotes(address _proxy) external {
        require(_proxy != address(0), "Proxy address cannot be zero");
        require(_proxy != msg.sender, "Cannot delegate to yourself");

        // Calculate votes to delegate
        uint256 votesToDelegate = balanceOf(msg.sender);
        require(votesToDelegate > 0, "No votes to delegate");

        // Revoke previous delegation if active
        _revokeDelegation(msg.sender);

        // Update delegation
        delegations[msg.sender] = Delegation(_proxy, true, votesToDelegate);
        tokenDelegations[_proxy][msg.sender] = votesToDelegate;

        emit VotesDelegated(msg.sender, _proxy, votesToDelegate);
    }

    /**
     * @dev Revoke delegation and return voting rights.
     */
    function revokeDelegation() external {
        Delegation storage delegation = delegations[msg.sender];
        require(delegation.isActive, "No active delegation to revoke");

        // Reset delegation
        delete tokenDelegations[delegation.proxy][msg.sender];
        delete delegations[msg.sender];

        emit VotesRevoked(msg.sender);
    }

    /**
     * @dev Update the proxy's delegated votes.
     * @param _proxy Address of the proxy.
     */
    function updateProxyVotes(address _proxy) external {
        require(delegations[msg.sender].isActive, "No active delegation");
        require(delegations[msg.sender].proxy == _proxy, "Not your proxy");

        // Update proxy with new votes
        uint256 votes = tokenDelegations[_proxy][msg.sender];
        emit ProxyUpdated(_proxy, votes);
    }

    /**
     * @dev View the delegation details for a specific delegator.
     * @param _delegator Address to view delegation details for.
     * @return proxy Address of the proxy and active status.
     */
    function viewDelegation(address _delegator) external view returns (address, bool, uint256) {
        Delegation storage delegation = delegations[_delegator];
        return (delegation.proxy, delegation.isActive, delegation.delegatedVotes);
    }
}
