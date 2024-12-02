// scripts/deploy.js

async function main() {
    // Get the contract factory
    const DAOTreasuryManagementContract = await ethers.getContractFactory("DAOTreasuryManagementContract");
  
    // Replace this with your deployed ERC20 governance token contract address
    const governanceTokenAddress = "0xYourERC20TokenAddressHere";
  
    // Deploy the contract with the governance token address
    const daoTreasury = await DAOTreasuryManagementContract.deploy(governanceTokenAddress);
  
    await daoTreasury.deployed();
  
    console.log("DAOTreasuryManagementContract deployed to:", daoTreasury.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  