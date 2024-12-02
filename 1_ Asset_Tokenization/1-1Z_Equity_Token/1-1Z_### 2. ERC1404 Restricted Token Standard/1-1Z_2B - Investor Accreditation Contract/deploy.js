const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const InvestorAccreditationContract = await ethers.getContractFactory("InvestorAccreditationContract");
  const equityToken = await InvestorAccreditationContract.deploy("Accredited Equity Token", "AET", ethers.utils.parseEther("1000000"));
  await equityToken.deployed();

  console.log("Investor Accreditation Contract deployed to:", equityToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
