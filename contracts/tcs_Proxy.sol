// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract BasicToken is Initializable, ERC20Upgradeable {
    function initialize(string calldata _name, string calldata _symbol)
        external
        initializer
    {
        __ERC20_init(_name, _symbol);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}

contract BasicTokenProxyFactory is Ownable {
    address public implementation;

    address[] public clonesList;

    event CloneCreated(address _clone);

    constructor(address _implementation, address initialOwner)
        Ownable(initialOwner)
    {
        implementation = _implementation;
    }

    function createNewToken(string calldata _name, string calldata _symbol)
        external
        returns (address newInstance)
    {
        newInstance = Clones.clone(implementation);
        (bool success, ) = newInstance.call(
            abi.encodeWithSignature("initialize(string,string)", _name, _symbol)
        );
        require(success, "Creation Failed");
        clonesList.push(newInstance);
        emit CloneCreated(newInstance);
        return newInstance;
    }
}
