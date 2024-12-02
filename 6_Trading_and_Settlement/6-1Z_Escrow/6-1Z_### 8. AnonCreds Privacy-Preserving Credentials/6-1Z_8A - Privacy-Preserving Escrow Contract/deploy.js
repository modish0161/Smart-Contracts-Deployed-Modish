async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const PrivacyPreservingEscrowContract = await ethers.getContractFactory("PrivacyPreservingEscrowContract");
    const contract = await PrivacyPreservingEscrowContract.deploy();
  
    console.log("PrivacyPreservingEscrowContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  