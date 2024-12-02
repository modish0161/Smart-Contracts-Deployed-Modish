const hre = require("hardhat");

async function main() {
  const SecurityTokenAddress = "0x..."; // Replace with your deployed ERC1400 token address
  const WhitelistingBlacklistingETF = await hre.ethers.getContractFactory("WhitelistingBlacklistingETF");
  const whitelistingBlacklistingContract = await WhitelistingBlacklistingETF.deploy(SecurityTokenAddress);
  await whitelistingBlacklistingContract.deployed();
  console.log("Whitelisting/Blacklisting Contract deployed to:", whitelistingBlacklistingContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
