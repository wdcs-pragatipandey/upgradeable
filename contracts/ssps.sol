// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ERC1967/ERC1967UpgradeUpgradeable.sol";

contract Data is Initializable {
    mapping(string => string) stringStorage;
}

contract Greeter is ERC1967UpgradeUpgradeable, Data {
    function initialize() public initializer {
        __ERC1967Upgrade_init();
    }

    function greet() public view returns (string memory) {
        return stringStorage["test"];
    }

    function setGreeting(string memory _greeting) public {
        stringStorage["test"] = _greeting;
    }
}

contract Greeter2 is ERC1967UpgradeUpgradeable, Data {
    function initialize() public initializer {
        __ERC1967Upgrade_init();
    }

    function setString(string memory _number) external {
        stringStorage["test"] = _number;
    }

    function getString() public view returns (string memory) {
        return stringStorage["test"];
    }

    function getStringK1() public view returns (string memory) {
        return stringStorage["test"];
    }
}
