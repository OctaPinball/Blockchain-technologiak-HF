pragma solidity ^0.8.0;

contract TrainCrossing {
    address public infrastructure; // Address of the railway infrastructure
    uint public crossingState; // 0 - LOCKED, 1 - FREE TO CROSS, 2 - SPECIAL STATE
    uint public lastUpdate; // Timestamp of the last state update
    uint public crossingValidity; // Validity time of the "FREE TO CROSS" state
    uint public maxCarsPerLane; // Maximum number of crossing cars per lane
    
    mapping(address => bool) public crossingRequests; // Mapping to track crossing requests
    mapping(address => bool) public crossingCars; // Mapping to track crossing cars
    
    event CrossRequest(address requester);
    event PermissionGranted(address requester);
    event PermissionReleased(address requester);
    event TrainApproaching();
    
    modifier onlyInfrastructure() {
        require(msg.sender == infrastructure, "Only infrastructure can call this function.");
        _;
    }
    
    modifier onlyFreeToCross() {
        require(crossingState == 1, "Crossing is not free to cross.");
        _;
    }
    
    modifier onlyNotLocked() {
        require(crossingState != 0, "Crossing is locked.");
        _;
    }
    
    modifier onlyInSpecialState() {
        require(crossingState == 2, "Crossing is not in special state.");
        _;
    }
    
    constructor(uint _crossingValidity, uint _maxCarsPerLane) {
        infrastructure = msg.sender;
        crossingValidity = _crossingValidity;
        maxCarsPerLane = _maxCarsPerLane;
        crossingState = 0; // Initialize with LOCKED state
        lastUpdate = block.timestamp;
    }
    
    function requestCrossing() external onlyFreeToCross {
        crossingRequests[msg.sender] = true;
        emit CrossRequest(msg.sender);
    }
    
    function grantPermission(address requester) external onlyInfrastructure onlyNotLocked {
        require(crossingRequests[requester], "No pending request from requester.");
        crossingCars[requester] = true;
        crossingRequests[requester] = false;
        emit PermissionGranted(requester);
    }
    
    function releasePermission() external {
        require(crossingCars[msg.sender], "You don't have permission to release.");
        crossingCars[msg.sender] = false;
        emit PermissionReleased(msg.sender);
    }
    
    function updateCrossingState(uint _newState) external onlyInfrastructure {
        crossingState = _newState;
        lastUpdate = block.timestamp;
        if (_newState == 2) {
            emit TrainApproaching();
        }
    }
    
    function trainRequestCrossing() external onlyInfrastructure onlyInSpecialState {
        // Logic to handle train crossing request
    }
}
