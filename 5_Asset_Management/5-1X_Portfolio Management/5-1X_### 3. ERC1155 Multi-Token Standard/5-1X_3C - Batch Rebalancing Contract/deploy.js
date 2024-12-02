// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const uri = "https://api.example.com/metadata/{id}"; // Replace with actual URI
  
    const BatchRebalancingMixedPortfolios = await ethers.getContractFactory("BatchRebalancingMixedPortfolios");
    const contract = await BatchRebalancingMixedPortfolios.deploy(uri);
  
    console.log("BatchRebalancingMixedPortfolios deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  