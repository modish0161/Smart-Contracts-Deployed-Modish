// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const TokenizedVaultPortfolioManagement = await ethers.getContractFactory("TokenizedVaultPortfolioManagement");
    const contract = await TokenizedVaultPortfolioManagement.deploy("0xAssetTokenAddress");
  
    console.log("TokenizedVaultPortfolioManagement deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  