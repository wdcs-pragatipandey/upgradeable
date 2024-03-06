// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

contract Vaultv1 is Initializable {
    string public name;
    uint256 public vaLue;

    function initialize(string memory _name, uint256 _vaLue)
        public
        initializer
    {
        name = _name;
        vaLue = _vaLue;
    }

    function down() public {
        vaLue--;
        revert("!vaLue");
    }
}

contract Vaultv2 is Initializable {
    string public name;
    uint256 public vaLue;

    function initialize(string memory _name, uint256 _vaLue)
        public
        initializer
    {
        name = _name;
        vaLue = _vaLue;
    }

    function down() public {
        vaLue--;
        revert("!vaLue");
    }

    function up() public {
        vaLue++;
    }
}

contract VaultBeacon {
    UpgradeableBeacon immutable beacon;

    address public vLogic;

    constructor(address _vLogic) {
        beacon = new UpgradeableBeacon(_vLogic, address(this));
        vLogic = _vLogic;
    }

    function update(address _vLogic) public {
        beacon.upgradeTo(_vLogic);
        vLogic = _vLogic;
    }

    function implementation() public view returns (address) {
        return beacon.implementation();
    }
}

contract Factory {
    mapping(uint256 => address) private vaults;

    VaultBeacon immutable beacon;

    constructor(address _vLogic) {
        beacon = new VaultBeacon(_vLogic);
    }

    function create(
        string calldata _name,
        uint256 _vaLue,
        uint256 x
    ) external returns (address) {
        BeaconProxy proxy = new BeaconProxy(
            address(beacon),
            abi.encodeWithSelector(
                Vaultv1(address(0)).initialize.selector,
                _name,
                _vaLue
            )
        );
        vaults[x] = address(proxy);
        return address(proxy);
    }

    function getImplementation() public view returns (address) {
        return beacon.implementation();
    }

    function getBeacon() public view returns (address) {
        return address(beacon);
    }

    function getVault(uint256 x) public view returns (address) {
        return vaults[x];
    }
}
