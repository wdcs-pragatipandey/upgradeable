//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

contract Proxy {
    constructor(bytes memory constructData, address contractLogic) {
        assembly {
            sstore(
                0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7,
                contractLogic
            )
        }
        (bool success, ) = contractLogic.delegatecall(constructData);
        require(success, "Delegatecall failed");
    }

    fallback() external payable {
        assembly {
            let contractLogic := sload(
                0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7
            )
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                sub(gas(), 10000),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }
}

contract Proxiable {
    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(
                0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7
            ) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly {
            sstore(
                0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7,
                newAddress
            )
        }
    }

    function proxiableUUID() public pure returns (bytes32) {
        return
            0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}

contract MyContract {
    address public owner;
    uint256 public totalVoter;

    struct vote {
        address voterAddress;
        bool choice;
    }

    struct voter {
        string voterName;
        bool voted;
    }
    mapping(uint256 => vote) private votes;
    mapping(address => voter) private voterRegister;

    function constructor1() public {
        require(owner == address(0), "Already initalized");
        owner = msg.sender;
    }

    function addVoter(address _voterAddress, string memory _voterName) public {
        voter memory v;
        v.voterName = _voterName;
        v.voted = true;
        voterRegister[_voterAddress] = v;
        totalVoter++;
    }

    function removeVoter(address _voterAddress, string memory _voterName)
        public
    {
        voter memory v;
        v.voterName = _voterName;
        v.voted = false;
        voterRegister[_voterAddress] = v;
        totalVoter--;
    }
}

contract MyFinalContract is MyContract, Proxiable {
    function updateCode(address newCode) public onlyOwner {
        updateCodeAddress(newCode);
    }

    modifier onlyOwner() {
        require(owner == address(0), "Already initalized");
        _;
    }
}
