const hre = require("hardhat");

async function main() {
  const SecurityTokenAddress = "0x..."; // Replace with your deployed ERC1400 token address
  const DividendDistributionETF = await hre.ethers.getContractFactory("DividendDistributionETF");
  const dividendDistributionContract = await DividendDistributionETF.deploy(SecurityTokenAddress);
  await dividendDistributionContract.deployed();
  console.log("Dividend Distribution Contract deployed to:", dividendDistributionContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
