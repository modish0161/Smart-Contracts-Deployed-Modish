async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const PrivacyPreservingSettlement = await ethers.getContractFactory("PrivacyPreservingSettlement");
    const privacyPreservingSettlement = await PrivacyPreservingSettlement.deploy();
  
    console.log("PrivacyPreservingSettlement deployed to:", privacyPreservingSettlement.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  