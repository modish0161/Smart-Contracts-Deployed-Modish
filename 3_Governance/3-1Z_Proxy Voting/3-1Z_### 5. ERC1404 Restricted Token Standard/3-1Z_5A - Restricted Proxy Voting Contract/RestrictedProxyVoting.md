Here's a complete smart contract for the **Restricted Proxy Voting Contract** based on the ERC1404 standard. This contract allows investors to delegate their voting rights to authorized proxies while ensuring compliance with regulatory requirements.

### Smart Contract Code: `RestrictedProxyVoting.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1404/ERC1404.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RestrictedProxyVoting is ERC1404, Ownable {
    using SafeMath for uint256;

    struct Delegation {
        address proxy;
        uint256 amount;
        bool isActive;
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
    ) ERC1404(name, symbol, totalSupply, controllers) {}

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
        delegations[msg.sender] = Delegation(_proxy, _amount, true);
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
    function viewDelegation(address _delegator) external view returns (address, uint256, bool) {
        Delegation storage delegation = delegations[_delegator];
        return (delegation.proxy, delegation.amount, delegation.isActive);
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

1. **Restricted Proxy Voting:**
   - Allows token holders to delegate their voting rights to authorized proxies, ensuring compliance with regulations.

2. **Authorization Management:**
   - The contract owner can authorize or revoke proxies' ability to vote on behalf of token holders, maintaining compliance.

3. **Token Transfers:**
   - Transfers tokens to the contract during delegation to manage voting power securely.

4. **Delegation Management:**
   - Tracks active delegations and allows easy revocation of voting rights and return of tokens.

### Deployment Script

Use the following script to deploy the `RestrictedProxyVoting` contract:

#### Deployment Script (`deploy.js`)

```javascript
// scripts/deploy.js

async function main() {
  const RestrictedProxyVoting = await ethers.getContractFactory("RestrictedProxyVoting");

  const restrictedProxyVotingContract = await RestrictedProxyVoting.deploy(
    "RestrictedToken",
    "RTK",
    1000000,
    []
  );

  await restrictedProxyVotingContract.deployed();

  console.log("RestrictedProxyVoting deployed to:", restrictedProxyVotingContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### Test Suite

Here's a basic test suite to validate the functionality of the `RestrictedProxyVoting` contract:

#### Test Script (`test/RestrictedProxyVoting.test.js`)

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RestrictedProxyVoting", function () {
  let RestrictedProxyVoting;
  let restrictedProxyVoting;
  let owner;
  let proxy;
  let delegator;

  beforeEach(async function () {
    [owner, proxy, delegator] = await ethers.getSigners();

    RestrictedProxyVoting = await ethers.getContractFactory("RestrictedProxyVoting");
    restrictedProxyVoting = await RestrictedProxyVoting.deploy("RestrictedToken", "RTK", 1000000, []);
    await restrictedProxyVoting.deployed();

    // Mint some tokens to delegator
    await restrictedProxyVoting.mint(delegator.address, 1000, "");
  });

  it("Should authorize and delegate votes to a proxy", async function () {
    await restrictedProxyVoting.updateProxyAuthorization(proxy.address, true);
    await restrictedProxyVoting.connect(delegator).delegateVotes(proxy.address, 500);

    const delegation = await restrictedProxyVoting.viewDelegation(delegator.address);
    expect(delegation[0]).to.equal(proxy.address);
    expect(delegation[1]).to.equal(500);
    expect(delegation[2]).to.be.true;

    const totalVotes = await restrictedProxyVoting.viewTotalDelegatedVotes(proxy.address);
    expect(totalVotes).to.equal(500);
  });

  it("Should revoke delegation and return tokens to delegator", async function () {
    await restrictedProxyVoting.updateProxyAuthorization(proxy.address, true);
    await restrictedProxyVoting.connect(delegator).delegateVotes(proxy.address, 500);
    await restrictedProxyVoting.connect(delegator).revokeDelegation();

    const delegation = await restrictedProxyVoting.viewDelegation(delegator.address);
    expect(delegation[0]).to.equal(ethers.constants.AddressZero);
    expect(delegation[1]).to.equal(0);
    expect(delegation[2]).to.be.false;

    const delegatorBalance = await restrictedProxyVoting.balanceOf(delegator.address);
    expect(delegatorBalance).to.equal(1000); // Tokens returned
  });

  it("Should not allow delegation if proxy is unauthorized", async function () {
    await expect(
      restrictedProxyVoting.connect(delegator).delegateVotes(proxy.address, 500)
    ).to.be.revertedWith("Proxy is not authorized");
  });

  it("Should not allow self-delegation", async function () {
    await restrictedProxyVoting.updateProxyAuthorization(proxy.address, true);
    await expect(
      restrictedProxyVoting.connect(delegator).delegateVotes(delegator.address, 500)
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

This **Restricted Proxy Voting Contract** provides a secure solution for proxy voting in regulated environments, ensuring compliance and protection for all participants involved.