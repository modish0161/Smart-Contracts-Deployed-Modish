### Smart Contract: Basic Proxy Voting Contract

This smart contract, named `BasicProxyVoting.sol`, allows token holders to delegate their voting rights to another address (proxy) based on the ERC20 standard. This is useful for scenarios where token holders may not have the time or expertise to participate in governance decisions directly.

#### Smart Contract Code (`BasicProxyVoting.sol`)

```solidity
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
```

### Key Features:

1. **Delegation of Votes:**
   - Token holders can delegate their voting rights (votes) to another address (proxy) by transferring their tokens to the contract.
   - Delegated tokens remain in the contract and are still owned by the delegator, but the proxy has voting power equivalent to the number of tokens delegated.

2. **Revocation of Delegation:**
   - Delegators can revoke their delegation at any time, and the delegated tokens will be returned to them.

3. **View Functions:**
   - Users can view the number of votes delegated to a specific address and the details of any delegations they have made.

### Deployment Script

This deployment script will help deploy the `BasicProxyVoting` contract to the network of your choice.

#### Deployment Script (`deploy.js`)

```javascript
// scripts/deploy.js

async function main() {
  // Get the contract factory
  const BasicProxyVoting = await ethers.getContractFactory("BasicProxyVoting");

  // Deployment parameters
  const name = "Basic Proxy Voting Token";
  const symbol = "BPVT";

  // Deploy the contract with necessary parameters
  const basicProxyVoting = await BasicProxyVoting.deploy(name, symbol);

  await basicProxyVoting.deployed();

  console.log("BasicProxyVoting deployed to:", basicProxyVoting.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### Test Suite

This test suite validates the core functionalities of the `BasicProxyVoting` contract.

#### Test Script (`test/BasicProxyVoting.test.js`)

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BasicProxyVoting", function () {
  let BasicProxyVoting;
  let basicProxyVoting;
  let owner;
  let delegate;
  let delegator;

  beforeEach(async function () {
    [owner, delegate, delegator] = await ethers.getSigners();

    BasicProxyVoting = await ethers.getContractFactory("BasicProxyVoting");
    basicProxyVoting = await BasicProxyVoting.deploy("Basic Proxy Voting Token", "BPVT");
    await basicProxyVoting.deployed();

    // Mint some tokens to delegator
    await basicProxyVoting.transfer(delegator.address, 1000);
  });

  it("Should delegate votes to a delegate", async function () {
    await basicProxyVoting.connect(delegator).delegateVotes(delegate.address, 500);
    const delegation = await basicProxyVoting.viewDelegation(delegator.address);
    expect(delegation[0]).to.equal(delegate.address);
    expect(delegation[1]).to.equal(500);

    const delegatedVotes = await basicProxyVoting.viewDelegatedVotes(delegate.address);
    expect(delegatedVotes).to.equal(500);
  });

  it("Should revoke delegation and return tokens to delegator", async function () {
    await basicProxyVoting.connect(delegator).delegateVotes(delegate.address, 500);
    await basicProxyVoting.connect(delegator).revokeDelegation();

    const delegation = await basicProxyVoting.viewDelegation(delegator.address);
    expect(delegation[0]).to.equal(ethers.constants.AddressZero);
    expect(delegation[1]).to.equal(0);

    const delegatorBalance = await basicProxyVoting.balanceOf(delegator.address);
    expect(delegatorBalance).to.equal(1000);
  });

  it("Should not allow delegation if insufficient balance", async function () {
    await expect(
      basicProxyVoting.connect(delegator).delegateVotes(delegate.address, 2000)
    ).to.be.revertedWith("Insufficient balance to delegate");
  });

  it("Should not allow self-delegation", async function () {
    await expect(
      basicProxyVoting.connect(delegator).delegateVotes(delegator.address, 500)
    ).to.be.revertedWith("Cannot delegate to yourself");
  });
});
```

### Additional Instructions

1. **Token Supply and Distribution:**
   - Adjust the initial supply and distribution mechanism according to your requirements.

2. **Integration with Governance Contracts:**
   - Integrate the contract with other governance contracts that utilize the proxy voting mechanism.

3. **Gas Optimization:**
   - Optimize the contract further by reducing state variable reads and writes where possible.

4. **Multi-Network Deployment:**
   - Use the deployment script to deploy the contract on multiple networks like Ethereum, Binance Smart Chain, and Layer-2 networks.

5. **Security Audits:**
   - Conduct thorough security audits before deploying the contract in a production environment.

This smart contract enables a straightforward proxy voting system for ERC20 token holders, allowing them to delegate their voting power to trusted proxies without losing control over their tokens.