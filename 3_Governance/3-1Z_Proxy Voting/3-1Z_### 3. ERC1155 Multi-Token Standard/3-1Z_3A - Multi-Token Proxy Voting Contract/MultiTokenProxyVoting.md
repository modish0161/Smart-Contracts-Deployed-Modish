Here's the complete smart contract for the **Multi-Token Proxy Voting Contract** based on the ERC1155 standard. This contract allows token holders of various asset types to delegate their voting rights to a proxy, accommodating different voting powers across multiple tokens.

### Smart Contract Code: `MultiTokenProxyVoting.sol`

```solidity
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
```

### Key Features:

1. **Multi-Token Support:**
   - The contract allows delegation of voting rights across various token types, making it suitable for DAOs with diverse assets.

2. **Temporary Delegation:**
   - Delegations can be set to expire after a specified time, ensuring that governance participation remains flexible.

3. **Automatic Token Transfers:**
   - Tokens are transferred to the contract for delegation, and returned upon revocation, maintaining a clear audit trail.

4. **Tracking of Delegated Votes:**
   - The contract tracks how many votes are delegated to each proxy for efficient governance.

### Deployment Script

This deployment script helps deploy the `MultiTokenProxyVoting` contract to the desired blockchain network.

#### Deployment Script (`deploy.js`)

```javascript
// scripts/deploy.js

async function main() {
  // Get the contract factory
  const MultiTokenProxyVoting = await ethers.getContractFactory("MultiTokenProxyVoting");

  // Deploy the contract
  const multiTokenProxyVoting = await MultiTokenProxyVoting.deploy();

  await multiTokenProxyVoting.deployed();

  console.log("MultiTokenProxyVoting deployed to:", multiTokenProxyVoting.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### Test Suite

This test suite validates the core functionalities of the `MultiTokenProxyVoting` contract.

#### Test Script (`test/MultiTokenProxyVoting.test.js`)

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MultiTokenProxyVoting", function () {
  let MultiTokenProxyVoting;
  let multiTokenProxyVoting;
  let owner;
  let proxy;
  let delegator;

  beforeEach(async function () {
    [owner, proxy, delegator] = await ethers.getSigners();

    MultiTokenProxyVoting = await ethers.getContractFactory("MultiTokenProxyVoting");
    multiTokenProxyVoting = await MultiTokenProxyVoting.deploy();
    await multiTokenProxyVoting.deployed();

    // Mint some tokens to delegator
    await multiTokenProxyVoting.mint(delegator.address, 1, 2000, "");
  });

  it("Should delegate votes to a proxy with expiration", async function () {
    const expiration = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
    await multiTokenProxyVoting.connect(delegator).delegateVotes(proxy.address, 1, 1000, expiration);
    const delegation = await multiTokenProxyVoting.viewDelegation(delegator.address);
    expect(delegation[0]).to.equal(proxy.address);
    expect(delegation[1]).to.equal(1000);
    expect(delegation[2]).to.equal(expiration);
    expect(delegation[3]).to.be.true;

    const totalVotes = await multiTokenProxyVoting.viewTotalDelegatedVotes(proxy.address);
    expect(totalVotes).to.equal(1000);
  });

  it("Should revoke delegation and return tokens to delegator", async function () {
    const expiration = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
    await multiTokenProxyVoting.connect(delegator).delegateVotes(proxy.address, 1, 1000, expiration);
    await multiTokenProxyVoting.connect(delegator).revokeDelegation();

    const delegation = await multiTokenProxyVoting.viewDelegation(delegator.address);
    expect(delegation[0]).to.equal(ethers.constants.AddressZero);
    expect(delegation[1]).to.equal(0);
    expect(delegation[2]).to.equal(0);
    expect(delegation[3]).to.be.false;

    const delegatorBalance = await multiTokenProxyVoting.balanceOf(delegator.address, 1);
    expect(delegatorBalance).to.equal(2000);
  });

  it("Should not allow delegation if insufficient balance", async function () {
    await expect(
      multiTokenProxyVoting.connect(delegator).delegateVotes(proxy.address, 1, 3000, Math.floor(Date.now() / 1000) + 3600)
    ).to.be.revertedWith("Insufficient token balance to delegate");
  });

  it("Should not allow self-delegation", async function () {
    await expect(
      multiTokenProxyVoting.connect(delegator).delegateVotes(delegator.address, 1, 500, Math.floor(Date.now() / 1000) + 3600)
    ).to.be.revertedWith("Cannot delegate to yourself");
  });

  it("Should indicate if the delegation is still active", async function () {
    const expiration = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
    await multiTokenProxyVoting.connect(delegator).delegateVotes(proxy.address,

 1, 1000, expiration);
    expect(await multiTokenProxyVoting.isDelegationActive(delegator.address)).to.be.true;

    // Wait for expiration
    await ethers.provider.send("evm_increaseTime", [3601]); // Increase time by 3601 seconds
    await ethers.provider.send("evm_mine"); // Mine a block
    expect(await multiTokenProxyVoting.isDelegationActive(delegator.address)).to.be.false;
  });
});
```

### Additional Instructions

1. **Integration with Governance Protocols:**
   - Consider integrating the contract with existing on-chain governance frameworks for enhanced functionality.

2. **Gas Optimization:**
   - Review the contract for potential optimizations to reduce gas costs during execution.

3. **Security Audits:**
   - Conduct thorough security audits to ensure robustness against common vulnerabilities.

4. **Multi-Network Deployment:**
   - Prepare deployment configurations for various blockchain networks, including Ethereum and Layer-2 solutions.

5. **Advanced Governance Features:**
   - Explore implementing additional features like notification mechanisms for expiring delegations.

This `MultiTokenProxyVoting` contract provides a secure and flexible mechanism for governance through multi-token delegation, enabling efficient participation in governance processes.