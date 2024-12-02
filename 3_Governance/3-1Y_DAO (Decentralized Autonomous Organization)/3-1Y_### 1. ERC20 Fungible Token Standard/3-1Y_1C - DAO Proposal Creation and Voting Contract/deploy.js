// scripts/deploy.js

async function main() {
    // Get the contract factory
    const DAOProposalVotingContract = await ethers.getContractFactory("DAOProposalVotingContract");
  
    // Replace this with your deployed ERC20 governance token contract address
    const governanceTokenAddress = "0xYourERC20TokenAddressHere";
    const proposalFee = ethers.utils.parseEther("1"); // 1 ETH proposal fee
    const feeRecipient = "0xYourFeeRecipientAddressHere";
  
    // Deploy the contract with the governance token address, proposal fee, and fee recipient
    const daoProposalVoting = await DAOProposalVotingContract.deploy(governanceTokenAddress, proposalFee, feeRecipient);
  
    await daoProposalVoting.deployed();
  
    console.log("DAOProposalVotingContract deployed to:", daoProposalVoting.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  