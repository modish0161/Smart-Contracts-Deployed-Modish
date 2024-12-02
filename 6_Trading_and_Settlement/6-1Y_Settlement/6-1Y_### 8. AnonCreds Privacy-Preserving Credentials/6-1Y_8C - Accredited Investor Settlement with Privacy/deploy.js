async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const AccreditedInvestorPrivacySettlement = await ethers.getContractFactory("AccreditedInvestorPrivacySettlement");
    const accreditedInvestorPrivacySettlement = await AccreditedInvestorPrivacySettlement.deploy();
  
    console.log("AccreditedInvestorPrivacySettlement deployed to:", accreditedInvestorPrivacySettlement.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  