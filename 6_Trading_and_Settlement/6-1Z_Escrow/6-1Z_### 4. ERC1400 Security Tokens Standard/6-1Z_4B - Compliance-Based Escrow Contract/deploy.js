async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const securityTokenAddress = "0xYourSecurityTokenAddress"; // Replace with actual ERC1400 token contract address
  
    const ComplianceBasedEscrow = await ethers.getContractFactory("ComplianceBasedEscrow");
    const escrow = await ComplianceBasedEscrow.deploy(securityTokenAddress);
    console.log("ComplianceBasedEscrow contract deployed to:", escrow.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  