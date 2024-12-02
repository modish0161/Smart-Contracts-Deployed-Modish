// scripts/deploy.js

async function main() {
    // Get the contract factory
    const AccreditedVotingContractWithAnonCreds = await ethers.getContractFactory("AccreditedVotingContractWithAnonCreds");
  
    // Replace this with the deployed AnonCreds verifier contract address
    const anonCredsVerifierAddress = "0xYourAnonCredsVerifierAddressHere";
  
    // Deploy the contract with the AnonCreds verifier address
    const accreditedVoting = await AccreditedVotingContractWithAnonCreds.deploy(anonCredsVerifierAddress);
  
    await accreditedVoting.deployed();
  
    console.log("AccreditedVotingContractWithAnonCreds deployed to:", accreditedVoting.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  