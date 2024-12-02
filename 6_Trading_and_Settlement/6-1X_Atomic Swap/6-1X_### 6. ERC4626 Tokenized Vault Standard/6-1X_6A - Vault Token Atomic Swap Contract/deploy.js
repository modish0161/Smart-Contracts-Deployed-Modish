async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const VaultTokenAtomicSwap = await ethers.getContractFactory("VaultTokenAtomicSwap");
    const vaultTokenAtomicSwap = await VaultTokenAtomicSwap.deploy();
  
    console.log("VaultTokenAtomicSwap deployed to:", vaultTokenAtomicSwap.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  