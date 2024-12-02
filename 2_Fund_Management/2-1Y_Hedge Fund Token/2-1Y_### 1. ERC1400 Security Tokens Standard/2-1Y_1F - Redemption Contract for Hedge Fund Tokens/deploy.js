const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const tokenAddress = "YOUR_ERC1400_TOKEN_ADDRESS"; // Replace with your ERC1400 token contract address
  const RedemptionContract = await hre.ethers.getContractFactory("RedemptionContract");
  const redemptionContract = await RedemptionContract.deploy(tokenAddress);

  await redemptionContract.deployed();
  console.log("Redemption Contract deployed to:", redemptionContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
