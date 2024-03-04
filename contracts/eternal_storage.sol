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

library StorageLib {
    function setXVar(address storageContractAddress, uint256 value) public {
        Storage(storageContractAddress).setUintVars(keccak256("x"), value);
    }

    function getXVar(address storageContractAddress)
        public
        view
        returns (uint256)
    {
        return Storage(storageContractAddress).getUintVarsValue(keccak256("x"));
    }

    function setUserNameVar(address storageContractAddress, string memory value)
        public
    {
        Storage(storageContractAddress).setStringVars(
            keccak256("Username"),
            value
        );
    }

    function getUserNameVar(address storageContractAddress)
        public
        view
        returns (string memory)
    {
        return
            Storage(storageContractAddress).getStringVarsValue(
                keccak256("Username")
            );
    }
}

contract LogicContract {
    using StorageLib for address;
    address storageAddr;

    constructor(address storageContractAddress) {
        storageAddr = storageContractAddress;
    }

    function addX(uint256 a, uint256 b) public {
        uint256 x = a + b;
        storageAddr.setXVar(x);
    }

    function getX() public view returns (uint256) {
        return storageAddr.getXVar();
    }

    function setUserName(string memory name) public {
        storageAddr.setUserNameVar(name);
    }

    function getuserName() public view returns (string memory) {
        return storageAddr.getUserNameVar();
    }
}
