Below is the smart contract for the requested use case: `TaxWithholdingContract.sol`. This contract adheres to the ERC1404 standard and manages the calculation and automatic withholding of taxes on token transactions or distributions to ensure proper tax compliance for investors.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin libraries for modular security features
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Import ERC1404 interface and extensions
import "./IERC1404.sol";

// TaxWithholdingContract based on ERC1404 standard
contract TaxWithholdingContract is IERC1404, Ownable, AccessControl, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // Define roles for access control
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant COMPLIANCE_OFFICER_ROLE = keccak256("COMPLIANCE_OFFICER_ROLE");

    // ERC1404 compliance details
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowed;

    // Tax withholding parameters
    uint256 public taxRate; // Tax rate as a percentage (e.g., 5 for 5%)
    mapping(address => bool) private _taxExemptAddresses; // List of tax-exempt addresses
    mapping(address => uint256) private _withheldTaxes; // Withheld tax amounts per address

    // Events for tax withholding management
    event TaxWithheld(address indexed from, address indexed to, uint256 amount, uint256 taxAmount);
    event TaxExemptAddressAdded(address indexed account);
    event TaxExemptAddressRemoved(address indexed account);
    event TaxRateUpdated(uint256 oldRate, uint256 newRate);
    event TaxWithdrawn(address indexed admin, uint256 amount);

    // Constructor for initial contract setup
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        uint256 initialTaxRate_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _mint(msg.sender, initialSupply_);

        // Set initial tax rate
        taxRate = initialTaxRate_;

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
        _transferWithTax(msg.sender, recipient, amount);
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
        _transferWithTax(sender, recipient, amount);
        _approve(sender, msg.sender, _allowed[sender][msg.sender] - amount);
        return true;
    }

    // Function to mint new tokens
    function mint(address account, uint256 amount) public onlyRole(ADMIN_ROLE) whenNotPaused {
        _mint(account, amount);
    }

    // Internal function to handle token transfers with tax withholding
    function _transferWithTax(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC1404: transfer from the zero address");
        require(recipient != address(0), "ERC1404: transfer to the zero address");

        uint256 taxAmount = 0;
        if (!_taxExemptAddresses[sender] && !_taxExemptAddresses[recipient]) {
            taxAmount = amount.mul(taxRate).div(100);
            _withheldTaxes[owner()] = _withheldTaxes[owner()].add(taxAmount);
        }

        uint256 transferAmount = amount.sub(taxAmount);

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(transferAmount);
        emit TaxWithheld(sender, recipient, transferAmount, taxAmount);
        emit Transfer(sender, recipient, transferAmount);
    }

    // Internal function to mint new tokens
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC1404: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    // Internal function to approve allowances
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC1404: approve from the zero address");
        require(spender != address(0), "ERC1404: approve to the zero address");

        _allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Function to add a tax-exempt address
    function addTaxExemptAddress(address account) public onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _taxExemptAddresses[account] = true;
        emit TaxExemptAddressAdded(account);
    }

    // Function to remove a tax-exempt address
    function removeTaxExemptAddress(address account) public onlyRole(COMPLIANCE_OFFICER_ROLE) {
        _taxExemptAddresses[account] = false;
        emit TaxExemptAddressRemoved(account);
    }

    // Function to update the tax rate
    function updateTaxRate(uint256 newTaxRate) public onlyRole(COMPLIANCE_OFFICER_ROLE) {
        require(newTaxRate <= 100, "TaxWithholdingContract: tax rate cannot exceed 100%");
        uint256 oldRate = taxRate;
        taxRate = newTaxRate;
        emit TaxRateUpdated(oldRate, newTaxRate);
    }

    // Function to withdraw withheld taxes
    function withdrawWithheldTaxes() public onlyRole(ADMIN_ROLE) nonReentrant {
        uint256 amount = _withheldTaxes[owner()];
        require(amount > 0, "TaxWithholdingContract: no withheld taxes to withdraw");

        _withheldTaxes[owner()] = 0;
        payable(owner()).transfer(amount);
        emit TaxWithdrawn(owner(), amount);
    }

    // Function to check transfer restrictions
    function _checkTransferRestrictions(address sender, address recipient, uint256 amount) internal view {
        require(sender != address(0), "ERC1404: sender address is zero");
        require(recipient != address(0), "ERC1404: recipient address is zero");
    }

    // Function to get transfer restriction message code
    function detectTransferRestriction(address sender, address recipient, uint256 amount) public view returns (uint8) {
        return 0; // No restriction for this basic implementation
    }

    // Function to get transfer restriction message text
    function messageForTransferRestriction(uint8 restrictionCode) public pure returns (string memory) {
        return "No restriction";
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
       const TaxWithholdingContract = await ethers.getContractFactory("TaxWithholdingContract");
       const taxWithholdingContract = await TaxWithholdingContract.deploy(
           "Tax Withholding Token",
           "TWT",
           18,
           1000000,
           5 // Initial tax rate of 5%
       );
       await taxWithholdingContract.deployed();
       console.log("TaxWithholdingContract deployed to:", taxWithholdingContract.address);
   }

   main()
       .then(() => process.exit(0))
       .catch(error => {
           console.error(error);
           process.exit(

1);
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
   npx hardhat verify --network mainnet <deployed_contract_address> "Tax Withholding Token" "TWT" 18 1000000 5
   ```

### **Further Customization**:

- **Dynamic Tax Rates**: Implement a system to update the tax rates dynamically based on specific conditions or rules.
- **Integration with External APIs**: Integrate with tax compliance APIs to automatically calculate and remit withheld taxes to the appropriate tax authorities.
- **On-Chain Governance**: Implement on-chain governance to enable token holders to vote on tax rates or other compliance-related parameters.
- **Proxy Upgradeability**: Use UUPS or Transparent proxy patterns to allow upgrades without changing the contract address.
- **Multi-Network Deployment**: Deploy the contract on multiple networks like BSC, Polygon, or Ethereum Layer-2 solutions.

This contract template provides a strong foundation for implementing tax withholding functionalities based on compliance requirements. It should be thoroughly tested and audited before deployment to a production environment.