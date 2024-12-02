// scripts/deploy.js

async function main() {
    // Get the contract factory
    const DelegatedVotingDAO = await ethers.getContractFactory("DelegatedVotingDAO");
  
    // Replace these with your desired initial parameters
    const defaultOperators = ["0xYourOperatorAddressHere"];
    const name = "Delegated Voting Token";
    const symbol = "DVT";
  
    // Deploy the contract with default operators, name, and symbol
    const delegatedVotingDAO = await DelegatedVotingDAO.deploy(defaultOperators, name, symbol);
  
    await delegatedVotingDAO.deployed();
  
    console.log("DelegatedVotingDAO deployed to:", delegatedVotingDAO.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  