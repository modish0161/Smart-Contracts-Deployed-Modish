async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const AnonymousEscrowContract = await ethers.getContractFactory("AnonymousEscrowContract");
    const contract = await AnonymousEscrowContract.deploy();
  
    console.log("Contract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  