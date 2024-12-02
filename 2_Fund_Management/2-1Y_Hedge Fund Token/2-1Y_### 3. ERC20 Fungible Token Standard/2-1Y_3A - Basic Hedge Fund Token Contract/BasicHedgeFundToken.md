Here’s a complete smart contract for the **Basic Hedge Fund Token Contract** based on the ERC20 standard. This contract will tokenize fractional ownership in a hedge fund, allowing for easy trading and transferring of tokens.

### Contract: 2-1Y_3A_BasicHedgeFundToken.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BasicHedgeFundToken is ERC20, Ownable, ReentrancyGuard {
    uint256 public maxSupply;
    mapping(address => bool) private accreditedInvestors;

    event InvestorAccredited(address indexed investor);
    event InvestorDe-accredited(address indexed investor);

    constructor(string memory name, string memory symbol, uint256 _maxSupply) 
        ERC20(name, symbol) {
        maxSupply = _maxSupply * (10 ** decimals());
    }

    modifier onlyAccredited() {
        require(accreditedInvestors[msg.sender], "Not an accredited investor");
        _;
    }

    function mint(uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        _mint(msg.sender, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override onlyAccredited returns (bool) {
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override onlyAccredited returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    function setAccreditedInvestor(address investor, bool status) external onlyOwner {
        accreditedInvestors[investor] = status;
        if (status) {
            emit InvestorAccredited(investor);
        } else {
            emit InvestorDe-accredited(investor);
        }
    }

    function isAccreditedInvestor(address investor) external view returns (bool) {
        return accreditedInvestors[investor];
    }
}
```

### Contract Explanation:

1. **Token Management:**
   - The contract inherits from OpenZeppelin's `ERC20`, allowing easy management of fungible tokens.
   - The `mint` function allows the contract owner to issue new tokens, ensuring it does not exceed the maximum supply.

2. **Accredited Investor Management:**
   - The `accreditedInvestors` mapping keeps track of who is an accredited investor.
   - Only accredited investors can transfer tokens, ensuring compliance with regulations.

3. **Events:**
   - Emits events when investors are accredited or de-accredited, allowing for better tracking and transparency.

### Deployment Instructions:

1. **Prerequisites:**
   - Ensure you have Node.js and Hardhat installed.
   - Install OpenZeppelin contracts:
     ```bash
     npm install @openzeppelin/contracts
     ```

2. **Deployment Script:**
   Create a deployment script `deploy.js` in the `scripts` folder:

   ```javascript
   const hre = require("hardhat");

   async function main() {
     const [deployer] = await hre.ethers.getSigners();
     console.log("Deploying contracts with the account:", deployer.address);

     const HedgeFundToken = await hre.ethers.getContractFactory("BasicHedgeFundToken");
     const token = await HedgeFundToken.deploy("Hedge Fund Token", "HFT", 1000000); // 1 million max supply

     await token.deployed();
     console.log("Basic Hedge Fund Token deployed to:", token.address);
   }

   main()
     .then(() => process.exit(0))
     .catch((error) => {
       console.error(error);
       process.exit(1);
     });
   ```

3. **Run the Deployment Script:**
   ```bash
   npx hardhat run scripts/deploy.js --network [network-name]
   ```

### Testing Suite:

1. **Basic Tests:**
   Use Mocha and Chai for testing core functions such as minting tokens and transferring them.

   ```javascript
   const { expect } = require("chai");

   describe("Basic Hedge Fund Token", function () {
     let token;
     let owner, investor;

     beforeEach(async function () {
       [owner, investor] = await ethers.getSigners();

       const HedgeFundToken = await ethers.getContractFactory("BasicHedgeFundToken");
       token = await HedgeFundToken.deploy("Hedge Fund Token", "HFT", 1000000);
       await token.deployed();
     });

     it("Should allow owner to mint tokens", async function () {
       await token.mint(100);
       expect(await token.totalSupply()).to.equal(100);
     });

     it("Should allow accredited investor to transfer tokens", async function () {
       await token.mint(100);
       await token.setAccreditedInvestor(investor.address, true);
       await token.connect(investor).transfer(owner.address, 50);
       expect(await token.balanceOf(owner.address)).to.equal(50);
     });

     it("Should prevent non-accredited investor from transferring tokens", async function () {
       await token.mint(100);
       await expect(token.connect(investor).transfer(owner.address, 1))
         .to.be.revertedWith("Not an accredited investor");
     });
   });
   ```

2. **Run Tests:**
   ```bash
   npx hardhat test
   ```

### Documentation:

1. **API Documentation:**
   - Include detailed NatSpec comments for each function, event, and modifier in the contract.

2. **User Guide:**
   - Provide step-by-step instructions on how to manage the hedge fund tokens and accreditation status.

3. **Developer Guide:**
   - Explain the contract architecture, including token management and accreditation processes.

This smart contract framework provides a solid foundation for managing fractional ownership in a hedge fund. If you need any additional features or modifications, just let me know!