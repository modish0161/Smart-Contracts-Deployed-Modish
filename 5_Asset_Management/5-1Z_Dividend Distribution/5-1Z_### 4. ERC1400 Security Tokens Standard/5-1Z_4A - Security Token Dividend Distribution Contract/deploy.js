// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const securityToken = "0xYourERC1400TokenAddress"; // Replace with actual ERC1400 token address
    const dividendToken = "0xYourERC20TokenAddress"; // Replace with actual ERC20 token address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const SecurityTokenDividendDistribution = await ethers.getContractFactory("SecurityTokenDividendDistribution");
    const contract = await SecurityTokenDividendDistribution.deploy(securityToken, dividendToken);
  
    console.log("SecurityTokenDividendDistribution deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  