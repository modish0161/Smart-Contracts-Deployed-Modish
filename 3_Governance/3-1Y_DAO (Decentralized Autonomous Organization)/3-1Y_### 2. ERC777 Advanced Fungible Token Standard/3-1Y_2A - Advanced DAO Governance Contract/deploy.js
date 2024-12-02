// scripts/deploy.js

async function main() {
    // Get the contract factory
    const AdvancedDAOGovernance = await ethers.getContractFactory("AdvancedDAOGovernance");
  
    // Replace these with your desired initial parameters
    const defaultOperators = ["0xYourOperatorAddressHere"];
    const name = "Advanced DAO Token";
    const symbol = "ADT";
  
    // Deploy the contract with default operators, name, and symbol
    const advancedDAOGovernance = await AdvancedDAOGovernance.deploy(defaultOperators, name, symbol);
  
    await advancedDAOGovernance.deployed();
  
    console.log("AdvancedDAOGovernance deployed to:", advancedDAOGovernance.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  