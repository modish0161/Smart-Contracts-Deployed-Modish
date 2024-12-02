// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const restrictedToken = "0xYourERC1404TokenAddress"; // Replace with actual ERC1404 token address
    const dividendToken = "0xYourERC20TokenAddress"; // Replace with actual ERC20 token address
    const accreditationComplianceContract = "0xYourAccreditationComplianceContractAddress"; // Replace with actual accreditation compliance contract address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const AccreditedInvestorDividendDistribution = await ethers.getContractFactory("AccreditedInvestorDividendDistribution");
    const contract = await AccreditedInvestorDividendDistribution.deploy(
      restrictedToken,
      dividendToken,
      accreditationComplianceContract
    );
  
    console.log("AccreditedInvestorDividendDistribution deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  