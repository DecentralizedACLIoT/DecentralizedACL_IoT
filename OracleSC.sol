pragma solidity >=0.4.22 <0.7.0;

contract OracleSC {
    address oracleAddress; //Oracle Address
    struct Request {
        bytes data;
        function(bytes memory) external callback;
    }
    Request[] requests;
    event NewRequest(uint);
    modifier onlyBy(address account) {
        require(msg.sender == account); _;
    }
    function query(bytes memory data, function(bytes memory) external callback) public {
        requests.push(Request(data, callback));
        emit NewRequest(requests.length - 1);
    }
    // invoked by outside world
    function reply(uint requestID, bytes memory response) public onlyBy(oracleAddress) {
        requests[requestID].callback(response);
    }
}