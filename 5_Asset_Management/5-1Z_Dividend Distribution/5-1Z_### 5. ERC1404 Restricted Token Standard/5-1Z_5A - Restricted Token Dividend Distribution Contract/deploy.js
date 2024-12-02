// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const restrictedToken = "0xYourERC1404TokenAddress"; // Replace with actual ERC1404 token address
    const dividendToken = "0xYourERC20TokenAddress"; // Replace with actual ERC20 token address
    const kycComplianceContract = "0xYourKYCComplianceContractAddress"; // Replace with actual KYC compliance contract address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const RestrictedTokenDividendDistribution = await ethers.getContractFactory("RestrictedTokenDividendDistribution");
    const contract = await RestrictedTokenDividendDistribution.deploy(
      restrictedToken,
      dividendToken,
      kycComplianceContract
    );
  
    console.log("RestrictedTokenDividendDistribution deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  