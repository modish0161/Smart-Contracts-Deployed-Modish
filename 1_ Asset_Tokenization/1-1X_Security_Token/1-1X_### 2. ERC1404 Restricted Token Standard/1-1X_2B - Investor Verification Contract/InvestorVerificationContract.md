Below is the smart contract for the requested use case: `InvestorVerificationContract.sol`. This contract adheres to the ERC1404 standard and verifies whether token holders meet the requirements for owning the security token, such as accredited investor status, geographical restrictions, or regulatory compliance.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin libraries for modular security features
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Import ERC1404 interface and extensions
import "./IERC1404.sol";

// InvestorVerificationContract based on ERC1404 standard
contract InvestorVerificationContract is IERC1404, Ownable, AccessControl, Pausable, ReentrancyGuard {
    // Define roles for access control
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");

    // ERC1404 compliance details
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(bytes32 => mapping(address => uint256)) private _partitionBalances;
    mapping(address => mapping(address => uint256)) private _allowed;

    // Investor verification data structures
    mapping(address => bool) private _whitelistedInvestors;
    mapping(address => bool) private _blacklistedInvestors;
    mapping(address => string) private _investorStatus; // e.g., "accredited", "non-accredited", "restricted", etc.

    // Events for investor verification management
    event InvestorWhitelisted(address indexed account, string status);
    event InvestorBlacklisted(address indexed account, string reason);
    event InvestorStatusUpdated(address indexed account, string newStatus);

    // Constructor for initial contract setup
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _mint(msg.sender, initialSupply_);

        // Setup roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(COMPLIANCE_OFFICER_ROLE, msg.sender);
    }

    // ERC1404 Implementation
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
        _checkTransferRestrictions(msg.sender, recipient, amount);
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
        _checkTransferRestrictions(sender, recipient, amount);
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowed[sender][msg.sender] - amount);
        return true;
    }

    // Function to mint new tokens
    function mint(address account, uint256 amount) public onlyRole(ADMIN_ROLE) whenNotPaused {
        _mint(account, amount);
    }

    // Internal function to handle token transfers
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC1404: transfer from the zero address");
        require(recipient != address(0), "ERC1404: transfer to the zero address");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    // Internal function to mint new tokens
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC1404: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    // Internal function to approve allowances
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC1404: approve from the zero address");
        require(spender != address(0), "ERC1404: approve to the zero address");

        _allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Function to add an investor to the whitelist
    function addWhitelistedInvestor(address account, string memory status) public onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _whitelistedInvestors[account] = true;
        _investorStatus[account] = status;
        emit InvestorWhitelisted(account, status);
    }

    // Function to add an investor to the blacklist
    function addBlacklistedInvestor(address account, string memory reason) public onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _blacklistedInvestors[account] = true;
        _investorStatus[account] = reason;
        emit InvestorBlacklisted(account, reason);
    }

    // Function to update an investor's status
    function updateInvestorStatus(address account, string memory newStatus) public onlyRole(COMPLIANCE_OFFICER_ROLE) {
        require(_whitelistedInvestors[account], "InvestorVerificationContract: investor is not whitelisted");
        _investorStatus[account] = newStatus;
        emit InvestorStatusUpdated(account, newStatus);
    }

    // Function to check transfer restrictions
    function _checkTransferRestrictions(address sender, address recipient, uint256 amount) internal view {
        require(!_blacklistedInvestors[sender], "InvestorVerificationContract: sender is blacklisted");
        require(!_blacklistedInvestors[recipient], "InvestorVerificationContract: recipient is blacklisted");
        require(_whitelistedInvestors[sender], "InvestorVerificationContract: sender is not whitelisted");
        require(_whitelistedInvestors[recipient], "InvestorVerificationContract: recipient is not whitelisted");
    }

    // Function to get transfer restriction message code
    function detectTransferRestriction(address sender, address recipient, uint256 amount) public view returns (uint8) {
        if (_blacklistedInvestors[sender]) {
            return 1; // Sender is blacklisted
        }
        if (_blacklistedInvestors[recipient]) {
            return 2; // Recipient is blacklisted
        }
        if (!_whitelistedInvestors[sender]) {
            return 3; // Sender is not whitelisted
        }
        if (!_whitelistedInvestors[recipient]) {
            return 4; // Recipient is not whitelisted
        }
        return 0; // No restriction
    }

    // Function to get transfer restriction message text
    function messageForTransferRestriction(uint8 restrictionCode) public pure returns (string memory) {
        if (restrictionCode == 1) {
            return "Sender is blacklisted";
        }
        if (restrictionCode == 2) {
            return "Recipient is blacklisted";
        }
        if (restrictionCode == 3) {
            return "Sender is not whitelisted";
        }
        if (restrictionCode == 4) {
            return "Recipient is not whitelisted";
        }
        return "No restriction";
    }

    // Function to get investor status
    function getInvestorStatus(address account) public view returns (string memory) {
        return _investorStatus[account];
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
       const InvestorVerificationContract = await ethers.getContractFactory("InvestorVerificationContract");
       const investorVerificationContract = await InvestorVerificationContract.deploy("Investor Verification Token", "IVT", 18, 1000000);
       await investorVerificationContract.deployed();
       console.log("InvestorVerificationContract deployed to:", investorVerificationContract.address);
   }

   main()
       .then(() => process.exit(0))
       .catch(error => {
           console.error(error);
           process.exit(1);
       });
   ```

4. **Run Unit Tests**:
   Use Mocha and Chai to write unit tests for

 all the functions.
   ```bash
   npx hardhat test
   ```

5. **Verify on Etherscan (Optional)**:
   If deploying to the Ethereum mainnet or testnet, verify the contract on Etherscan using:
   ```bash
   npx hardhat verify --network mainnet <deployed_contract_address> "Investor Verification Token" "IVT" 18 1000000
   ```

### **Further Customization**:

- **Dynamic Investor Status Management**: Allow admin to update investor status dynamically based on specific conditions or rules.
- **Integration with Third-Party Services**: Integrate with third-party KYC/AML services for automated investor verification.
- **Governance Mechanisms**: Implement on-chain voting for token holders to participate in decision-making processes, such as modifying investor verification rules.
- **Proxy Upgradeability**: Use UUPS or Transparent proxy patterns to allow upgrades without changing the contract address.
- **Multi-Network Deployment**: Deploy the contract on multiple networks like BSC, Polygon, or Ethereum Layer-2 solutions.

This contract template provides a strong foundation for implementing investor verification functionalities based on compliance requirements. It should be thoroughly tested and audited before deployment to a production environment.