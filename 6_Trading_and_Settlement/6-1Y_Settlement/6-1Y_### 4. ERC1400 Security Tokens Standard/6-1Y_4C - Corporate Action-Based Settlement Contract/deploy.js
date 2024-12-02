async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const SecurityTokenAddress = "0xYourSecurityTokenAddress"; // Replace with your ERC1400 token address
  
    const CorporateActionSettlement = await ethers.getContractFactory("CorporateActionSettlement");
    const corporateActionSettlement = await CorporateActionSettlement.deploy(SecurityTokenAddress);
  
    console.log("CorporateActionSettlement deployed to:", corporateActionSettlement.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  