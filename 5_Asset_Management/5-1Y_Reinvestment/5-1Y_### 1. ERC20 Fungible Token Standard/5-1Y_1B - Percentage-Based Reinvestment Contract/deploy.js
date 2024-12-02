// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const investmentTokenAddress = "0x123..."; // Replace with actual token address
    const dividendTokenAddress = "0xabc..."; // Replace with actual token address
    const minimumReinvestmentPercentage = 5000; // 50% minimum reinvestment
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const PercentageBasedReinvestmentContract = await ethers.getContractFactory("PercentageBasedReinvestmentContract");
    const contract = await PercentageBasedReinvestmentContract.deploy(investmentTokenAddress, dividendTokenAddress, minimumReinvestmentPercentage);
  
    console.log("PercentageBasedReinvestmentContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  