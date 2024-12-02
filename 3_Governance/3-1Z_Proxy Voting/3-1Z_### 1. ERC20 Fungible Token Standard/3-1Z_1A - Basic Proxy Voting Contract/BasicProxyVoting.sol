// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BasicProxyVoting is ERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct Delegation {
        address delegate;
        uint256 amount;
    }

    mapping(address => Delegation) public delegations;
    mapping(address => uint256) public delegatedVotes;

    event DelegationCreated(address indexed delegator, address indexed delegate, uint256 amount);
    event DelegationRevoked(address indexed delegator, address indexed delegate, uint256 amount);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /**
     * @dev Delegate voting rights to a specified address.
     * @param _delegate Address to delegate votes to.
     * @param _amount Number of tokens to delegate.
     */
    function delegateVotes(address _delegate, uint256 _amount) external nonReentrant {
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance to delegate");
        require(_delegate != address(0), "Delegate address cannot be zero address");
        require(_delegate != msg.sender, "Cannot delegate to yourself");

        // Revoke previous delegation
        _revokeDelegation(msg.sender);

        // Transfer tokens to the contract for delegation
        _transfer(msg.sender, address(this), _amount);

        // Update delegation and delegated votes
        delegations[msg.sender] = Delegation({delegate: _delegate, amount: _amount});
        delegatedVotes[_delegate] = delegatedVotes[_delegate].add(_amount);

        emit DelegationCreated(msg.sender, _delegate, _amount);
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
            delegatedVotes[delegation.delegate] = delegatedVotes[delegation.delegate].sub(delegation.amount);

            emit DelegationRevoked(_delegator, delegation.delegate, delegation.amount);

            // Reset delegation
            delete delegations[_delegator];
        }
    }

    /**
     * @dev View the number of delegated votes for a specific address.
     * @param _delegate Address to view delegated votes for.
     * @return Number of delegated votes.
     */
    function viewDelegatedVotes(address _delegate) external view returns (uint256) {
        return delegatedVotes[_delegate];
    }

    /**
     * @dev View the delegation details for a specific address.
     * @param _delegator Address to view delegation details for.
     * @return delegate Address of the delegate and amount of delegated votes.
     */
    function viewDelegation(address _delegator) external view returns (address, uint256) {
        Delegation memory delegation = delegations[_delegator];
        return (delegation.delegate, delegation.amount);
    }
}
