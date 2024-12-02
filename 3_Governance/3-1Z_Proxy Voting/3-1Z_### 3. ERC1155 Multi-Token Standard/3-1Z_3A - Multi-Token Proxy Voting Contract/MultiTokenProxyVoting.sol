// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MultiTokenProxyVoting is ERC1155, Ownable {
    using SafeMath for uint256;

    struct Delegation {
        address proxy;
        mapping(uint256 => uint256) amounts; // Token ID to delegated amount
        uint256 expiration;
        bool isActive;
    }

    mapping(address => Delegation) public delegations;
    mapping(address => uint256) public totalDelegatedVotes; // Total votes for each proxy

    event VotesDelegated(address indexed delegator, address indexed proxy, uint256 indexed tokenId, uint256 amount, uint256 expiration);
    event VotesRevoked(address indexed delegator, address indexed proxy, uint256 indexed tokenId, uint256 amount);

    constructor() ERC1155("https://api.example.com/tokens/{id}.json") {}

    /**
     * @dev Delegate voting rights to a proxy with an expiration time for a specific token ID.
     * @param _proxy Address of the proxy to delegate votes to.
     * @param _tokenId ID of the token to delegate votes for.
     * @param _amount Amount of tokens to delegate.
     * @param _expiration Duration for which the delegation is valid (in seconds).
     */
    function delegateVotes(address _proxy, uint256 _tokenId, uint256 _amount, uint256 _expiration) external {
        require(balanceOf(msg.sender, _tokenId) >= _amount, "Insufficient token balance to delegate");
        require(_proxy != address(0), "Proxy address cannot be zero");
        require(_proxy != msg.sender, "Cannot delegate to yourself");
        require(_expiration > block.timestamp, "Expiration must be in the future");

        // Revoke previous delegation if active
        _revokeDelegation(msg.sender);

        // Transfer tokens to this contract for delegation
        safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");

        // Update delegation
        delegations[msg.sender].proxy = _proxy;
        delegations[msg.sender].amounts[_tokenId] = _amount;
        delegations[msg.sender].expiration = _expiration;
        delegations[msg.sender].isActive = true;

        totalDelegatedVotes[_proxy] = totalDelegatedVotes[_proxy].add(_amount);

        emit VotesDelegated(msg.sender, _proxy, _tokenId, _amount, _expiration);
    }

    /**
     * @dev Revoke delegation for the sender and return the delegated tokens.
     */
    function revokeDelegation() external {
        Delegation storage delegation = delegations[msg.sender];
        require(delegation.isActive, "No active delegation to revoke");

        uint256 amount = delegation.amounts[delegation.proxy];

        // Transfer tokens back to the delegator
        safeTransferFrom(address(this), msg.sender, delegation.proxy, amount, "");
        totalDelegatedVotes[delegation.proxy] = totalDelegatedVotes[delegation.proxy].sub(amount);

        emit VotesRevoked(msg.sender, delegation.proxy, delegation.proxy, amount);

        // Reset delegation
        delete delegations[msg.sender];
    }

    /**
     * @dev Check if the delegation is still active.
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
     * @return proxy Address of the proxy and amounts of delegated votes.
     */
    function viewDelegation(address _delegator) external view returns (address, uint256, uint256, bool) {
        Delegation storage delegation = delegations[_delegator];
        return (delegation.proxy, delegation.amounts[delegation.proxy], delegation.expiration, delegation.isActive);
    }

    /**
     * @dev View the total number of delegated votes for a specific proxy.
     * @param _proxy Address to view total delegated votes for.
     * @return Total number of delegated votes.
     */
    function viewTotalDelegatedVotes(address _proxy) external view returns (uint256) {
        return totalDelegatedVotes[_proxy];
    }
}
