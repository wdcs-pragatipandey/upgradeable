// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Storage {
    mapping(bytes32 => uint256) uintVars;
    mapping(bytes32 => string) stringVars;

    function setUintVars(bytes32 varName, uint256 value) public {
        uintVars[varName] = value;
    }

    function getUintVarsValue(bytes32 varName) public view returns (uint256) {
        return uintVars[varName];
    }

    function setStringVars(bytes32 varName, string calldata value) public {
        stringVars[varName] = value;
    }

    function getStringVarsValue(bytes32 varName)
        public
        view
        returns (string memory)
    {
        return stringVars[varName];
    }
}

contract LogicContract {
    address storageAddr;

    constructor(address storageContractAddress) {
        storageAddr = storageContractAddress;
    }

    function addX(uint256 a, uint256 b) public {
        uint256 x = a + b;
        Storage(storageAddr).setUintVars(keccak256("x"), x);
    }

    function getX() public view returns (uint256) {
        return Storage(storageAddr).getUintVarsValue(keccak256("x"));
    }

    function setUserName(string memory name) public {
        Storage(storageAddr).setStringVars(keccak256("Username"), name);
    }

    function getuserName() public view returns (string memory) {
        return Storage(storageAddr).getStringVarsValue(keccak256("Username"));
    }
}
