// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const securityToken = "0xYourERC1400TokenAddress"; // Replace with actual ERC1400 token address
    const dividendToken = "0xYourERC20TokenAddress"; // Replace with actual ERC20 token address
    const taxWithholdingContract = "0xYourTaxWithholdingContractAddress"; // Replace with actual tax withholding contract address
    const complianceContract = "0xYourComplianceContractAddress"; // Replace with actual compliance contract address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const DividendWithholdingAndReporting = await ethers.getContractFactory("DividendWithholdingAndReporting");
    const contract = await DividendWithholdingAndReporting.deploy(
      securityToken,
      dividendToken,
      taxWithholdingContract,
      complianceContract
    );
  
    console.log("DividendWithholdingAndReporting deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  