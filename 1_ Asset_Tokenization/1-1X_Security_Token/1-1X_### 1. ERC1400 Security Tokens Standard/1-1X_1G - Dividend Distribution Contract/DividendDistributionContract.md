Below is the smart contract for the requested use case: `DividendDistributionContract.sol`. This contract adheres to the ERC1400 standard and automatically distributes dividends to token holders based on their token holdings. It is ideal for security tokens representing stocks or other yield-bearing assets.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import OpenZeppelin libraries for modular security features
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Import ERC1400 interface and extensions
import "./IERC1400.sol";
import "./IERC1400TokensValidator.sol";
import "./IERC1400TokensSender.sol";
import "./IERC1400TokensRecipient.sol";

// DividendDistributionContract based on ERC1400 standard
contract DividendDistributionContract is IERC1400, Ownable, AccessControl, Pausable, ReentrancyGuard {
    // Define roles for access control
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant DIVIDEND_MANAGER_ROLE = keccak256("DIVIDEND_MANAGER_ROLE");

    // ERC1400 compliance details
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(bytes32 => mapping(address => uint256)) private _partitionBalances;
    mapping(address => mapping(address => uint256)) private _allowed;

    // Dividend distribution tracking
    mapping(address => uint256) private _dividends;
    mapping(address => uint256) private _lastDividendPoints;
    uint256 private _totalDividendPoints;
    uint256 private _unclaimedDividends;

    IERC20 private _dividendToken;

    // Events for dividend distribution
    event DividendsDistributed(uint256 amount);
    event DividendClaimed(address indexed account, uint256 amount);

    // Constructor for initial contract setup
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        address dividendToken_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _mint(msg.sender, initialSupply_);
        _dividendToken = IERC20(dividendToken_);
        
        // Setup roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DIVIDEND_MANAGER_ROLE, msg.sender);
    }

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
        _updateAccount(msg.sender);
        _updateAccount(recipient);
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
        _updateAccount(sender);
        _updateAccount(recipient);
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowed[sender][msg.sender] - amount);
        return true;
    }

    // Function to mint new tokens
    function mint(address account, uint256 amount) public onlyRole(ADMIN_ROLE) whenNotPaused {
        _updateAccount(account);
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

    // Function to distribute dividends to all token holders
    function distributeDividends(uint256 amount) public onlyRole(DIVIDEND_MANAGER_ROLE) whenNotPaused {
        require(_totalSupply > 0, "DividendDistributionContract: total supply is zero");
        require(_dividendToken.transferFrom(msg.sender, address(this), amount), "DividendDistributionContract: transfer failed");

        _totalDividendPoints += (amount * 1e18) / _totalSupply;
        _unclaimedDividends += amount;

        emit DividendsDistributed(amount);
    }

    // Function for token holders to claim their dividends
    function claimDividend() public whenNotPaused {
        _updateAccount(msg.sender);
        uint256 dividend = _dividends[msg.sender];
        require(dividend > 0, "DividendDistributionContract: no dividends to claim");

        _dividends[msg.sender] = 0;
        _unclaimedDividends -= dividend;
        require(_dividendToken.transfer(msg.sender, dividend), "DividendDistributionContract: transfer failed");

        emit DividendClaimed(msg.sender, dividend);
    }

    // Internal function to update dividend balance of an account
    function _updateAccount(address account) internal {
        uint256 owed = (_totalDividendPoints - _lastDividendPoints[account]) * _balances[account] / 1e18;
        _dividends[account] += owed;
        _lastDividendPoints[account] = _totalDividendPoints;
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
       const DividendDistributionContract = await ethers.getContractFactory("DividendDistributionContract");
       const dividendToken = "0xYourDividendTokenAddress"; // Replace with your dividend token address
       const dividendDistributionContract = await DividendDistributionContract.deploy("Dividend Security Token", "DST", 18, 1000000, dividendToken);
       await dividendDistributionContract.deployed();
       console.log("DividendDistributionContract deployed to:", dividendDistributionContract.address);
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
   npx hardhat verify --network mainnet <deployed_contract_address> "Dividend Security Token" "DST" 18 1000000 <dividendToken>
   ```

### **Further Customization**:

- **Dynamic Dividend Distribution**: Allow admin to dynamically adjust dividend distribution based on specific conditions or rules.
- **Governance Mechanisms**: Implement on-chain voting for token holders to participate in decision-making processes, such as adjusting dividend payout frequencies.
- **Proxy Upgradeability**: Use UUPS or Transparent proxy patterns to allow upgrades without changing the contract address.
- **Multi-Network Deployment**: Deploy the contract on multiple networks like BSC, Polygon, or Ethereum Layer-2 solutions.

This contract template provides a strong foundation for implementing automated dividend distribution based on token holdings. It should be thoroughly tested and audited before deployment to a production environment.