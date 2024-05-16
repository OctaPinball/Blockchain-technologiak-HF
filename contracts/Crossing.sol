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
    
    mapping(address => bool) public crossingRequests; // Mapping to track crossing requests
    mapping(address => bool) public crossingCars; // Mapping to track crossing cars
    mapping(address => uint) public trainRequestTimes;
    
    event CrossRequest(address requester);
    event PermissionGranted(address requester);
    event PermissionReleased(address requester);
    event TrainApproaching();
    
    modifier onlyInfrastructure() {
        require(msg.sender == infrastructure, "Only infrastructure can call this function.");
        _;
    }
    
    modifier onlyFreeToCross() {
        require(crossingState == CrossingState.FREE_TO_CROSS, "Crossing is not free to cross.");
        _;
    }
    
    modifier onlyNotLocked() {
        require(crossingState != CrossingState.LOCKED, "Crossing is locked.");
        _;
    }
    
    modifier onlyInSpecialState() {
        require(crossingState == CrossingState.PRE_LOCKED, "Crossing is not in pre-locked state.");
        _;
    }

    modifier onlyWithFreeCrossingSlot() {
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
        lastUpdate = block.timestamp;
    }
    
    function requestCrossing() external onlyFreeToCross {
        crossingRequests[msg.sender] = true;
        emit CrossRequest(msg.sender);
    }
    
    function grantPermission(address requester) external onlyInfrastructure onlyNotLocked onlyWithFreeCrossingSlot {
        require(crossingRequests[requester], "No pending request from requester.");
        crossingCars[requester] = true;
        crossingRequests[requester] = false;
        currentCrossingCarNumber++;
        emit PermissionGranted(requester);
    }
    
    function releasePermission() external {
        require(crossingCars[msg.sender], "You don't have permission to release.");
        crossingCars[msg.sender] = false;
        currentCrossingCarNumber--;
        if(crossingState == CrossingState.PRE_LOCKED && currentCrossingCarNumber == 0) // in PRE-LOCKED state and crossing is empty
        {
            crossingState = CrossingState.LOCKED;
            // TODO Maybe here give all the trains the crossing permission
        }
        emit PermissionReleased(msg.sender);
    }
    
    function updateFreeToCrossState() external onlyInfrastructure {
        crossingState = CrossingState.FREE_TO_CROSS;
        lastUpdate = block.timestamp;
    }

    function freeToCrossExpire() internal {
        // If now - lastUpdate > crossingValidity
        // Exit from FREE TO CROSS
    }
    
    function trainRequestCrossing() external {
        if(crossingRequests[msg.sender] = false) // First request
        {
            crossingRequests[msg.sender] = true;
            trainRequestTimes[msg.sender] = block.timestamp;
        }
        if(currentCrossingCarNumber == 0)
        {
            crossingState = CrossingState.LOCKED; // LOCKED
            // TODO Maybe give here a permission...
        }
        else 
        {
            crossingState = CrossingState.PRE_LOCKED; // PRE-LOCKED
        }
    }

    function trainReleaseCrossing() external {
        require(crossingCars[msg.sender], "You don't have permission to release.");
        crossingCars[msg.sender] = false;
    }

    function stopTrain() internal {
        // If now - trainRequestTimes[msg.sender] > preLockedTime
        // STOP TRAIN
    }
}
