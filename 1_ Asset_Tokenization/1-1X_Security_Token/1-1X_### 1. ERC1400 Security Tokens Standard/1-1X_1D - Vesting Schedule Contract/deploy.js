async function main() {
    const VestingScheduleContract = await ethers.getContractFactory("VestingScheduleContract");
    const vestingScheduleContract = await VestingScheduleContract.deploy("Vesting Security Token", "VST", 18, 1000000);
    await vestingScheduleContract.deployed();
    console.log("VestingScheduleContract deployed to:", vestingScheduleContract.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
