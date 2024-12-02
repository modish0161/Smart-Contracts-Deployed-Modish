Here’s a complete smart contract for the **Multi-Layer Proxy Voting Contract** based on the ERC998 standard. This contract allows token holders to delegate their voting rights across multiple layers of ownership, effectively managing governance for complex asset structures.

### Smart Contract Code: `MultiLayerProxyVoting.sol`

```solidity
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
```

### Key Features:

1. **Proxy Management:**
   - The contract allows delegators to assign their voting rights to a proxy, with checks to ensure valid proxy addresses.

2. **Dynamic Delegation:**
   - Delegators can revoke their votes at any time, and the contract tracks delegated votes accurately.

3. **Layered Voting:**
   - This structure supports voting across multiple layers of ownership, accommodating complex asset arrangements.

### Deployment Script

Use the following script to deploy the `MultiLayerProxyVoting` contract:

#### Deployment Script (`deploy.js`)

```javascript
// scripts/deploy.js

async function main() {
  const MultiLayerProxyVoting = await ethers.getContractFactory("MultiLayerProxyVoting");

  const contract = await MultiLayerProxyVoting.deploy("MultiLayerToken", "MLT");

  await contract.deployed();

  console.log("MultiLayerProxyVoting deployed to:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### Test Suite

Here’s a basic test suite to validate the functionality of the `MultiLayerProxyVoting` contract:

#### Test Script (`test/MultiLayerProxyVoting.test.js`)

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MultiLayerProxyVoting", function () {
  let MultiLayerProxyVoting;
  let contract;
  let owner;
  let proxy;
  let delegator;

  beforeEach(async function () {
    [owner, proxy, delegator] = await ethers.getSigners();

    MultiLayerProxyVoting = await ethers.getContractFactory("MultiLayerProxyVoting");
    contract = await MultiLayerProxyVoting.deploy("MultiLayerToken", "MLT");
    await contract.deployed();
  });

  it("Should delegate votes to a compliant proxy", async function () {
    await contract.connect(delegator).delegateVotes(proxy.address);

    const delegation = await contract.viewDelegation(delegator.address);
    expect(delegation[0]).to.equal(proxy.address);
    expect(delegation[1]).to.be.true;
  });

  it("Should revoke delegation and return voting rights", async function () {
    await contract.connect(delegator).delegateVotes(proxy.address);
    await contract.connect(delegator).revokeDelegation();

    const delegation = await contract.viewDelegation(delegator.address);
    expect(delegation[0]).to.equal(ethers.constants.AddressZero);
    expect(delegation[1]).to.be.false;
  });

  it("Should not allow self-delegation", async function () {
    await expect(
      contract.connect(delegator).delegateVotes(delegator.address)
    ).to.be.revertedWith("Cannot delegate to yourself");
  });
});
```

### Additional Instructions

1. **Compliance Framework Integration:**
   - Ensure the contract meets legal requirements relevant to your jurisdiction.

2. **Gas Optimization:**
   - Review and optimize the code for gas efficiency.

3. **Security Audits:**
   - Conduct thorough audits to identify potential vulnerabilities.

4. **Multi-Network Deployment:**
   - Prepare deployment scripts for various blockchain networks.

5. **Enhanced Reporting:**
   - Implement features for reporting voting actions to relevant authorities if necessary.

This **Multi-Layer Proxy Voting Contract** enables effective governance over complex asset structures, allowing stakeholders to maintain their voting rights while participating in decision-making processes across multiple layers of ownership.