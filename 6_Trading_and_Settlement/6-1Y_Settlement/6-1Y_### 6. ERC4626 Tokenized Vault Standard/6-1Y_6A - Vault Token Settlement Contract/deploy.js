async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    const VaultTokenAddress = "0xYourVaultTokenAddress"; // Replace with your ERC4626 token address
  
    const VaultTokenSettlement = await ethers.getContractFactory("VaultTokenSettlement");
    const vaultTokenSettlement = await VaultTokenSettlement.deploy(VaultTokenAddress);
  
    console.log("VaultTokenSettlement deployed to:", vaultTokenSettlement.address);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  