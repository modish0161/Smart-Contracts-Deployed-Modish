// scripts/deploy.js

async function main() {
    // Get the contract factory
    const PrivacyPreservingVotingContract = await ethers.getContractFactory("PrivacyPreservingVotingContract");
  
    // Replace this with the deployed AnonCreds verifier contract address
    const anonCredsVerifierAddress = "0xYourAnonCredsVerifierAddressHere";
  
    // Deploy the contract with the AnonCreds verifier address
    const privacyPreservingVoting = await PrivacyPreservingVotingContract.deploy(anonCredsVerifierAddress);
  
    await privacyPreservingVoting.deployed();
  
    console.log("PrivacyPreservingVotingContract deployed to:", privacyPreservingVoting.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  