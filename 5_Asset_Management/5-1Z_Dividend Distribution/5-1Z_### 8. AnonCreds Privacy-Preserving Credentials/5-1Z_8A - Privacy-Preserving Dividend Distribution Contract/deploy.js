// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const dividendToken = "0xYourERC20TokenAddress"; // Replace with actual ERC20 dividend token address
    const anonCreds = "0xYourAnonCredsContractAddress"; // Replace with actual AnonCreds contract address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const PrivacyPreservingDividendDistribution = await ethers.getContractFactory("PrivacyPreservingDividendDistribution");
    const contract = await PrivacyPreservingDividendDistribution.deploy(
      dividendToken,
      anonCreds
    );
  
    console.log("PrivacyPreservingDividendDistribution deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  