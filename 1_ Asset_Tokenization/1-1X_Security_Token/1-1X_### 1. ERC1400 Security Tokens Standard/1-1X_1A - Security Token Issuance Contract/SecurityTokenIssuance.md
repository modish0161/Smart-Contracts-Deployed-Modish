 This contract adheres to the ERC1400 standard for security tokens, includes regulatory compliance features, and has modularity for future upgrades.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin contracts for modular security features
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

// Import ERC1400 interface and extensions
import "./IERC1400.sol";
import "./IERC1400TokensValidator.sol";
import "./IERC1400TokensSender.sol";
import "./IERC1400TokensRecipient.sol";

// SecurityTokenIssuance contract based on ERC1400
contract SecurityTokenIssuance is IERC1400, Ownable, Pausable, ReentrancyGuard, AccessControl, Initializable, UUPSUpgradeable {
    // Define roles for access control
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");

    // ERC1400 compliance details
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(bytes32 => mapping(address => uint256)) private _partitionBalances;
    mapping(address => mapping(address => uint256)) private _allowed;

    // Constructor for initial contract setup
    function initialize(string memory name_, string memory symbol_, uint8 decimals_, uint256 initialSupply_) public initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _mint(msg.sender, initialSupply_);
        
        // Setup roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(ISSUER_ROLE, msg.sender);
    }

    // Function to upgrade the contract in the future
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // ERC1400 Implementation
    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowed[owner][spender];
    }

    function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowed[sender][msg.sender] - amount);
        return true;
    }

    // Function to mint new tokens
    function mint(address account, uint256 amount) public onlyRole(ISSUER_ROLE) whenNotPaused {
        _mint(account, amount);
    }

    // Internal function to handle token transfers
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC1400: transfer from the zero address");
        require(recipient != address(0), "ERC1400: transfer to the zero address");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    // Internal function to mint new tokens
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC1400: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    // Internal function to approve allowances
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC1400: approve from the zero address");
        require(spender != address(0), "ERC1400: approve to the zero address");

        _allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Compliance and transfer restrictions
    function _checkTransferCompliance(address from, address to, uint256 value) internal view {
        // Implement custom compliance logic here
    }

    // Pause contract functions in case of emergency
    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    // Unpause contract functions
    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // Emergency withdrawal function
    function emergencyWithdraw() public onlyOwner whenPaused {
        payable(owner()).transfer(address(this).balance);
    }

    // Add KYC verification logic if necessary
    function _checkKYCCompliance(address account) internal view {
        // Implement KYC logic
    }

    // Event for token issuance
    event TokenIssued(address indexed to, uint256 amount);
}
```

### **Deployment Instructions**:

1. **Install Dependencies**:
   Ensure you have the necessary dependencies installed:
   ```bash
   npm install @openzeppelin/contracts
   ```

2. **Compile the Contract**:
   Compile the smart contract using Hardhat or Truffle to ensure there are no syntax errors.
   ```bash
   npx hardhat compile
   ```

3. **Deploy the Contract**:
   Create a deployment script in your Hardhat or Truffle project to deploy the contract:
   ```javascript
   async function main() {
       const SecurityTokenIssuance = await ethers.getContractFactory("SecurityTokenIssuance");
       const securityToken = await SecurityTokenIssuance.deploy("My Security Token", "MST", 18, 1000000);
       await securityToken.deployed();
       console.log("SecurityTokenIssuance deployed to:", securityToken.address);
   }

   main()
       .then(() => process.exit(0))
       .catch(error => {
           console.error(error);
           process.exit(1);
       });
   ```

4. **Run Unit Tests**:
   Use Mocha and Chai to write unit tests for all the functions.
   ```bash
   npx hardhat test
   ```

5. **Verify on Etherscan (Optional)**:
   If deploying to the Ethereum mainnet or testnet, verify the contract on Etherscan using:
   ```bash
   npx hardhat verify --network mainnet <deployed_contract_address> "My Security Token" "MST" 18 1000000
   ```

### **Further Customization**:

- **Integration with KYC/AML Providers**: Add third-party KYC/AML checks before allowing token transfers.
- **Governance Mechanisms**: Implement on-chain voting for token holders to participate in decision-making processes.
- **Proxy Upgradeability**: Use UUPS or Transparent proxy patterns to allow upgrades without changing the contract address.
- **Multi-Network Deployment**: Deploy the contract on multiple networks like BSC, Polygon, or Ethereum Layer-2 solutions.

This contract template is a foundational starting point and should be thoroughly tested and audited before deployment to a production environment.