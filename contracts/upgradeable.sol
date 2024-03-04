//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

abstract contract Upgradeable {
    mapping(bytes4 => uint32) _sizes;
    address _dest;

    function initialize() public virtual;

    function replace(address target) public {
        _dest = target;
        (bool success, ) = target.delegatecall(
            abi.encodeWithSelector(bytes4(keccak256("initialize()")))
        );
        require(success, "Initialization failed");
    }
}

contract Dispatcher is Upgradeable {
    constructor(address target) {
        replace(target);
    }

    function initialize() public override {
        _sizes[bytes4(keccak256("getUint()"))] = 32;
    }

    fallback() external {
        bytes4 sig;
        assembly {
            sig := calldataload(0)
        }
        uint256 len = _sizes[sig];
        address target = _dest;

        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let result := delegatecall(
                sub(gas(), 10000),
                target,
                0x0,
                calldatasize(),
                0,
                len
            )
            return(0, len)
        }
    }
}

contract Vote is Upgradeable {
    constructor(string memory _ballotOfficialName, string memory _proposal) {
        ballotOfficialAddress = msg.sender;
        ballotOfficialName = _ballotOfficialName;
        proposol = _proposal;

        state = State.Created;
    }

    struct vote {
        address voterAddress;
        bool choice;
    }

    struct voter {
        string voterName;
        bool voted;
    }

    uint256 private countResult = 0;
    uint256 public finalResult = 0;
    uint256 public totalVoter = 0;
    uint256 public totalVotes = 0;

    address public ballotOfficialAddress;
    string public ballotOfficialName;
    string public proposol;

    mapping(uint256 => vote) private votes;
    mapping(address => voter) public voterRegister;

    enum State {
        Created,
        Voting,
        Ended
    }
    State public state;

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    modifier onlyOfficial() {
        require(msg.sender == ballotOfficialAddress);
        _;
    }

    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    function initialize() public override {
        _sizes[bytes4(keccak256("getUint()"))] = 32;
    }

    function addVoter(address _voterAddress, string memory _voterName)
        public
        inState(State.Created)
        onlyOfficial
    {
        voter memory v;
        v.voterName = _voterName;
        v.voted = false;
        voterRegister[_voterAddress] = v;
        totalVoter++;
    }

    function startVote() public inState(State.Created) onlyOfficial {
        state = State.Voting;
    }

    function doVote(bool _choice)
        public
        inState(State.Voting)
        returns (bool voted)
    {
        bool found = false;

        if (
            bytes(voterRegister[msg.sender].voterName).length != 0 &&
            !voterRegister[msg.sender].voted
        ) {
            voterRegister[msg.sender].voted = true;
            vote memory v;
            v.voterAddress = msg.sender;
            v.choice = _choice;
            if (_choice) {
                countResult++;
            }
            votes[totalVotes] = v;
            totalVotes++;
            found = true;
        }
        return found;
    }

    function endVote() public inState(State.Voting) onlyOfficial {
        state = State.Ended;
        finalResult = countResult;
    }
}
