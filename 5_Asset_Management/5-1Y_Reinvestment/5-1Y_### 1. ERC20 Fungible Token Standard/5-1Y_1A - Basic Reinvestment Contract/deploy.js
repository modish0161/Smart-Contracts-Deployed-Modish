// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    const investmentTokenAddress = "0x123..."; // Replace with actual token address
    const dividendTokenAddress = "0xabc..."; // Replace with actual token address
    const minimumReinvestmentAmount = ethers.utils.parseEther("10"); // Replace with desired amount
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const BasicReinvestmentContract = await ethers.getContractFactory("BasicReinvestmentContract");
    const contract = await BasicReinvestmentContract.deploy(investmentTokenAddress, dividendTokenAddress, minimumReinvestmentAmount);
  
    console.log("BasicReinvestmentContract deployed to:", contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  