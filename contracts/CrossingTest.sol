pragma solidity ^0.8.0;

import "./Crossing.sol";

contract TrainCrossingTest is TrainCrossing {
    constructor(uint _crossingValidity, uint _maxCarsPerLane, uint _preLockedTime)
        TrainCrossing(_crossingValidity, _maxCarsPerLane, _preLockedTime) {}

    function publicCheckFreeToCrossTimer() public {
        checkFreeToCrossTimer();
    }

    function publicLockCrossing() public {
        lockCrossing();
    }
}
