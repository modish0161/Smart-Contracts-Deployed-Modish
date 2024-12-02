async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const VaultTokenAddress = "0xYourVaultTokenAddress"; // Replace with your ERC4626 token address
  
    const YieldDrivenSettlement = await ethers.getContractFactory("YieldDrivenSettlement");
    const yieldDrivenSettlement = await YieldDrivenSettlement.deploy(VaultTokenAddress);
  
    console.log("YieldDrivenSettlement deployed to:", yieldDrivenSettlement.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  