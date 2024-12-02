### Solidity Smart Contract for `Accredited Investor Verification for Equity Tokens`

This contract will utilize AnonCreds for privacy-preserving accreditation and verification of investors. Although AnonCreds is not directly supported by Solidity, this implementation will use a simplified approach with placeholders for AnonCreds integration points.

#### Contract Code: `AccreditedInvestorVerification.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract AccreditedInvestorVerification is Ownable, ReentrancyGuard, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private accreditedInvestors;

    event InvestorVerified(address indexed investor);
    event InvestorRevoked(address indexed investor);
    event VerificationRequested(address indexed investor);

    // Placeholder for AnonCreds integration point for credential verification
    struct AnonCred {
        bytes32 proof;
        bytes32 publicKey;
    }

    mapping(address => AnonCred) private investorCredentials;

    // Modifier to check if the caller is an accredited investor
    modifier onlyAccredited() {
        require(isAccredited(msg.sender), "Not an accredited investor");
        _;
    }

    constructor() {}

    /**
     * @dev Request verification as an accredited investor.
     * This is a placeholder function to integrate AnonCreds in a real-world scenario.
     * @param proof The proof of accreditation.
     * @param publicKey The public key linked to the proof.
     */
    function requestVerification(bytes32 proof, bytes32 publicKey) external whenNotPaused {
        investorCredentials[msg.sender] = AnonCred(proof, publicKey);
        emit VerificationRequested(msg.sender);
    }

    /**
     * @dev Verify an investor manually. Only owner can call this.
     * This is a simplified manual verification function.
     * @param investor The address of the investor to be verified.
     */
    function verifyInvestor(address investor) external onlyOwner whenNotPaused {
        accreditedInvestors.add(investor);
        emit InvestorVerified(investor);
    }

    /**
     * @dev Revoke an investor's accredited status. Only owner can call this.
     * @param investor The address of the investor to be revoked.
     */
    function revokeInvestor(address investor) external onlyOwner whenNotPaused {
        accreditedInvestors.remove(investor);
        emit InvestorRevoked(investor);
    }

    /**
     * @dev Check if an address is an accredited investor.
     * @param investor The address to check.
     * @return True if the address is accredited, false otherwise.
     */
    function isAccredited(address investor) public view returns (bool) {
        return accreditedInvestors.contains(investor);
    }

    /**
     * @dev Pause the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
```

### Deployment Script (`deploy.js`)

Create a deployment script using Hardhat for deploying the `AccreditedInvestorVerification.sol` contract.

```javascript
// deploy.js
const hre = require("hardhat");

async function main() {
  // Compile the contract
  const AccreditedInvestorVerification = await hre.ethers.getContractFactory("AccreditedInvestorVerification");

  // Deploy the contract
  const accreditedInvestorVerification = await AccreditedInvestorVerification.deploy();

  // Wait for the contract to be deployed
  await accreditedInvestorVerification.deployed();

  // Log the address of the deployed contract
  console.log("AccreditedInvestorVerification deployed to:", accreditedInvestorVerification.address);
}

// Run the deployment script
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### Testing Script (`test/AccreditedInvestorVerification.test.js`)

Create a testing script to verify the core functionalities of the `AccreditedInvestorVerification` contract using Mocha, Chai, and Hardhat Waffle.

```javascript
// test/AccreditedInvestorVerification.test.js
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AccreditedInvestorVerification", function () {
  let owner, investor1, investor2;
  let accreditedInvestorVerification;

  beforeEach(async function () {
    [owner, investor1, investor2] = await ethers.getSigners();

    // Deploy the AccreditedInvestorVerification contract
    const AccreditedInvestorVerification = await ethers.getContractFactory("AccreditedInvestorVerification");
    accreditedInvestorVerification = await AccreditedInvestorVerification.deploy();
    await accreditedInvestorVerification.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await accreditedInvestorVerification.owner()).to.equal(owner.address);
    });
  });

  describe("Investor Verification", function () {
    it("Should allow owner to verify an investor", async function () {
      await accreditedInvestorVerification.verifyInvestor(investor1.address);
      expect(await accreditedInvestorVerification.isAccredited(investor1.address)).to.be.true;
    });

    it("Should emit event when investor is verified", async function () {
      await expect(accreditedInvestorVerification.verifyInvestor(investor1.address))
        .to.emit(accreditedInvestorVerification, "InvestorVerified")
        .withArgs(investor1.address);
    });

    it("Should allow owner to revoke an investor", async function () {
      await accreditedInvestorVerification.verifyInvestor(investor1.address);
      await accreditedInvestorVerification.revokeInvestor(investor1.address);
      expect(await accreditedInvestorVerification.isAccredited(investor1.address)).to.be.false;
    });

    it("Should emit event when investor is revoked", async function () {
      await accreditedInvestorVerification.verifyInvestor(investor1.address);
      await expect(accreditedInvestorVerification.revokeInvestor(investor1.address))
        .to.emit(accreditedInvestorVerification, "InvestorRevoked")
        .withArgs(investor1.address);
    });
  });

  describe("Pausable Functionality", function () {
    it("Should allow the owner to pause and unpause the contract", async function () {
      // Pause the contract
      await accreditedInvestorVerification.pause();
      expect(await accreditedInvestorVerification.paused()).to.be.true;

      // Unpause the contract
      await accreditedInvestorVerification.unpause();
      expect(await accreditedInvestorVerification.paused()).to.be.false;
    });

    it("Should revert when performing actions while paused", async function () {
      // Pause the contract
      await accreditedInvestorVerification.pause();

      // Try to verify an investor
      await expect(accreditedInvestorVerification.verifyInvestor(investor1.address)).to.be.revertedWith("Pausable: paused");
    });
  });

  describe("Request Verification", function () {
    it("Should allow investor to request verification with proof", async function () {
      const proof = ethers.utils.formatBytes32String("proof");
      const publicKey = ethers.utils.formatBytes32String("publicKey");

      await accreditedInvestorVerification.connect(investor1).requestVerification(proof, publicKey);

      const credential = await accreditedInvestorVerification.investorCredentials(investor1.address);
      expect(credential.proof).to.equal(proof);
      expect(credential.publicKey).to.equal(publicKey);
    });

    it("Should emit event when verification is requested", async function () {
      const proof = ethers.utils.formatBytes32String("proof");
      const publicKey = ethers.utils.formatBytes32String("publicKey");

      await expect(accreditedInvestorVerification.connect(investor1).requestVerification(proof, publicKey))
        .to.emit(accreditedInvestorVerification, "VerificationRequested")
        .withArgs(investor1.address);
    });
  });
});
```

### Deployment and Testing Instructions

1. **Install Dependencies**:
   ```bash
   npm install --save-dev @openzeppelin/contracts hardhat ethers mocha chai
   ```

2. **Deploy the Contract**:
   ```bash
   npx hardhat run scripts/deploy.js --network <your_network>
   ```

3. **Run the Tests**:
   ```bash
   npx hardhat test
   ```

This setup provides a complete smart contract for `AccreditedInvestorVerification.sol` with a simplified structure, along with deployment and testing scripts to ensure the contract functions correctly. For real-world scenarios, integration with AnonCreds would require off-chain interactions, which are not directly implementable in Solidity alone.