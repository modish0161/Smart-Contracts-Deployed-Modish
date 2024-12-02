const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const tokenAddress = "YOUR_ERC1400_TOKEN_ADDRESS"; // Replace with your ERC1400 token contract address
  const WhitelistingBlacklistingContract = await hre.ethers.getContractFactory("WhitelistingBlacklistingContract");
  const whitelistingContract = await WhitelistingBlacklistingContract.deploy(tokenAddress);

  await whitelistingContract.deployed();
  console.log("Whitelisting/Blacklisting Contract deployed to:", whitelistingContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
