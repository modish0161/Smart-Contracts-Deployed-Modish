// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const vaultToken = "0xYourERC4626VaultTokenAddress"; // Replace with actual ERC4626 vault token address
    const yieldToken = "0xYourERC20TokenAddress"; // Replace with actual ERC20 yield token address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const YieldDrivenDividendDistribution = await ethers.getContractFactory("YieldDrivenDividendDistribution");
    const contract = await YieldDrivenDividendDistribution.deploy(
      vaultToken,
      yieldToken
    );
  
    console.log("YieldDrivenDividendDistribution deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  