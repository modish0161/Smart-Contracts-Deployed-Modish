// scripts/deploy.js

async function main() {
    // Get the contract factory
    const BasicDAOGovernanceContract = await ethers.getContractFactory("BasicDAOGovernanceContract");
  
    // Replace this with your deployed ERC20 governance token contract address
    const governanceTokenAddress = "0xYourERC20TokenAddressHere";
  
    // Deploy the contract with the governance token address
    const daoGovernance = await BasicDAOGovernanceContract.deploy(governanceTokenAddress);
  
    await daoGovernance.deployed();
  
    console.log("BasicDAOGovernanceContract deployed to:", daoGovernance.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  