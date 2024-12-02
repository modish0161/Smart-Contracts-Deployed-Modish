async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const AnonymousAtomicSwap = await ethers.getContractFactory("AnonymousAtomicSwap");
    const anonymousAtomicSwap = await AnonymousAtomicSwap.deploy();
  
    console.log("AnonymousAtomicSwap deployed to:", anonymousAtomicSwap.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  