// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const vaultToken = "0xYourERC4626VaultTokenAddress"; // Replace with actual ERC4626 tokenized vault address
    const dividendToken = "0xYourERC20TokenAddress"; // Replace with actual ERC20 token address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const VaultDividendDistribution = await ethers.getContractFactory("VaultDividendDistribution");
    const contract = await VaultDividendDistribution.deploy(
      vaultToken,
      dividendToken
    );
  
    console.log("VaultDividendDistribution deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  