// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract UpgradableContract is UUPSUpgradeable, OwnableUpgradeable {
    uint256 private changeId;
    uint256 public number;
    string public name;

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        number = 10;
    }

    function updateNumber(uint256 _number) public returns (uint256, uint256) {
        number = _number;
        changeId += 1;
        uint256 id = changeId;
        return (number, id);
    }

    function addName(string memory _name) public returns (string memory) {
        name = _name;
        return name;
    }
}
