const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ComposableAssetVotingContract", function () {
  let ComposableAssetVotingContract;
  let composableAssetVoting;
  let ERC998Mock;
  let erc998Token;
  let owner;
  let voter1;
  let voter2;
  let voter3;

  beforeEach(async function () {
    [owner, voter1, voter2, voter3] = await ethers.getSigners();

    // Deploy a mock ERC998 contract for testing purposes
    ERC998Mock = await ethers.getContractFactory("ERC998ERC721TopDown");
    erc998Token = await ERC998Mock.deploy("MockComposableToken", "MCT");
    await erc998Token.deployed();

    // Mint some composable tokens to voters
    await erc998Token.mint(voter1.address, 1);
    await erc998Token.mint(voter2.address, 2);
    await erc998Token.mint(voter3.address, 3);

    // Deploy the ComposableAssetVotingContract
    ComposableAssetVotingContract = await ethers.getContractFactory("ComposableAssetVotingContract");
    composableAssetVoting = await ComposableAssetVotingContract.deploy(erc998Token.address);
    await composableAssetVoting.deployed();
  });

  it("Should add voters to the whitelist", async function () {
    await composableAssetVoting.addWhitelist(voter1.address);
    await composableAssetVoting.addWhitelist(voter2.address);
    expect(await composableAssetVoting.isWhitelisted(voter1.address)).to.be.true;
    expect(await composableAssetVoting.isWhitelisted(voter2.address)).to.be.true;
  });

  it("Should create a proposal", async function () {
    await composableAssetVoting.addWhitelist(voter1.address);
    await composableAssetVoting.addWhitelist(voter2.address);
    await composableAssetVoting.createProposal(
      "Proposal 1",
      "This is a test proposal",
      50, // Quorum
      50, // Approval percentage
      [erc998Token.address], // Affected assets
      [ethers.utils.defaultAbiCoder.encode(["uint256"], [1])] // Execution data
    );

    const proposal = await composableAssetVoting.getProposal(0);
    expect(proposal.title).to.equal("Proposal 1");
  });

  it("Should allow whitelisted voters to vote", async function () {
    await composableAssetVoting.addWhitelist(voter1.address);
    await composableAssetVoting.addWhitelist(voter2.address);

    await composableAssetVoting.createProposal(
      "Proposal 1",
      "This is a test proposal",
      50,
      50,
      [erc998Token.address],
      [ethers.utils.defaultAbiCoder.encode(["uint256"], [1])]
    );

    await composableAssetVoting.connect(voter1).vote(0, 1); // Vote Yes
    await composableAssetVoting.connect(voter2).vote(0, 2); // Vote No

    const proposal = await composableAssetVoting.getProposal(0);
    expect(proposal.yesVotes).to.equal(1);
    expect(proposal.noVotes).to.equal(1);
  });

  it("Should execute a proposal when quorum and approval are met", async function () {
    await composableAssetVoting.addWhitelist(voter1.address);
    await composableAssetVoting.addWhitelist(voter2.address);
    await composableAssetVoting.addWhitelist(voter3.address);

    await composableAssetVoting.createProposal(
      "Proposal 1",
      "This is a test proposal",
      50,
      50,
      [erc998Token.address],
      [ethers.utils.defaultAbiCoder.encode(["uint256"], [1])]
    );

    await composableAssetVoting.connect(voter1).vote(0, 1); // Vote Yes
    await composableAssetVoting.connect(voter2).vote(0, 1); // Vote Yes

    // Wait for the voting period to end (7 days) in test scenario, we simulate time passing
    await ethers.provider.send("evm_increaseTime", [7 * 24 * 60 * 60]); // Increase time by 7 days
    await ethers.provider.send("evm_mine", []); // Mine the next block

    await composableAssetVoting.executeProposal(0);

    const proposal = await composableAssetVoting.getProposal(0);
    expect(proposal.executed).to.be.true;
  });

  it("Should not allow non-whitelisted addresses to vote", async function () {
    await composableAssetVoting.addWhitelist(voter1.address);
    await composableAssetVoting.createProposal(
      "Proposal 1",
      "This is a test proposal",
      50,
      50,
      [erc998Token.address],
      [ethers.utils.defaultAbiCoder.encode(["uint256"], [1])]
    );

    await expect(composableAssetVoting.connect(voter2).vote(0, 1)).to.be.revertedWith("You are not authorized to vote");
  });
});
