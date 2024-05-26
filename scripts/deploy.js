async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const TrainCrossing = await ethers.getContractFactory("TrainCrossing");
    const trainCrossing = await TrainCrossing.deploy(600, 3, 60); // Example parameters

    console.log("TrainCrossing deployed to:", trainCrossing.address);
}

main()
   .then(() => process.exit(0))
   .catch((error) => {
       console.error(error);
       process.exit(1);
   });
