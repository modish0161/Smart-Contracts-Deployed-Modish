const hre = require("hardhat");

async function main() {
  const initialSupply = 1000000; // Set initial supply as needed
  const InvestorAccreditation = await hre.ethers.getContractFactory("InvestorAccreditation");
  const investorAccreditation = await InvestorAccreditation.deploy(initialSupply);
  await investorAccreditation.deployed();
  console.log("Investor Accreditation Contract deployed to:", investorAccreditation.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
