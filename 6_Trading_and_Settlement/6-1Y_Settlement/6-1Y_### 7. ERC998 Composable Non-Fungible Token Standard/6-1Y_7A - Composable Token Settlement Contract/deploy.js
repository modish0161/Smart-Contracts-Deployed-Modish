async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const ComposableTokenSettlement = await ethers.getContractFactory("ComposableTokenSettlement");
    const composableTokenSettlement = await ComposableTokenSettlement.deploy("Composable Token Settlement", "CTS");
  
    console.log("ComposableTokenSettlement deployed to:", composableTokenSettlement.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  