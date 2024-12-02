Here's a complete smart contract for the **Regulated Proxy Voting with Compliance Contract** based on the ERC1400 standard. This contract facilitates proxy voting for security token holders while ensuring compliance with securities regulations.

### Smart Contract Code: `RegulatedProxyVotingWithCompliance.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1400/ERC1400.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RegulatedProxyVotingWithCompliance is ERC1400, Ownable {
    using SafeMath for uint256;

    struct Delegation {
        address proxy;
        uint256 amount;
        bool isActive;
        bool isAuthorized; // Indicates if the proxy is authorized to vote
    }

    mapping(address => Delegation) public delegations;
    mapping(address => uint256) public totalDelegatedVotes; // Total votes for each proxy
    mapping(address => bool) public authorizedProxies; // List of authorized proxies

    event VotesDelegated(address indexed delegator, address indexed proxy, uint256 amount);
    event VotesRevoked(address indexed delegator, address indexed proxy, uint256 amount);
    event ProxyAuthorizationUpdated(address indexed proxy, bool authorized);

    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        address[] memory controllers
    ) ERC1400(name, symbol, totalSupply, controllers) {}

    // Function to authorize or revoke a proxy's authorization
    function updateProxyAuthorization(address _proxy, bool _authorized) external onlyOwner {
        authorizedProxies[_proxy] = _authorized;
        emit ProxyAuthorizationUpdated(_proxy, _authorized);
    }

    /**
     * @dev Delegate voting rights to a proxy.
     * @param _proxy Address of the proxy to delegate votes to.
     * @param _amount Amount of votes to delegate.
     */
    function delegateVotes(address _proxy, uint256 _amount) external {
        require(_proxy != address(0), "Proxy address cannot be zero");
        require(_proxy != msg.sender, "Cannot delegate to yourself");
        require(balanceOf(msg.sender) >= _amount, "Insufficient token balance to delegate");
        require(authorizedProxies[_proxy], "Proxy is not authorized");

        // Revoke previous delegation if active
        _revokeDelegation(msg.sender);

        // Update delegation
        delegations[msg.sender] = Delegation(_proxy, _amount, true, true);
        totalDelegatedVotes[_proxy] = totalDelegatedVotes[_proxy].add(_amount);

        // Transfer tokens to this contract for delegation
        transferFrom(msg.sender, address(this), _amount);

        emit VotesDelegated(msg.sender, _proxy, _amount);
    }

    /**
     * @dev Revoke delegation and return the delegated tokens.
     */
    function revokeDelegation() external {
        Delegation storage delegation = delegations[msg.sender];
        require(delegation.isActive, "No active delegation to revoke");

        // Transfer tokens back to the delegator
        transfer(msg.sender, delegation.amount);
        totalDelegatedVotes[delegation.proxy] = totalDelegatedVotes[delegation.proxy].sub(delegation.amount);

        emit VotesRevoked(msg.sender, delegation.proxy, delegation.amount);

        // Reset delegation
        delete delegations[msg.sender];
    }

    /**
     * @dev View the delegation details for a specific delegator.
     * @param _delegator Address to view delegation details for.
     * @return proxy Address of the proxy and amount of delegated votes.
     */
    function viewDelegation(address _delegator) external view returns (address, uint256, bool, bool) {
        Delegation storage delegation = delegations[_delegator];
        return (delegation.proxy, delegation.amount, delegation.isActive, delegation.isAuthorized);
    }

    /**
     * @dev View the total number of delegated votes for a specific proxy.
     * @param _proxy Address to view total delegated votes for.
     * @return Total number of delegated votes.
     */
    function viewTotalDelegatedVotes(address _proxy) external view returns (uint256) {
        return totalDelegatedVotes[_proxy];
    }

    /**
     * @dev Internal function to revoke previous delegation.
     * @param _delegator Address of the delegator to revoke.
     */
    function _revokeDelegation(address _delegator) internal {
        Delegation storage delegation = delegations[_delegator];
        if (delegation.isActive) {
            totalDelegatedVotes[delegation.proxy] = totalDelegatedVotes[delegation.proxy].sub(delegation.amount);
            delegation.isActive = false;
        }
    }
}
```

### Key Features:

1. **Proxy Voting with Compliance:**
   - Allows security token holders to delegate their voting rights to authorized proxies, ensuring compliance with regulatory requirements.

2. **Authorization Management:**
   - The owner can authorize or revoke proxies' ability to vote on behalf of token holders, ensuring that only eligible proxies can participate.

3. **Token Transfers:**
   - Transfers tokens to the contract during delegation, managing voting power securely.

4. **Delegation Management:**
   - Tracks active delegations, allowing easy revocation of voting rights and returning of tokens.

### Deployment Script

Use the following script to deploy the `RegulatedProxyVotingWithCompliance` contract:

#### Deployment Script (`deploy.js`)

```javascript
// scripts/deploy.js

async function main() {
  const RegulatedProxyVotingWithCompliance = await ethers.getContractFactory("RegulatedProxyVotingWithCompliance");

  const regulatedProxyVotingContract = await RegulatedProxyVotingWithCompliance.deploy(
    "RegulatedToken",
    "RTK",
    1000000,
    []
  );

  await regulatedProxyVotingContract.deployed();

  console.log("RegulatedProxyVotingWithCompliance deployed to:", regulatedProxyVotingContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### Test Suite

Here's a basic test suite to validate the functionality of the `RegulatedProxyVotingWithCompliance` contract:

#### Test Script (`test/RegulatedProxyVotingWithCompliance.test.js`)

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RegulatedProxyVotingWithCompliance", function () {
  let RegulatedProxyVotingWithCompliance;
  let regulatedProxyVoting;
  let owner;
  let proxy;
  let delegator;

  beforeEach(async function () {
    [owner, proxy, delegator] = await ethers.getSigners();

    RegulatedProxyVotingWithCompliance = await ethers.getContractFactory("RegulatedProxyVotingWithCompliance");
    regulatedProxyVoting = await RegulatedProxyVotingWithCompliance.deploy("RegulatedToken", "RTK", 1000000, []);
    await regulatedProxyVoting.deployed();

    // Mint some tokens to delegator
    await regulatedProxyVoting.mint(delegator.address, 1000, "");
  });

  it("Should authorize and delegate votes to a proxy", async function () {
    await regulatedProxyVoting.updateProxyAuthorization(proxy.address, true);
    await regulatedProxyVoting.connect(delegator).delegateVotes(proxy.address, 500);

    const delegation = await regulatedProxyVoting.viewDelegation(delegator.address);
    expect(delegation[0]).to.equal(proxy.address);
    expect(delegation[1]).to.equal(500);
    expect(delegation[2]).to.be.true;

    const totalVotes = await regulatedProxyVoting.viewTotalDelegatedVotes(proxy.address);
    expect(totalVotes).to.equal(500);
  });

  it("Should revoke delegation and return tokens to delegator", async function () {
    await regulatedProxyVoting.updateProxyAuthorization(proxy.address, true);
    await regulatedProxyVoting.connect(delegator).delegateVotes(proxy.address, 500);
    await regulatedProxyVoting.connect(delegator).revokeDelegation();

    const delegation = await regulatedProxyVoting.viewDelegation(delegator.address);
    expect(delegation[0]).to.equal(ethers.constants.AddressZero);
    expect(delegation[1]).to.equal(0);
    expect(delegation[2]).to.be.false;

    const delegatorBalance = await regulatedProxyVoting.balanceOf(delegator.address);
    expect(delegatorBalance).to.equal(1000); // Tokens returned
  });

  it("Should not allow delegation if proxy is unauthorized", async function () {
    await expect(
      regulatedProxyVoting.connect(delegator).delegateVotes(proxy.address, 500)
    ).to.be.revertedWith("Proxy is not authorized");
  });

  it("Should not allow self-delegation", async function () {
    await regulatedProxyVoting.updateProxyAuthorization(proxy.address, true);
    await expect(
      regulatedProxyVoting.connect(delegator).delegateVotes(delegator.address, 500)
    ).to.be.revertedWith("Cannot delegate to yourself");
  });
});
```

### Additional Instructions

1. **Compliance Integration:**
   - Ensure integration with legal compliance frameworks relevant to your jurisdiction.

2. **Gas Optimization:**
   - Review and optimize the contract for gas efficiency.

3. **Security Audits:**
   - Conduct thorough audits to identify and mitigate potential vulnerabilities.

4. **Multi-Network Deployment:**
   - Prepare the deployment scripts for various blockchain networks.

5. **Enhanced Governance Features:**
   - Consider adding features for notifications on delegation changes or upcoming votes.

This **Regulated Proxy Voting with Compliance Contract** provides a secure and compliant solution for proxy voting in corporate governance, ensuring that shareholders' interests are adequately represented while adhering to regulatory requirements.