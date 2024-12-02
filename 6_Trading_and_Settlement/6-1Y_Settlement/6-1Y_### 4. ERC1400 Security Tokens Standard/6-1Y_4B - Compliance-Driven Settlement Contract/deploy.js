async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const SecurityTokenAddress = "0xYourSecurityTokenAddress"; // Replace with your ERC1400 token address
  
    const ComplianceDrivenSettlement = await ethers.getContractFactory("ComplianceDrivenSettlement");
    const complianceDrivenSettlement = await ComplianceDrivenSettlement.deploy(SecurityTokenAddress);
  
    console.log("ComplianceDrivenSettlement deployed to:", complianceDrivenSettlement.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  