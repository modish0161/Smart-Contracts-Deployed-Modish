async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const Escrow = await ethers.getContractFactory("AccreditedInvestorPrivacyEscrow");
    const escrow = await Escrow.deploy();
    console.log("Contract deployed to:", escrow.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  