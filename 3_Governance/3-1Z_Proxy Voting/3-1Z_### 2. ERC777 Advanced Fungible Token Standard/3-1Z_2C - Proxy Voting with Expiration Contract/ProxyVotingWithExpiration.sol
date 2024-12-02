// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ProxyVotingWithExpiration is ERC777, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct Delegation {
        address operator;
        uint256 amount;
        uint256 expiration;
        bool isActive;
    }

    mapping(address => Delegation) public delegations;
    mapping(address => uint256) public totalDelegatedVotes;

    event VotesDelegated(address indexed delegator, address indexed operator, uint256 amount, uint256 expiration);
    event VotesRevoked(address indexed delegator, address indexed operator, uint256 amount);

    constructor(string memory name, string memory symbol, address[] memory defaultOperators)
        ERC777(name, symbol, defaultOperators) {}

    /**
     * @dev Delegate voting rights to a specified operator with an expiration time.
     * @param _operator Address of the operator to delegate votes to.
     * @param _amount Amount of tokens to delegate.
     * @param _expiration Duration for which the delegation is valid (in seconds).
     */
    function delegateVotes(address _operator, uint256 _amount, uint256 _expiration) external nonReentrant {
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance to delegate");
        require(_operator != address(0), "Operator address cannot be zero");
        require(_operator != msg.sender, "Cannot delegate to yourself");
        require(_expiration > block.timestamp, "Expiration must be in the future");

        // Revoke previous delegation if active
        _revokeDelegation(msg.sender);

        // Transfer tokens to the contract for delegation
        _transfer(msg.sender, address(this), _amount);

        // Update delegation
        delegations[msg.sender] = Delegation({operator: _operator, amount: _amount, expiration: _expiration, isActive: true});
        totalDelegatedVotes[_operator] = totalDelegatedVotes[_operator].add(_amount);

        emit VotesDelegated(msg.sender, _operator, _amount, _expiration);
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

        if (delegation.isActive) {
            _transfer(address(this), _delegator, delegation.amount);
            totalDelegatedVotes[delegation.operator] = totalDelegatedVotes[delegation.operator].sub(delegation.amount);

            emit VotesRevoked(_delegator, delegation.operator, delegation.amount);

            // Reset delegation
            delete delegations[_delegator];
        }
    }

    /**
     * @dev Function to check if the delegation is still active.
     * @param _delegator Address to check delegation for.
     * @return isActive True if delegation is active, false otherwise.
     */
    function isDelegationActive(address _delegator) external view returns (bool) {
        Delegation memory delegation = delegations[_delegator];
        return delegation.isActive && (delegation.expiration > block.timestamp);
    }

    /**
     * @dev View the delegation details for a specific delegator.
     * @param _delegator Address to view delegation details for.
     * @return operator Address of the operator and amount of delegated votes.
     */
    function viewDelegation(address _delegator) external view returns (address, uint256, uint256, bool) {
        Delegation memory delegation = delegations[_delegator];
        return (delegation.operator, delegation.amount, delegation.expiration, delegation.isActive);
    }

    /**
     * @dev View the total number of delegated votes for a specific operator.
     * @param _operator Address to view total delegated votes for.
     * @return Total number of delegated votes.
     */
    function viewTotalDelegatedVotes(address _operator) external view returns (uint256) {
        return totalDelegatedVotes[_operator];
    }
}
