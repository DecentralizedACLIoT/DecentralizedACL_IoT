pragma solidity >=0.4.22 <0.7.0;

contract ReputationSC{
    //This is the address for contract oswer
    address public owner;
    
    //List of aggregators addresses
    address[] aggregators;
    
    // This is a type for a single oracle.
    struct Oracle {
        uint numContributions; // how many time this oracle contributed with data
        uint averageReputation; //average reputation score
    }
    
    // This declares a state variable that stores a 'Oracle' struct for crosponding oracle's address.
    mapping(address => Oracle) public oracles;

    //constructor
    constructor()public{
        owner = msg.sender;
        addAggregator(owner);
    }
    
    modifier onlyOwner() { // Modifier
        require(
            msg.sender == owner,
            "Only contract owner can call this."
        );
        _;
    }
    
    modifier onlyAggregator{ // Modifier
        bool aggregator=false;
        for(uint256 i = 0; i < aggregators.length;i++){
            if(msg.sender==aggregators[i]){
                aggregator=true;
                break;
            }
        }
        
        require(
            aggregator==true,
            "Only aggregator can call this."
        );
        _;
       
    }
    
    //Add new aggregator 
    function addAggregator(address aggregatorAddress) public onlyOwner {
        aggregators.push(aggregatorAddress);
        emit AggregatorAdded(aggregatorAddress,msg.sender);
    }
    
    // to share the addition of new aggregator 
    event AggregatorAdded(address newAggregator, address owner); 
    
    //This function record the points for a list of oracles and return the address of the oracle with highest average points
    function reportReputationScore(address[] memory oracleAddress, uint[] memory points) public onlyAggregator returns (address winningOracleAddress){
        for (uint i = 0; i < oracleAddress.length; i++) {
            address addrs = oracleAddress[i];
            uint c = oracles[addrs].numContributions;
            uint avg = oracles[addrs].averageReputation;
            oracles[addrs].averageReputation = ((c*avg)+points[i])/(c+1);
            oracles[addrs].numContributions++;
            
        }
        
        winningOracleAddress = selectWinningOracle(oracleAddress);
    }
    
    //This is a private function to select the winning oracle address from a given list of oracles
    function selectWinningOracle(address[] memory oracleAddress) private view returns (address winningOracleAddress)
    {
        uint maxAveragePoints = 0;
        uint currentAveragePoints=0;
        for (uint i = 0; i < oracleAddress.length; i++) {
            currentAveragePoints = oracles[oracleAddress[i]].averageReputation;
            if (currentAveragePoints >= maxAveragePoints) {
                maxAveragePoints = currentAveragePoints;
                winningOracleAddress = oracleAddress[i];
            }
        }
    }
    
    //This fucntion returns average reputatoin score for a given oracle
    function getOracleReputation(address oracleAddress) public view returns (uint averageReputationScore){
        return oracles[oracleAddress].averageReputation;
    }

}