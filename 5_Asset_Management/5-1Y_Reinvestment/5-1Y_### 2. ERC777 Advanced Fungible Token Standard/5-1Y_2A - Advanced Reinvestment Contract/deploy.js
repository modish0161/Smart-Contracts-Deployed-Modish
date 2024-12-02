// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const dividendTokenAddress = "0x123..."; // Replace with actual dividend token address
    const investmentTokenAddress = "0xabc..."; // Replace with actual investment token address
    const profitThreshold = ethers.utils.parseEther("10"); // 10 tokens threshold
    const reinvestmentOperator = "0xdef..."; // Replace with actual operator address
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const AdvancedReinvestmentContract = await ethers.getContractFactory("AdvancedReinvestmentContract");
    const contract = await AdvancedReinvestmentContract.deploy(dividendTokenAddress, investmentTokenAddress, profitThreshold, reinvestmentOperator);
  
    console.log("AdvancedReinvestmentContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  