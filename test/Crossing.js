const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TrainCrossing", function () {
    let TrainCrossing, trainCrossing, owner, addr1, addr2, addr3;

    beforeEach(async function () {
        TrainCrossing = await ethers.getContractFactory("TrainCrossing");
        [owner, addr1, addr2, addr3] = await ethers.getSigners();
        trainCrossing = await TrainCrossing.deploy(600, 5, 300);
        await trainCrossing.deployed();
    });

    it("Should set the right owner", async function () {
        expect(await trainCrossing.infrastructure()).to.equal(owner.address);
    });

    it("Should authorize a train and allow it to request crossing", async function () {
        await trainCrossing.authorizeTrain(addr1.address);
        expect(await trainCrossing.authorizedTrains(addr1.address)).to.equal(true);

        await expect(trainCrossing.connect(addr1).requestTrainCrossing())
            .to.emit(trainCrossing, "TrainCrossingRequest")
            .withArgs(addr1.address, true);
    });

    it("Should not allow unauthorized train to request crossing", async function () {
        await expect(trainCrossing.connect(addr1).requestTrainCrossing())
            .to.be.revertedWith("Not authorized train.");
    });

    it("Should allow a car to request and release crossing permission", async function () {
        await trainCrossing.updateFreeToCrossState();
        await expect(trainCrossing.connect(addr1).requestCarPermission())
            .to.emit(trainCrossing, "CarCrossingPermissionGranted")
            .withArgs(addr1.address);

        await expect(trainCrossing.connect(addr1).releaseCarPermission())
            .to.emit(trainCrossing, "CarCrossingPermissionReleased")
            .withArgs(addr1.address);
    });

    it("Should not allow a car to request crossing when it's full", async function () {
        await trainCrossing.updateFreeToCrossState();
        for (let i = 0; i < 5; i++) {
            await trainCrossing.connect(addr1).requestCarPermission();
        }
        await expect(trainCrossing.connect(addr2).requestCarPermission())
            .to.be.revertedWith("Crossing is full.");
    });

    it("Should allow authorized train to release crossing", async function () {
        await trainCrossing.authorizeTrain(addr1.address);
        await trainCrossing.connect(addr1).requestTrainCrossing();
        await expect(trainCrossing.connect(addr1).releaseTrainCrossing())
            .to.emit(trainCrossing, "TrainCrossingPermissionReleased")
            .withArgs(addr1.address);
    });

    it("Should update crossing state to free to cross", async function () {
        await trainCrossing.updateFreeToCrossState();
        expect(await trainCrossing.crossingState()).to.equal(0); // FREE_TO_CROSS
    });

    it("Should lock crossing after validity period", async function () {
        await trainCrossing.updateFreeToCrossState();
        await ethers.provider.send("evm_increaseTime", [601]); // Increase time by 601 seconds
        await trainCrossing.connect(addr1).requestCarPermission();
        expect(await trainCrossing.crossingState()).to.equal(2); // PRE_LOCKED
    });

    it("Should stop train if pre-locked time has passed", async function () {
        await trainCrossing.authorizeTrain(addr1.address);
        await trainCrossing.updateFreeToCrossState();
        await trainCrossing.connect(addr1).requestTrainCrossing();
        await ethers.provider.send("evm_increaseTime", [301]); // Increase time by 301 seconds
        await expect(trainCrossing.connect(addr1).requestTrainCrossing())
            .to.emit(trainCrossing, "StopTrain")
            .withArgs(addr1.address);
    });
});
