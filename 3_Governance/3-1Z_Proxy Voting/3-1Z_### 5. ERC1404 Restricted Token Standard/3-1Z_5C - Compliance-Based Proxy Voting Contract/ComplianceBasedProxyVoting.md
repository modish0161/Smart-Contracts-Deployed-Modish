Here's the complete smart contract for the **Compliance-Based Proxy Voting Contract** based on the ERC1404 standard. This contract enables proxy voting while ensuring that only compliant stakeholders can delegate their voting rights or serve as proxies.

### Smart Contract Code: `ComplianceBasedProxyVoting.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1404/ERC1404.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ComplianceBasedProxyVoting is ERC1404, Ownable {
    using SafeMath for uint256;

    struct Delegation {
        address proxy;
        uint256 amount;
        bool isActive;
    }

    mapping(address => Delegation) public delegations;
    mapping(address => uint256) public totalDelegatedVotes;
    mapping(address => bool) public compliantProxies; // List of compliant proxies

    event VotesDelegated(address indexed delegator, address indexed proxy, uint256 amount);
    event VotesRevoked(address indexed delegator, address indexed proxy, uint256 amount);
    event ProxyComplianceUpdated(address indexed proxy, bool compliant);

    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        address[] memory controllers
    ) ERC1404(name, symbol, totalSupply, controllers) {}

    // Update proxy compliance status
    function updateProxyCompliance(address _proxy, bool _compliant) external onlyOwner {
        compliantProxies[_proxy] = _compliant;
        emit ProxyComplianceUpdated(_proxy, _compliant);
    }

    /**
     * @dev Delegate voting rights to a compliant proxy.
     * @param _proxy Address of the compliant proxy to delegate votes to.
     * @param _amount Amount of votes to delegate.
     */
    function delegateVotes(address _proxy, uint256 _amount) external {
        require(_proxy != address(0), "Proxy address cannot be zero");
        require(_proxy != msg.sender, "Cannot delegate to yourself");
        require(balanceOf(msg.sender) >= _amount, "Insufficient token balance to delegate");
        require(compliantProxies[_proxy], "Proxy is not compliant");

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

1. **Compliance Integration:**
   - Allows only compliant proxies to be authorized for voting on behalf of token holders.

2. **Dynamic Proxy Management:**
   - The owner can update the compliance status of proxies, ensuring adherence to regulations.

3. **Delegation Management:**
   - Facilitates the delegation and revocation of voting rights, including automatic token transfers.

### Deployment Script

Use the following script to deploy the `ComplianceBasedProxyVoting` contract:

#### Deployment Script (`deploy.js`)

```javascript
// scripts/deploy.js

async function main() {
  const ComplianceBasedProxyVoting = await ethers.getContractFactory("ComplianceBasedProxyVoting");

  const contract = await ComplianceBasedProxyVoting.deploy(
    "ComplianceToken",
    "CMT",
    1000000,
    []
  );

  await contract.deployed();

  console.log("ComplianceBasedProxyVoting deployed to:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### Test Suite

Here's a basic test suite to validate the functionality of the `ComplianceBasedProxyVoting` contract:

#### Test Script (`test/ComplianceBasedProxyVoting.test.js`)

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ComplianceBasedProxyVoting", function () {
  let ComplianceBasedProxyVoting;
  let contract;
  let owner;
  let proxy;
  let delegator;

  beforeEach(async function () {
    [owner, proxy, delegator] = await ethers.getSigners();

    ComplianceBasedProxyVoting = await ethers.getContractFactory("ComplianceBasedProxyVoting");
    contract = await ComplianceBasedProxyVoting.deploy("ComplianceToken", "CMT", 1000000, []);
    await contract.deployed();

    // Mint some tokens to delegator
    await contract.mint(delegator.address, 1000, "");
  });

  it("Should authorize and delegate votes to a compliant proxy", async function () {
    await contract.updateProxyCompliance(proxy.address, true);
    await contract.connect(delegator).delegateVotes(proxy.address, 500);

    const delegation = await contract.viewDelegation(delegator.address);
    expect(delegation[0]).to.equal(proxy.address);
    expect(delegation[1]).to.equal(500);
    expect(delegation[2]).to.be.true;

    const totalVotes = await contract.viewTotalDelegatedVotes(proxy.address);
    expect(totalVotes).to.equal(500);
  });

  it("Should revoke delegation and return tokens to delegator", async function () {
    await contract.updateProxyCompliance(proxy.address, true);
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
    ).to.be.revertedWith("Proxy is not compliant");
  });

  it("Should not allow self-delegation", async function () {
    await contract.updateProxyCompliance(proxy.address, true);
    await expect(
      contract.connect(delegator).delegateVotes(delegator.address, 500)
    ).to.be.revertedWith("Cannot delegate to yourself");
  });
});
```

### Additional Instructions

1. **Compliance Framework Integration:**
   - Ensure the contract integrates with any relevant legal compliance frameworks specific to your jurisdiction.

2. **Gas Optimization:**
   - Review the code to optimize for gas efficiency.

3. **Security Audits:**
   - Conduct thorough audits to identify potential vulnerabilities.

4. **Multi-Network Deployment:**
   - Prepare scripts for deployment across multiple blockchain networks.

5. **Enhanced Reporting:**
   - Consider adding features for detailed reporting of voting actions to regulatory bodies.

This **Compliance-Based Proxy Voting Contract** provides a robust solution for ensuring that proxy voting complies with regulatory standards, while also protecting the interests of token holders and maintaining integrity in governance processes.