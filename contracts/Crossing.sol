pragma solidity ^0.8.0;

contract TrainCrossing {

    enum CrossingState { FREE_TO_CROSS, LOCKED, PRE_LOCKED }

    CrossingState public crossingState;
    address public infrastructure; // Address of the railway infrastructure
    uint public lastUpdate; // Timestamp of the last state update
    uint public crossingValidity; // Validity time of the "FREE TO CROSS" state
    uint public maxCarsPerLane; // Maximum number of crossing cars per lane
    uint public preLockedTime; // Maximum elapsed time since the first train crossing request, after which the train brakes
    uint public currentCrossingCarNumber; // Number of cars, which are currently crossing
    uint public trainCrossingRequestNumber;
    
    mapping(address => bool) public crossingVehicles; // Mapping to track crossing cars
    mapping(address => bool) public trainCrossingRequests;
    mapping(address => uint) public trainRequestTimes;
    
    event CarCrossRequest(address requester);
    event CarCrossingPermissionGranted(address requester);
    event CarCrossingPermissionReleased(address requester);
    event TrainCrossingRequest(address requester, bool first);
    event TrainCrossingPermissionGranted(address requester);
    event TrainCrossingWaitingForRetry(address requester);
    event StopTrain(address requester);
    event TrainCrossingPermissionReleased(address requester);
    
    modifier onlyInfrastructure() {
        require(msg.sender == infrastructure, "Only infrastructure can call this function.");
        _;
    }
    
    modifier onlyFreeToCross() {
        checkFreeToCrossTimer();
        require(crossingState == CrossingState.FREE_TO_CROSS, "Crossing is not free to cross.");
        _;
    }
    
    modifier onlyNotLocked() {
        require(crossingState != CrossingState.LOCKED, "Crossing is locked.");
        _;
    }

    modifier onlyWhenCrossingNotFull() {
        require(currentCrossingCarNumber < maxCarsPerLane);
        _;
    }
    
    constructor(uint _crossingValidity, uint _maxCarsPerLane, uint _preLockedTime) {
        infrastructure = msg.sender;
        crossingValidity = _crossingValidity;
        maxCarsPerLane = _maxCarsPerLane;
        preLockedTime = _preLockedTime;
        crossingState = CrossingState.LOCKED; // Initialize with LOCKED state
        currentCrossingCarNumber = 0; // Initialize with 0 crossing cars
        trainCrossingRequestNumber = 0;
        lastUpdate = block.timestamp;
    }
    
    function requestPermission() external onlyFreeToCross onlyWhenCrossingNotFull {
        crossingVehicles[msg.sender] = true;
        currentCrossingCarNumber++;
        emit CarCrossingPermissionGranted(msg.sender);
    }

    function releasePermission() external {
        require(crossingVehicles[msg.sender], "Vehicle has not requested permission");
        crossingVehicles[msg.sender] = false;
        currentCrossingCarNumber--;
        emit CarCrossingPermissionReleased(msg.sender);
    }
    
    function updateFreeToCrossState() external onlyInfrastructure {
        crossingState = CrossingState.FREE_TO_CROSS;
        lastUpdate = block.timestamp;
    }

    function checkFreeToCrossTimer() internal {
        if(block.timestamp - lastUpdate > crossingValidity && crossingState == CrossingState.FREE_TO_CROSS)
        {
            lockCrossing();
        }
    }

    function lockCrossing() internal {
        if(currentCrossingCarNumber > 0)
        {
            crossingState = CrossingState.PRE_LOCKED;
        }
        else
        {
            crossingState = CrossingState.LOCKED;
        }
    }
    
    function trainRequestCrossing() external {
        emit TrainCrossingRequest(msg.sender, trainCrossingRequests[msg.sender]);
        if(!trainCrossingRequests[msg.sender]) // First request
        {
            trainCrossingRequests[msg.sender] = true;
            trainRequestTimes[msg.sender] = block.timestamp;
            trainCrossingRequestNumber++;
        }

        lockCrossing();

        if(crossingState == CrossingState.PRE_LOCKED)
        {
            if(block.timestamp - trainRequestTimes[msg.sender] > preLockedTime)
            {
                emit StopTrain(msg.sender);
                return;
            }
            emit TrainCrossingWaitingForRetry(msg.sender);
            return;

        }
        if(crossingState == CrossingState.LOCKED)
        {
            emit TrainCrossingPermissionGranted(msg.sender);
            return;
        }

    }

    function trainReleaseCrossing() external {
        require(crossingVehicles[msg.sender], "You don't have permission to release.");
        crossingVehicles[msg.sender] = false;
        trainCrossingRequestNumber--;
        if(trainCrossingRequestNumber == 0)
        {
            crossingState = CrossingState.FREE_TO_CROSS;
        }
        emit TrainCrossingPermissionReleased(msg.sender);
    }

}
