async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const composableTokenAddress = "0xYourComposableTokenAddress"; // Replace with actual ERC998 composable token contract address
  
    const ComposableTokenEscrowContract = await ethers.getContractFactory("ComposableTokenEscrowContract");
    const escrow = await ComposableTokenEscrowContract.deploy(composableTokenAddress);
    console.log("ComposableTokenEscrowContract deployed to:", escrow.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  