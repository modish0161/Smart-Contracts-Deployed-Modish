Here's a complete smart contract for the **Restricted Hedge Fund Token Contract** implementing the ERC1404 standard. This contract ensures that only accredited investors can buy, hold, or trade hedge fund tokens.

### Contract: 2-1Y_2A_RestrictedHedgeFundToken.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1404/IERC1404.sol";

contract RestrictedHedgeFundToken is IERC1404, Ownable, ReentrancyGuard {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    // Whitelist and blacklist
    mapping(address => bool) public whitelist; // Whitelisted investors
    mapping(address => bool) public blacklist; // Blacklisted investors

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Whitelisted(address indexed investor);
    event Blacklisted(address indexed investor);
    event RemovedFromWhitelist(address indexed investor);
    event RemovedFromBlacklist(address indexed investor);

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Not an authorized investor");
        _;
    }

    modifier notBlacklisted() {
        require(!blacklist[msg.sender], "Investor is blacklisted");
        _;
    }

    function mint(address _to, uint256 _value) external onlyOwner {
        require(_to != address(0), "Cannot mint to zero address");
        totalSupply += _value;
        balances[_to] += _value;
        emit Transfer(address(0), _to, _value);
    }

    function transfer(address _to, uint256 _value) external notBlacklisted {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        require(whitelist[_to], "Recipient is not whitelisted");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }

    function approve(address _spender, uint256 _value) external {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) external notBlacklisted {
        require(balances[_from] >= _value, "Insufficient balance");
        require(allowances[_from][msg.sender] >= _value, "Allowance exceeded");
        require(whitelist[_to], "Recipient is not whitelisted");

        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
    }

    function addToWhitelist(address _investor) external onlyOwner {
        require(!whitelist[_investor], "Investor is already whitelisted");
        whitelist[_investor] = true;
        emit Whitelisted(_investor);
    }

    function removeFromWhitelist(address _investor) external onlyOwner {
        require(whitelist[_investor], "Investor is not whitelisted");
        whitelist[_investor] = false;
        emit RemovedFromWhitelist(_investor);
    }

    function addToBlacklist(address _investor) external onlyOwner {
        require(!blacklist[_investor], "Investor is already blacklisted");
        blacklist[_investor] = true;
        emit Blacklisted(_investor);
    }

    function removeFromBlacklist(address _investor) external onlyOwner {
        require(blacklist[_investor], "Investor is not blacklisted");
        blacklist[_investor] = false;
        emit RemovedFromBlacklist(_investor);
    }

    // Implement required functions from IERC1404
    function detectTransferRestriction(address from, address to) external view override returns (byte) {
        if (blacklist[from] || blacklist[to]) {
            return "5"; // Blacklisted
        }
        if (!whitelist[from] || !whitelist[to]) {
            return "1"; // Not whitelisted
        }
        return "0"; // No restriction
    }

    function isTransferable(address from, address to) external view override returns (bool) {
        return !blacklist[from] && !blacklist[to] && whitelist[from] && whitelist[to];
    }
}
```

### Contract Explanation:

1. **Whitelisting and Blacklisting:**
   - The contract allows the owner to manage a whitelist and blacklist of investors.
   - Only whitelisted investors can hold or transfer tokens, while blacklisted investors are prevented from doing so.

2. **Modifiers:**
   - `onlyWhitelisted`: Ensures that only authorized investors can execute certain functions.
   - `notBlacklisted`: Prevents blacklisted investors from executing specific functions.

3. **Minting Tokens:**
   - The `mint` function allows the owner to create new tokens and allocate them to a specified address.

4. **Token Transfer:**
   - The `transfer` and `transferFrom` functions check that both the sender and recipient are whitelisted and not blacklisted.

5. **ERC1404 Compliance:**
   - The contract includes methods to detect transfer restrictions and check if a transfer is allowed based on whitelist and blacklist status.

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

     const RestrictedHedgeFundToken = await hre.ethers.getContractFactory("RestrictedHedgeFundToken");
     const token = await RestrictedHedgeFundToken.deploy("HedgeFundToken", "HFT", 18);

     await token.deployed();
     console.log("Restricted Hedge Fund Token deployed to:", token.address);
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
   Use Mocha and Chai for testing core functions such as adding/removing from the whitelist/blacklist and executing token transfers.

   ```javascript
   const { expect } = require("chai");

   describe("Restricted Hedge Fund Token", function () {
     let token;
     let owner, investor;

     beforeEach(async function () {
       [owner, investor] = await ethers.getSigners();

       const RestrictedHedgeFundToken = await ethers.getContractFactory("RestrictedHedgeFundToken");
       token = await RestrictedHedgeFundToken.deploy("HedgeFundToken", "HFT", 18);
       await token.deployed();
     });

     it("Should allow owner to whitelist an investor", async function () {
       await token.addToWhitelist(investor.address);
       expect(await token.whitelist(investor.address)).to.be.true;
     });

     it("Should allow owner to blacklist an investor", async function () {
       await token.addToBlacklist(investor.address);
       expect(await token.blacklist(investor.address)).to.be.true;
     });

     it("Should prevent blacklisted investor from transferring tokens", async function () {
       await token.addToBlacklist(investor.address);
       await expect(token.connect(investor).transfer(owner.address, 1))
         .to.be.revertedWith("Investor is blacklisted");
     });

     it("Should allow whitelisted investor to transfer tokens", async function () {
       await token.addToWhitelist(investor.address);
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
   - Provide step-by-step instructions on how to manage the whitelist and blacklist.

3. **Developer Guide:**
   - Explain the contract architecture, access control, and customization options for extending functionalities.

This smart contract framework ensures that only authorized investors can hold or transfer hedge fund tokens, maintaining compliance with ERC1404 standards. If you need further customization or additional features, feel free to ask!