// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const investmentTokenAddress = "0x123..."; // Replace with actual token address
    const dividendTokenAddress = "0xabc..."; // Replace with actual token address
    const profitThreshold = ethers.utils.parseEther("10"); // 10 tokens threshold
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const ProfitDrivenReinvestmentContract = await ethers.getContractFactory("ProfitDrivenReinvestmentContract");
    const contract = await ProfitDrivenReinvestmentContract.deploy(investmentTokenAddress, dividendTokenAddress, profitThreshold);
  
    console.log("ProfitDrivenReinvestmentContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  