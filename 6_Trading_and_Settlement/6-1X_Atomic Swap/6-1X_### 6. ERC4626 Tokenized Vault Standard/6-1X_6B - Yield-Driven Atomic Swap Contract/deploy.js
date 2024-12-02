async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const YieldDrivenAtomicSwap = await ethers.getContractFactory("YieldDrivenAtomicSwap");
    const yieldDrivenAtomicSwap = await YieldDrivenAtomicSwap.deploy();
  
    console.log("YieldDrivenAtomicSwap deployed to:", yieldDrivenAtomicSwap.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  