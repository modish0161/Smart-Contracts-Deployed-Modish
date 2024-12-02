async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const SecurityTokenAddress = "0xYourSecurityTokenAddress"; // Replace with your ERC1400 token address
  
    const SecurityTokenSettlement = await ethers.getContractFactory("SecurityTokenSettlement");
    const securityTokenSettlement = await SecurityTokenSettlement.deploy(SecurityTokenAddress);
  
    console.log("SecurityTokenSettlement deployed to:", securityTokenSettlement.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  