// scripts/deploy.js

async function main() {
    // Get the contract factory
    const DAOFundAllocation = await ethers.getContractFactory("DAOFundAllocation");
  
    // Replace these with your desired initial parameters
    const defaultOperators = ["0xYourOperatorAddressHere"];
    const name = "DAO Fund Allocation Token";
    const symbol = "DFAT";
  
    // Deploy the contract with default operators, name, and symbol
    const daoFundAllocation = await DAOFundAllocation.deploy(defaultOperators, name, symbol);
  
    await daoFundAllocation.deployed();
  
    console.log("DAOFundAllocation deployed to:", daoFundAllocation.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  