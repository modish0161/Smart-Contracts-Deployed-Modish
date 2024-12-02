// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const uri = "https://api.example.com/metadata/{id}"; // Replace with actual URI
  
    const DynamicRebalancingMixedPortfolios = await ethers.getContractFactory("DynamicRebalancingMixedPortfolios");
    const contract = await DynamicRebalancingMixedPortfolios.deploy(uri);
  
    console.log("DynamicRebalancingMixedPortfolios deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  