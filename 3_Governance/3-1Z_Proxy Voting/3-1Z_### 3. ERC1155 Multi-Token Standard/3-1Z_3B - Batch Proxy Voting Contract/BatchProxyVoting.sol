// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BatchProxyVoting is ERC1155, Ownable {
    using SafeMath for uint256;

    struct Delegation {
        address proxy;
        mapping(uint256 => uint256) amounts; // Token ID to delegated amount
        bool isActive;
    }

    mapping(address => Delegation) public delegations;
    mapping(address => uint256) public totalDelegatedVotes; // Total votes for each proxy

    event VotesDelegated(address indexed delegator, address indexed proxy, uint256[] tokenIds, uint256[] amounts);
    event VotesRevoked(address indexed delegator, address indexed proxy, uint256[] tokenIds, uint256[] amounts);

    constructor() ERC1155("https://api.example.com/tokens/{id}.json") {}

    /**
     * @dev Delegate voting rights to a proxy for multiple token IDs.
     * @param _proxy Address of the proxy to delegate votes to.
     * @param _tokenIds Array of token IDs to delegate votes for.
     * @param _amounts Array of amounts corresponding to each token ID.
     */
    function delegateVotes(address _proxy, uint256[] calldata _tokenIds, uint256[] calldata _amounts) external {
        require(_tokenIds.length == _amounts.length, "Token IDs and amounts length mismatch");
        require(_proxy != address(0), "Proxy address cannot be zero");
        require(_proxy != msg.sender, "Cannot delegate to yourself");

        // Revoke previous delegation if active
        _revokeDelegation(msg.sender);

        // Transfer tokens to this contract for delegation
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(balanceOf(msg.sender, _tokenIds[i]) >= _amounts[i], "Insufficient token balance to delegate");
            safeTransferFrom(msg.sender, address(this), _tokenIds[i], _amounts[i], "");
            delegations[msg.sender].amounts[_tokenIds[i]] = _amounts[i];
            totalDelegatedVotes[_proxy] = totalDelegatedVotes[_proxy].add(_amounts[i]);
        }

        delegations[msg.sender].proxy = _proxy;
        delegations[msg.sender].isActive = true;

        emit VotesDelegated(msg.sender, _proxy, _tokenIds, _amounts);
    }

    /**
     * @dev Revoke delegation for the sender and return the delegated tokens.
     */
    function revokeDelegation() external {
        Delegation storage delegation = delegations[msg.sender];
        require(delegation.isActive, "No active delegation to revoke");

        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        // Transfer tokens back to the delegator
        for (uint256 i = 0; i < tokenIds.length; i++) {
            amounts[i] = delegation.amounts[tokenIds[i]];
            safeTransferFrom(address(this), msg.sender, tokenIds[i], amounts[i], "");
            totalDelegatedVotes[delegation.proxy] = totalDelegatedVotes[delegation.proxy].sub(amounts[i]);
        }

        emit VotesRevoked(msg.sender, delegation.proxy, tokenIds, amounts);

        // Reset delegation
        delete delegations[msg.sender];
    }

    /**
     * @dev View the delegation details for a specific delegator.
     * @param _delegator Address to view delegation details for.
     * @return proxy Address of the proxy and amounts of delegated votes.
     */
    function viewDelegation(address _delegator) external view returns (address, uint256[] memory, bool) {
        Delegation storage delegation = delegations[_delegator];
        uint256[] memory amounts = new uint256[](1); // Modify as needed to return relevant token IDs
        return (delegation.proxy, amounts, delegation.isActive);
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
