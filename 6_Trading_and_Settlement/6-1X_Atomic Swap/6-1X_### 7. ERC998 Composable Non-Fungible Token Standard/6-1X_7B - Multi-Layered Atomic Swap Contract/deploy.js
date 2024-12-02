async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const MultiLayeredAtomicSwap = await ethers.getContractFactory("MultiLayeredAtomicSwap");
    const multiLayeredAtomicSwap = await MultiLayeredAtomicSwap.deploy();
  
    console.log("MultiLayeredAtomicSwap deployed to:", multiLayeredAtomicSwap.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  