Here's the complete smart contract for the **Accredited Investor Proxy Voting Contract** based on the ERC1404 standard. This contract allows accredited investors to delegate their voting rights to authorized proxies while ensuring compliance with regulatory requirements.

### Smart Contract Code: `AccreditedInvestorProxyVoting.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1404/ERC1404.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract AccreditedInvestorProxyVoting is ERC1404, Ownable {
    using SafeMath for uint256;

    struct Delegation {
        address proxy;
        uint256 amount;
        bool isActive;
    }

    mapping(address => Delegation) public delegations;
    mapping(address => uint256) public totalDelegatedVotes; // Total votes for each proxy
    mapping(address => bool) public accreditedProxies; // List of accredited proxies

    event VotesDelegated(address indexed delegator, address indexed proxy, uint256 amount);
    event VotesRevoked(address indexed delegator, address indexed proxy, uint256 amount);
    event ProxyAuthorizationUpdated(address indexed proxy, bool accredited);

    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        address[] memory controllers
    ) ERC1404(name, symbol, totalSupply, controllers) {}

    // Function to authorize or revoke a proxy's accreditation
    function updateProxyAuthorization(address _proxy, bool _accredited) external onlyOwner {
        accreditedProxies[_proxy] = _accredited;
        emit ProxyAuthorizationUpdated(_proxy, _accredited);
    }

    /**
     * @dev Delegate voting rights to an accredited proxy.
     * @param _proxy Address of the accredited proxy to delegate votes to.
     * @param _amount Amount of votes to delegate.
     */
    function delegateVotes(address _proxy, uint256 _amount) external {
        require(_proxy != address(0), "Proxy address cannot be zero");
        require(_proxy != msg.sender, "Cannot delegate to yourself");
        require(balanceOf(msg.sender) >= _amount, "Insufficient token balance to delegate");
        require(accreditedProxies[_proxy], "Proxy is not accredited");

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

1. **Accredited Proxy Voting:**
   - Allows accredited investors to delegate their voting rights to authorized proxies, ensuring compliance with regulations.

2. **Authorization Management:**
   - The contract owner can authorize or revoke proxies' ability to vote on behalf of token holders.

3. **Delegation Management:**
   - Tracks active delegations and allows easy revocation of voting rights and return of tokens.

### Deployment Script

Use the following script to deploy the `AccreditedInvestorProxyVoting` contract:

#### Deployment Script (`deploy.js`)

```javascript
// scripts/deploy.js

async function main() {
  const AccreditedInvestorProxyVoting = await ethers.getContractFactory("AccreditedInvestorProxyVoting");

  const contract = await AccreditedInvestorProxyVoting.deploy(
    "AccreditedToken",
    "AKT",
    1000000,
    []
  );

  await contract.deployed();

  console.log("AccreditedInvestorProxyVoting deployed to:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### Test Suite

Here's a basic test suite to validate the functionality of the `AccreditedInvestorProxyVoting` contract:

#### Test Script (`test/AccreditedInvestorProxyVoting.test.js`)

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AccreditedInvestorProxyVoting", function () {
  let AccreditedInvestorProxyVoting;
  let contract;
  let owner;
  let proxy;
  let delegator;

  beforeEach(async function () {
    [owner, proxy, delegator] = await ethers.getSigners();

    AccreditedInvestorProxyVoting = await ethers.getContractFactory("AccreditedInvestorProxyVoting");
    contract = await AccreditedInvestorProxyVoting.deploy("AccreditedToken", "AKT", 1000000, []);
    await contract.deployed();

    // Mint some tokens to delegator
    await contract.mint(delegator.address, 1000, "");
  });

  it("Should authorize and delegate votes to an accredited proxy", async function () {
    await contract.updateProxyAuthorization(proxy.address, true);
    await contract.connect(delegator).delegateVotes(proxy.address, 500);

    const delegation = await contract.viewDelegation(delegator.address);
    expect(delegation[0]).to.equal(proxy.address);
    expect(delegation[1]).to.equal(500);
    expect(delegation[2]).to.be.true;

    const totalVotes = await contract.viewTotalDelegatedVotes(proxy.address);
    expect(totalVotes).to.equal(500);
  });

  it("Should revoke delegation and return tokens to delegator", async function () {
    await contract.updateProxyAuthorization(proxy.address, true);
    await contract.connect(delegator).delegateVotes(proxy.address, 500);
    await contract.connect(delegator).revokeDelegation();

    const delegation = await contract.viewDelegation(delegator.address);
    expect(delegation[0]).to.equal(ethers.constants.AddressZero);
    expect(delegation[1]).to.equal(0);
    expect(delegation[2]).to.be.false;

    const delegatorBalance = await contract.balanceOf(delegator.address);
    expect(delegatorBalance).to.equal(1000); // Tokens returned
  });

  it("Should not allow delegation if proxy is unauthorized", async function () {
    await expect(
      contract.connect(delegator).delegateVotes(proxy.address, 500)
    ).to.be.revertedWith("Proxy is not accredited");
  });

  it("Should not allow self-delegation", async function () {
    await contract.updateProxyAuthorization(proxy.address, true);
    await expect(
      contract.connect(delegator).delegateVotes(delegator.address, 500)
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

This **Accredited Investor Proxy Voting Contract** provides a secure solution for proxy voting while ensuring compliance with regulatory requirements, protecting the interests of accredited investors and maintaining the integrity of governance processes.