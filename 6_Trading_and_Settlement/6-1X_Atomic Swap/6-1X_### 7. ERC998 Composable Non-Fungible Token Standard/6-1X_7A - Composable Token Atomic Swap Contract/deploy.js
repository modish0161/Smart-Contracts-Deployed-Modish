async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const ComposableTokenAtomicSwap = await ethers.getContractFactory("ComposableTokenAtomicSwap");
    const composableTokenAtomicSwap = await ComposableTokenAtomicSwap.deploy();
  
    console.log("ComposableTokenAtomicSwap deployed to:", composableTokenAtomicSwap.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  