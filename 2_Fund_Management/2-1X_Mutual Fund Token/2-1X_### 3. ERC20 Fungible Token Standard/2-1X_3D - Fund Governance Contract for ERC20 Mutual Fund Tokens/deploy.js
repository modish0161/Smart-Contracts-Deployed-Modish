const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const FundGovernance = await hre.ethers.getContractFactory("FundGovernance");
  const fundGovernance = await FundGovernance.deploy(
    "Mutual Fund Token", // Token name
    "MFT",               // Token symbol
    1000000 * 10 ** 18,  // Initial supply (1 million tokens)
    1,                   // Voting delay (1 block)
    45818,               // Voting period (~1 week in blocks)
    10000 * 10 ** 18,    // Proposal threshold (10,000 tokens)
    4                    // Quorum percentage (4%)
  );

  await fundGovernance.deployed();
  console.log("Fund Governance Token deployed to:", fundGovernance.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
