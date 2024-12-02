### Smart Contract: Proxy Voting with Revocation Contract

This smart contract, named `ProxyVotingWithRevocation.sol`, allows ERC20 token holders to delegate their voting rights to a proxy and provides the ability to revoke the delegation at any time. This ensures flexibility in governance participation.

#### Smart Contract Code (`ProxyVotingWithRevocation.sol`)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ProxyVotingWithRevocation is ERC20, Ownable, ReentrancyGuard {
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

1. **Vote Delegation and Revocation:**
   - The contract allows token holders to delegate their votes to another address and provides the ability to revoke the delegation at any time.
   - Delegation transfers the tokens to the contract to signify the commitment of voting power.

2. **Secure and Gas Efficient:**
   - The contract uses the ReentrancyGuard from OpenZeppelin to prevent reentrancy attacks.
   - Efficient gas management is achieved by leveraging SafeMath and struct mapping.

3. **Event Logging:**
   - Events are emitted for delegation creation and revocation for better traceability and transparency.

### Deployment Script

This deployment script helps deploy the `ProxyVotingWithRevocation` contract to the desired blockchain network.

#### Deployment Script (`deploy.js`)

```javascript
// scripts/deploy.js

async function main() {
  // Get the contract factory
  const ProxyVotingWithRevocation = await ethers.getContractFactory("ProxyVotingWithRevocation");

  // Deployment parameters
  const name = "Proxy Voting Token";
  const symbol = "PVT";

  // Deploy the contract with necessary parameters
  const proxyVotingWithRevocation = await ProxyVotingWithRevocation.deploy(name, symbol);

  await proxyVotingWithRevocation.deployed();

  console.log("ProxyVotingWithRevocation deployed to:", proxyVotingWithRevocation.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### Test Suite

This test suite validates the core functionalities of the `ProxyVotingWithRevocation` contract.

#### Test Script (`test/ProxyVotingWithRevocation.test.js`)

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ProxyVotingWithRevocation", function () {
  let ProxyVotingWithRevocation;
  let proxyVotingWithRevocation;
  let owner;
  let delegate;
  let delegator;

  beforeEach(async function () {
    [owner, delegate, delegator] = await ethers.getSigners();

    ProxyVotingWithRevocation = await ethers.getContractFactory("ProxyVotingWithRevocation");
    proxyVotingWithRevocation = await ProxyVotingWithRevocation.deploy("Proxy Voting Token", "PVT");
    await proxyVotingWithRevocation.deployed();

    // Mint some tokens to delegator
    await proxyVotingWithRevocation.transfer(delegator.address, 2000);
  });

  it("Should delegate votes to a delegate", async function () {
    await proxyVotingWithRevocation.connect(delegator).delegateVotes(delegate.address, 1000);
    const delegation = await proxyVotingWithRevocation.viewDelegation(delegator.address);
    expect(delegation[0]).to.equal(delegate.address);
    expect(delegation[1]).to.equal(1000);

    const delegatedVotes = await proxyVotingWithRevocation.viewDelegatedVotes(delegate.address);
    expect(delegatedVotes).to.equal(1000);
  });

  it("Should revoke delegation and return tokens to delegator", async function () {
    await proxyVotingWithRevocation.connect(delegator).delegateVotes(delegate.address, 1000);
    await proxyVotingWithRevocation.connect(delegator).revokeDelegation();

    const delegation = await proxyVotingWithRevocation.viewDelegation(delegator.address);
    expect(delegation[0]).to.equal(ethers.constants.AddressZero);
    expect(delegation[1]).to.equal(0);

    const delegatorBalance = await proxyVotingWithRevocation.balanceOf(delegator.address);
    expect(delegatorBalance).to.equal(2000);
  });

  it("Should not allow delegation if insufficient balance", async function () {
    await expect(
      proxyVotingWithRevocation.connect(delegator).delegateVotes(delegate.address, 3000)
    ).to.be.revertedWith("Insufficient balance to delegate");
  });

  it("Should not allow self-delegation", async function () {
    await expect(
      proxyVotingWithRevocation.connect(delegator).delegateVotes(delegator.address, 500)
    ).to.be.revertedWith("Cannot delegate to yourself");
  });
});
```

### Additional Instructions

1. **Integration with Governance Protocols:**
   - Integrate the contract with on-chain governance systems for decentralized decision-making processes.

2. **Gas Optimization:**
   - Further optimize the contract by minimizing state updates and utilizing gas-efficient data structures.

3. **Security Audits:**
   - Conduct rigorous security audits before deploying the contract to ensure it is secure and free of vulnerabilities.

4. **Multi-Network Deployment:**
   - Deploy the contract on multiple networks like Ethereum, Binance Smart Chain, and Layer-2 solutions to cater to different use cases.

5. **Advanced Governance:**
   - Implement advanced governance features such as quadratic voting, time-lock voting, and delegate incentives to enhance the flexibility and fairness of the voting process.

This contract enables token holders to delegate their votes to trusted proxies with the flexibility to revoke their delegation, ensuring robust and participative governance. It is suitable for organizations that require flexible participation and delegation in their governance processes.