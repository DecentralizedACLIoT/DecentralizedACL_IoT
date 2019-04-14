pragma solidity >=0.4.22 <0.6.0;
 
contract Aggregator{
    function addOracle(address oracleAddress, address[] memory devicesAddresses) public ;
    function sendDataRequest(bytes32 UID, address userAddr, address iotDeviceAddr, uint numOfOracles) public ;
    function oracleResponse(bytes memory response) public ;
    function reportReputationScore(address reputationSC, address[] memory oracleAddress, bytes[] memory dataHashes) private ;
}
contract AccessControl{
    
     /*
     1. Register Admin
     2. RegisterIoTDevice
     3. AddUserToIoTDevice
     4. RegisterUser
     5. RequestData --> verify permisoions
        a. denied --> do nothing
        b. Grant --> send request to  Aggregator
          (not sure) --> return oracle address and access token
     */
    uint256 count=0; //count for all the tokens
    address owner;//the onwer of the contract is the first admin and the creator
    address aggregatorSC;//the address if the aggregator smart cntract
     
    address [] admins; // admins of the system
    struct Token{ // struct for the information of a given token
        bytes32 UID;
        address user;
        address dev;
        uint numberOfOracles;
    }
   
    Token [] public Tokens ; // array of all tokens issued
    address [] public Devices ; // array of all devices owned by the admin
    mapping (address => address[]) public users_devices; // mapping for users and the devices they can access
   
    modifier onlyAdmin{ // for user check at modifications
        bool admin=false;
        for(uint256 i = 0; i < admins.length;i++){
            if(msg.sender==admins[i]){
                admin=true;
                break;
            }
        }
        require (admin,"Not an admin");
        _;
    }
   
    /* -----------set owner, add admins, register users and map deices to them ----------------*/
 
    constructor(address addr) public{
        admins.push(msg.sender); //creater of contract is the first admin
        owner=msg.sender;
        aggregatorSC=addr;
    }
    
    // adding a device by an admin
    function addDevice(address newDevice) public onlyAdmin{
        Devices.push(newDevice);
        emit DeviceAdded(newDevice,msg.sender);
    }
    
    // adding admin by other admins
    function addAdmin(address newAdmin) public onlyAdmin{
        admins.push(newAdmin);
        emit AdminAdded(newAdmin,msg.sender);
    }
    
    // adds a device to a given user by admin
    function addUserDeviceMapping(address user, address device) public onlyAdmin{
        //only admin can add users and devices
        //Check if device exist
        bool deviceExists=false;
        for(uint256 i = 0; i<Devices.length; i++){
        // Check if device is exist
        if(Devices[i]==device){ // check the devices of a user
        //the device exist
            deviceExists=true;
            break;
            }
        }
        if(deviceExists){
            users_devices[user].push(device);
          emit  UserDeviceMappingAdded(user,device,msg.sender);
        }
        else
           emit DeviceDoesnotExist(device,msg.sender);
          
    }
               /* -------------Events--------------- */
     // to share the addition of new admin by who
    event AdminAdded(address newAdmin, address addingAdmin);
    event DeviceAdded(address newDevice,address addingAdmin);
    // to share new mapping for user-device mapping added by who
    event UserDeviceMappingAdded(address user, address device, address addingAdmin);
     // to share the requested device doesn't exist on the system
    event DeviceDoesnotExist(address device, address sender);
   
     /* -------------Delete Admin/users--------------- */
        // delete a given admin
    function delAdmin (address admin) public onlyAdmin{
        require (admins.length>=2 && admin!=owner, "Cannot delte admin");
            uint256 i = 0;
            while(i < admins.length){
                if(admins[i]== admin){
                    delete admins[i];
                    emit AdminDeleted(admin,msg.sender);
                }
                i++;
            }
    }
    // delete user access to all devices
    function delUser(address user) public onlyAdmin{
        delete users_devices[user];
        emit UserDeviceAllMappingDeleted(user,msg.sender);
    }
                /* -------------Events--------------- */
      // to share the deletion of an admin by who
    event AdminDeleted(address newAdmin, address deletingAdmin);
    // to share the deletion of all user-device mapping of a user added by who
    event UserDeviceAllMappingDeleted(address user,  address deletingAdmin);
   
    /* -------------User Request to access IoT device data (authentication process)--------------- */
    function requestUserToAccessDevice(address device, uint numberOracle) public {
        
        bool deviceExists=false;
        for(uint256 i = 0; i<Devices.length; i++){
        // Check if device is exist
        if(Devices[i]==device){ // check the devices of a user
        //the device exist
            deviceExists=true;
            break;
            }
        }
        if(!deviceExists){
          emit DeviceDoesnotExist(device,msg.sender);
        }else {
            bool auth=false;
            for(uint256 m = 0; m<users_devices[msg.sender].length; m++){
                if(users_devices[msg.sender][m]==device){
                // if this is true then the user is granted access
                    auth=true;
                    break;
                }
            }
            if(auth){ // shares successful authentication event
                emit Authenticated(msg.sender,device);
                bytes32 UID=keccak256(abi.encodePacked(device,msg.sender,block.timestamp,numberOracle));
                Tokens.push(Token(UID,msg.sender,device,numberOracle));
                emit TokenCreated(UID,msg.sender,device,numberOracle);
                Aggregator agg=Aggregator(aggregatorSC);
                agg.sendDataRequest(UID, msg.sender,device,numberOracle);
            }
            else if(!auth){
                // trigger failed authentication event
                emit NotAuthenticated(msg.sender);
            }
        }
    }
                   /* -------------Events--------------- */
    event Authenticated(address user, address device);
    event NotAuthenticated(address user);
    event TokenCreated(bytes32 uid, address user, address device, uint numberOfOracles);
}
