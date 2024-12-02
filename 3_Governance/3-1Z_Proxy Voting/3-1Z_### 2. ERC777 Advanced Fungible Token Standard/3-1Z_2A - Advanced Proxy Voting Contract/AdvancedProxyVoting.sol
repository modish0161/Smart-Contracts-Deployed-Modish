// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract AdvancedProxyVoting is ERC777, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct Delegation {
        address proxy;
        uint256 amount;
    }

    mapping(address => Delegation) public delegations;
    mapping(address => uint256) public delegatedVotes;

    event VotesDelegated(address indexed delegator, address indexed proxy, uint256 amount);
    event VotesRevoked(address indexed delegator, address indexed proxy, uint256 amount);

    constructor(string memory name, string memory symbol, address[] memory defaultOperators)
        ERC777(name, symbol, defaultOperators) {}

    /**
     * @dev Delegate voting rights to a specified proxy.
     * @param _proxy Address of the proxy to delegate votes to.
     * @param _amount Amount of tokens to delegate.
     */
    function delegateVotes(address _proxy, uint256 _amount) external nonReentrant {
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance to delegate");
        require(_proxy != address(0), "Proxy address cannot be zero");
        require(_proxy != msg.sender, "Cannot delegate to yourself");

        // Revoke previous delegation
        _revokeDelegation(msg.sender);

        // Transfer tokens to the contract for delegation
        _transfer(msg.sender, address(this), _amount);

        // Update delegation and delegated votes
        delegations[msg.sender] = Delegation({proxy: _proxy, amount: _amount});
        delegatedVotes[_proxy] = delegatedVotes[_proxy].add(_amount);

        emit VotesDelegated(msg.sender, _proxy, _amount);
    }

    /**
     * @dev Revoke delegation and return the delegated tokens to the delegator.
     */
    function revokeDelegation() external nonReentrant {
        _revokeDelegation(msg.sender);
    }

    /**
     * @dev Internal function to handle delegation revocation.
     * @param _delegator Address of the delegator.
     */
    function _revokeDelegation(address _delegator) internal {
        Delegation memory delegation = delegations[_delegator];

        if (delegation.amount > 0) {
            _transfer(address(this), _delegator, delegation.amount);
            delegatedVotes[delegation.proxy] = delegatedVotes[delegation.proxy].sub(delegation.amount);

            emit VotesRevoked(_delegator, delegation.proxy, delegation.amount);

            // Reset delegation
            delete delegations[_delegator];
        }
    }

    /**
     * @dev View the number of delegated votes for a specific proxy.
     * @param _proxy Address to view delegated votes for.
     * @return Number of delegated votes.
     */
    function viewDelegatedVotes(address _proxy) external view returns (uint256) {
        return delegatedVotes[_proxy];
    }

    /**
     * @dev View the delegation details for a specific delegator.
     * @param _delegator Address to view delegation details for.
     * @return proxy Address of the proxy and amount of delegated votes.
     */
    function viewDelegation(address _delegator) external view returns (address, uint256) {
        Delegation memory delegation = delegations[_delegator];
        return (delegation.proxy, delegation.amount);
    }
}
