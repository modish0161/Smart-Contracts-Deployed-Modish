### Smart Contract: `EquityTokenGovernance.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title Equity Token Governance Contract
/// @notice This contract allows equity token holders to vote on corporate decisions such as board elections, mergers, or policy changes. This creates a decentralized governance structure for tokenized equity.
contract EquityTokenGovernance is ERC20, Ownable, ReentrancyGuard, Pausable {
    // Governance structures
    struct Proposal {
        string description;
        uint256 voteCount;
        bool executed;
        uint256 startTime;
        uint256 endTime;
    }

    struct Voter {
        bool hasVoted;
        uint256 voteWeight;
    }

    Proposal[] public proposals;
    mapping(address => mapping(uint256 => Voter)) public voters;
    mapping(uint256 => mapping(address => bool)) public voted;

    uint256 public minimumQuorum;
    uint256 public proposalDuration;

    event ProposalCreated(uint256 proposalId, string description);
    event Voted(address indexed voter, uint256 proposalId, uint256 weight);
    event ProposalExecuted(uint256 proposalId);

    modifier onlyTokenHolders() {
        require(balanceOf(msg.sender) > 0, "Only token holders can call this function");
        _;
    }

    constructor(string memory name, string memory symbol, uint256 _minimumQuorum, uint256 _proposalDuration)
        ERC20(name, symbol)
    {
        minimumQuorum = _minimumQuorum;
        proposalDuration = _proposalDuration;
    }

    /// @notice Allows the owner to mint new tokens to a specified address
    /// @param to The address to receive the newly minted tokens
    /// @param amount The amount of tokens to mint
    function mint(address to, uint256 amount) external onlyOwner whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        _mint(to, amount);
    }

    /// @notice Allows the owner to burn tokens from a specified address
    /// @param from The address from which to burn the tokens
    /// @param amount The amount of tokens to burn
    function burn(address from, uint256 amount) external onlyOwner whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        _burn(from, amount);
    }

    /// @notice Creates a new governance proposal
    /// @param description The description of the proposal
    function createProposal(string calldata description) external onlyTokenHolders whenNotPaused {
        proposals.push(
            Proposal({
                description: description,
                voteCount: 0,
                executed: false,
                startTime: block.timestamp,
                endTime: block.timestamp + proposalDuration
            })
        );
        uint256 proposalId = proposals.length - 1;
        emit ProposalCreated(proposalId, description);
    }

    /// @notice Allows token holders to vote on proposals
    /// @param proposalId The ID of the proposal to vote on
    function vote(uint256 proposalId) external onlyTokenHolders whenNotPaused {
        require(proposalId < proposals.length, "Invalid proposal ID");
        require(block.timestamp >= proposals[proposalId].startTime, "Voting period has not started");
        require(block.timestamp <= proposals[proposalId].endTime, "Voting period has ended");
        require(!voted[proposalId][msg.sender], "Already voted");

        uint256 weight = balanceOf(msg.sender);
        proposals[proposalId].voteCount += weight;
        voted[proposalId][msg.sender] = true;

        emit Voted(msg.sender, proposalId, weight);
    }

    /// @notice Executes a proposal if it meets the minimum quorum
    /// @param proposalId The ID of the proposal to execute
    function executeProposal(uint256 proposalId) external onlyOwner whenNotPaused {
        require(proposalId < proposals.length, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.endTime, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");

        if (proposal.voteCount >= minimumQuorum) {
            proposal.executed = true;
            emit ProposalExecuted(proposalId);
            // Implement the actions that should be executed if the proposal passes
        }
    }

    /// @notice Updates the minimum quorum for proposals
    /// @param newQuorum The new minimum quorum
    function updateMinimumQuorum(uint256 newQuorum) external onlyOwner {
        minimumQuorum = newQuorum;
    }

    /// @notice Updates the duration for proposals
    /// @param newDuration The new proposal duration in seconds
    function updateProposalDuration(uint256 newDuration) external onlyOwner {
        proposalDuration = newDuration;
    }

    /// @notice Allows the contract owner to pause all governance operations
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Allows the contract owner to unpause all governance operations
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to withdraw any ETH mistakenly sent to this contract
    function emergencyWithdrawETH() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        payable(owner()).transfer(balance);
    }

    /// @notice Allows the owner to withdraw any ERC20 tokens mistakenly sent to this contract
    /// @param token The address of the ERC20 token
    /// @param amount The amount of tokens to withdraw
    function emergencyWithdrawERC20(address token, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        IERC20(token).transfer(owner(), amount);
    }

    /// @notice Fallback function to accept ETH deposits
    receive() external payable {}

    /// @notice Override ERC20 _beforeTokenTransfer to enforce pausing
    /// @dev This function is called before any transfer of tokens. This includes minting and burning.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
```

### Key Features of the Contract:

1. **Governance Mechanisms**:
   - `createProposal(string description)`: Allows token holders to create a new proposal.
   - `vote(uint256 proposalId)`: Allows token holders to vote on proposals using their token balance as voting weight.
   - `executeProposal(uint256 proposalId)`: Allows the owner to execute proposals that have met the minimum quorum requirement.

2. **Minting and Burning**:
   - `mint(address to, uint256 amount)`: Allows the owner to mint new tokens.
   - `burn(address from, uint256 amount)`: Allows the owner to burn tokens from a specified address.

3. **Pausing**:
   - `pause()`: Pauses all minting, burning, and governance operations.
   - `unpause()`: Unpauses all operations.

4. **Emergency Withdrawals**:
   - `emergencyWithdrawETH()`: Allows the owner to withdraw ETH mistakenly sent to the contract.
   - `emergencyWithdrawERC20(address token, uint256 amount)`: Allows the owner to withdraw ERC20 tokens mistakenly sent to the contract.

5. **Governance Configurations**:
   - `updateMinimumQuorum(uint256 newQuorum)`: Allows the owner to update the minimum quorum for proposals.
   - `updateProposalDuration(uint256 newDuration)`: Allows the owner to update the duration of proposals.

6. **Modifiers and Checks**:
   - `onlyTokenHolders`: Restricts functions to be callable only by token holders.
   - `onlyOwner`: Restricts functions to be callable only by the contract owner.
   - `whenNotPaused`: Restricts functions to be callable only when the contract is not paused.
   - `nonReentrant`: Prevents reentrancy attacks in emergency withdrawal functions.

7. **Fallback Function**:
   - `receive()`: Allows the contract to accept ETH deposits.

8. **Compliance**:
   - Complies with the ERC20 standard using OpenZeppelin's `ERC20` implementation.
   - Utilizes OpenZeppelin’s `Ownable`, `ReentrancyGuard`, and `Pausable` contracts for secure and robust functionality.

### Deployment Instructions:

1. **Install Dependencies**:
   Ensure you have OpenZeppelin installed:
   ```bash
   npm install @openzeppelin/contracts
   ```

2. **Compile the Contract**:
   Compile the contract using Hardhat or Truffle:
   ```bash
   npx hardhat compile
   ```

3. **Deploy the Contract**:
   Example Hardhat deployment script:
   ```javascript
   const { ethers } = require("hardhat");

   async function main() {
     const [deployer] = await ethers.getSigners();

     console.log("Deploying contracts with the account:", deployer.address);
     console.log("Account balance:", (await deployer.getBalance()).toString());

     const EquityTokenGovernance = await ethers.getContractFactory("EquityTokenGovernance");
     const token = await EquityTokenGovernance.deploy("Equity Governance Token", "EGT", 1000, 604800);
     await token.deployed();

     console.log("Equity Token Governance Contract deployed to:", token.address);
   }

   main()
     .then(() => process.exit(0))
     .catch((error) => {
       console.error(error);
       process.exit(1);
     });
   ```

4.

 **Run the Deployment Script**:
   Deploy the contract using Hardhat:
   ```bash
   npx hardhat run scripts/deploy.js --network <network>
   ```

5. **Testing and Auditing**:
   - Write test cases to ensure that the governance functionalities work as expected, and that only the owner can mint and burn tokens.
   - Conduct thorough testing for edge cases such as double voting, and unauthorized minting.
   - Consider getting the contract audited to ensure it meets security and compliance standards.

6. **Future Enhancements**:
   - Implement quadratic voting for governance decisions.
   - Integrate with oracles for dynamic proposal validation.
   - Add multi-signature capabilities for higher security on executing proposals.

This contract provides a comprehensive governance framework for companies to allow their equity token holders to participate in corporate decisions, ensuring decentralized and transparent decision-making.