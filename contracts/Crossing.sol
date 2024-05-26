pragma solidity ^0.8.0;

contract TrainCrossing {

    enum CrossingState { FREE_TO_CROSS, LOCKED, PRE_LOCKED }

    CrossingState public crossingState;
    address public infrastructure;
    uint public lastUpdate;
    uint public crossingValidity;
    uint public maxCarsPerLane;
    uint public preLockedTime;
    uint public currentCrossingCarNumber;
    uint public trainCrossingRequestNumber;
    
    mapping(address => bool) public crossingVehicles;
    mapping(address => bool) public trainCrossingRequests;
    mapping(address => uint) public trainRequestTimes;
    mapping(address => bool) public authorizedTrains;
    
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

    modifier onlyAuthorizedTrain() {
        require(authorizedTrains[msg.sender], "Not authorized train.");
        _;
    }
    
    modifier onlyFreeToCross() {
        checkFreeToCrossTimer();
        require(crossingState == CrossingState.FREE_TO_CROSS, "Crossing is not free to cross.");
        _;
    }

    modifier onlyWhenCrossingNotFull() {
        require(currentCrossingCarNumber < maxCarsPerLane, "Crossing is full.");
        _;
    }
    
    constructor(uint _crossingValidity, uint _maxCarsPerLane, uint _preLockedTime) {
        infrastructure = msg.sender;
        crossingValidity = _crossingValidity;
        maxCarsPerLane = _maxCarsPerLane;
        preLockedTime = _preLockedTime;
        crossingState = CrossingState.LOCKED;
        currentCrossingCarNumber = 0;
        trainCrossingRequestNumber = 0;
        lastUpdate = block.timestamp;
    }

    // Functions for Cars
    function requestCarPermission() external onlyFreeToCross onlyWhenCrossingNotFull {
        require(!crossingVehicles[msg.sender], "Already crossing");
        crossingVehicles[msg.sender] = true;
        currentCrossingCarNumber++;
        emit CarCrossingPermissionGranted(msg.sender);
    }

    function releaseCarPermission() external {
        require(crossingVehicles[msg.sender], "Vehicle has not requested permission");
        crossingVehicles[msg.sender] = false;
        currentCrossingCarNumber--;
        emit CarCrossingPermissionReleased(msg.sender);
    }
    
    // Functions for Trains
    function requestTrainCrossing() external onlyAuthorizedTrain {
        emit TrainCrossingRequest(msg.sender, !trainCrossingRequests[msg.sender]);

        if (!trainCrossingRequests[msg.sender]) {
            trainCrossingRequests[msg.sender] = true;
            trainRequestTimes[msg.sender] = block.timestamp;
            trainCrossingRequestNumber++;
        }

        lockCrossing();

        if (crossingState == CrossingState.PRE_LOCKED) {
            if (block.timestamp - trainRequestTimes[msg.sender] > preLockedTime) {
                emit StopTrain(msg.sender);
                return;
            }
            emit TrainCrossingWaitingForRetry(msg.sender);
        } else if (crossingState == CrossingState.LOCKED) {
            emit TrainCrossingPermissionGranted(msg.sender);
        }
    }

    function releaseTrainCrossing() external onlyAuthorizedTrain {
        require(trainCrossingRequests[msg.sender], "You don't have permission to release.");
        trainCrossingRequests[msg.sender] = false;
        trainCrossingRequestNumber--;
        
        if (trainCrossingRequestNumber == 0) {
            crossingState = CrossingState.FREE_TO_CROSS;
        }
        
        emit TrainCrossingPermissionReleased(msg.sender);
    }

    // Administrative Functions
    function updateFreeToCrossState() external onlyInfrastructure {
        crossingState = CrossingState.FREE_TO_CROSS;
        lastUpdate = block.timestamp;
    }

    function authorizeTrain(address train) external onlyInfrastructure {
        authorizedTrains[train] = true;
    }

    function deauthorizeTrain(address train) external onlyInfrastructure {
        authorizedTrains[train] = false;
    }

    function checkFreeToCrossTimer() internal {
        if (block.timestamp - lastUpdate > crossingValidity && crossingState == CrossingState.FREE_TO_CROSS) {
            lockCrossing();
        }
    }

    function lockCrossing() internal {
        if (currentCrossingCarNumber > 0) {
            crossingState = CrossingState.PRE_LOCKED;
        } else {
            crossingState = CrossingState.LOCKED;
        }
    }
}
