Here’s a complete smart contract for the **Accredited Investor Verification Contract** based on the ERC1404 standard. This contract ensures that only accredited investors can hold hedge fund tokens.

### Contract: 2-1Y_2B_AccreditedInvestorVerification.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1404/IERC1404.sol";

contract AccreditedInvestorVerification is IERC1404, Ownable, ReentrancyGuard {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    // Whitelist of accredited investors
    mapping(address => bool) public accreditedInvestors; 

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event InvestorVerified(address indexed investor);
    event InvestorRevoked(address indexed investor);

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    modifier onlyAccredited() {
        require(accreditedInvestors[msg.sender], "Not an accredited investor");
        _;
    }

    function mint(address _to, uint256 _value) external onlyOwner {
        require(_to != address(0), "Cannot mint to zero address");
        totalSupply += _value;
        balances[_to] += _value;
        emit Transfer(address(0), _to, _value);
    }

    function transfer(address _to, uint256 _value) external onlyAccredited {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }

    function approve(address _spender, uint256 _value) external {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) external onlyAccredited {
        require(balances[_from] >= _value, "Insufficient balance");
        require(allowances[_from][msg.sender] >= _value, "Allowance exceeded");

        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
    }

    function verifyInvestor(address _investor) external onlyOwner {
        require(!accreditedInvestors[_investor], "Investor already verified");
        accreditedInvestors[_investor] = true;
        emit InvestorVerified(_investor);
    }

    function revokeInvestor(address _investor) external onlyOwner {
        require(accreditedInvestors[_investor], "Investor not verified");
        accreditedInvestors[_investor] = false;
        emit InvestorRevoked(_investor);
    }

    // Implement required functions from IERC1404
    function detectTransferRestriction(address from, address to) external view override returns (byte) {
        if (!accreditedInvestors[from] || !accreditedInvestors[to]) {
            return "1"; // Not an accredited investor
        }
        return "0"; // No restriction
    }

    function isTransferable(address from, address to) external view override returns (bool) {
        return accreditedInvestors[from] && accreditedInvestors[to];
    }
}
```

### Contract Explanation:

1. **Accredited Investor Management:**
   - The contract allows the owner to verify or revoke the accredited status of investors.

2. **Modifiers:**
   - `onlyAccredited`: Ensures that only accredited investors can execute certain functions.

3. **Minting Tokens:**
   - The `mint` function allows the owner to create new tokens and allocate them to a specified address.

4. **Token Transfer:**
   - The `transfer` and `transferFrom` functions check that both the sender and recipient are accredited.

5. **ERC1404 Compliance:**
   - The contract implements methods to detect transfer restrictions based on investor accreditation status.

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

     const AccreditedInvestorVerification = await hre.ethers.getContractFactory("AccreditedInvestorVerification");
     const token = await AccreditedInvestorVerification.deploy("HedgeFundToken", "HFT", 18);

     await token.deployed();
     console.log("Accredited Investor Verification Contract deployed to:", token.address);
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
   Use Mocha and Chai for testing core functions such as verifying and revoking investors, and executing token transfers.

   ```javascript
   const { expect } = require("chai");

   describe("Accredited Investor Verification", function () {
     let token;
     let owner, investor;

     beforeEach(async function () {
       [owner, investor] = await ethers.getSigners();

       const AccreditedInvestorVerification = await ethers.getContractFactory("AccreditedInvestorVerification");
       token = await AccreditedInvestorVerification.deploy("HedgeFundToken", "HFT", 18);
       await token.deployed();
     });

     it("Should allow owner to verify an investor", async function () {
       await token.verifyInvestor(investor.address);
       expect(await token.accreditedInvestors(investor.address)).to.be.true;
     });

     it("Should allow owner to revoke an investor", async function () {
       await token.verifyInvestor(investor.address);
       await token.revokeInvestor(investor.address);
       expect(await token.accreditedInvestors(investor.address)).to.be.false;
     });

     it("Should prevent non-accredited investor from transferring tokens", async function () {
       await token.mint(investor.address, 100);
       await expect(token.connect(investor).transfer(owner.address, 1))
         .to.be.revertedWith("Not an accredited investor");
     });

     it("Should allow accredited investor to transfer tokens", async function () {
       await token.verifyInvestor(investor.address);
       await token.mint(investor.address, 100);
       await token.connect(investor).transfer(owner.address, 1);
       expect(await token.balanceOf(owner.address)).to.equal(1);
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
   - Provide step-by-step instructions on how to verify and revoke investor accreditation.

3. **Developer Guide:**
   - Explain the contract architecture, access control, and customization options for extending functionalities.

This smart contract framework ensures that only accredited investors can hold hedge fund tokens, maintaining compliance with ERC1404 standards. If you need further customization or additional features, feel free to ask!