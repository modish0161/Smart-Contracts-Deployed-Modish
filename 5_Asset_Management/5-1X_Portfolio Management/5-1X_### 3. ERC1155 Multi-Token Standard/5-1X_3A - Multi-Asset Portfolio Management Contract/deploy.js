// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const uri = "https://api.example.com/metadata/{id}"; // Replace with actual URI
  
    const MultiAssetPortfolioManagement = await ethers.getContractFactory("MultiAssetPortfolioManagement");
    const contract = await MultiAssetPortfolioManagement.deploy(uri);
  
    console.log("MultiAssetPortfolioManagement deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  