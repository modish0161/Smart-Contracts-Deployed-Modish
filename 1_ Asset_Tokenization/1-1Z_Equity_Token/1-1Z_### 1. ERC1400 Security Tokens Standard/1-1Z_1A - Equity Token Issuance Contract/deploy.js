const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const EquityToken = await ethers.getContractFactory("EquityToken");
  const equityToken = await EquityToken.deploy();
  await equityToken.deployed();

  console.log("Equity Token deployed to:", equityToken.address);

  const EquityTokenIssuance = await ethers.getContractFactory("EquityTokenIssuance");
  const equityTokenIssuance = await EquityTokenIssuance.deploy(
    equityToken.address, // Address of the equity token contract
    ethers.utils.parseEther("0.1"), // Minimum investment in wei
    ethers.utils.parseEther("10"), // Maximum investment in wei
    ethers.utils.parseEther("1000"), // Total tokens for sale
    ethers.utils.parseEther("0.01") // Token price in wei
  );
  await equityTokenIssuance.deployed();

  console.log("Equity Token Issuance Contract deployed to:", equityTokenIssuance.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
