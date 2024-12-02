async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const securityTokenAddress = "0xYourSecurityTokenAddress"; // Replace with actual ERC1400 token contract address
  
    const SecurityTokenEscrow = await ethers.getContractFactory("SecurityTokenEscrow");
    const escrow = await SecurityTokenEscrow.deploy(securityTokenAddress);
    console.log("SecurityTokenEscrow contract deployed to:", escrow.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  