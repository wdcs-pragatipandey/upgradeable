/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

library LibDiamond {
    /// Storage slots of this diamond
    // load the storage of the diamond contract at a specific location:
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    event DiamondCut(FacetCut _diamondCut);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    struct FacetCut {
        address facetAddress; // address of the contract representing the facet of the diamond
        bytes4[] functionSelectors; // which functions from this new facet do we want registered
    }

    // Access existing facets and functions (aka selectors):
    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    /** ==================================================================
                        CUT NEW FACETS INTO THIS DIAMOND
    =====================================================================*/

    // The main function that is used to cut new facets into the diamond (aka add a new contract and its functions to the diamond)
    // Internal function version of diamondCut
    function diamondCut(FacetCut calldata _diamondCut) internal {
        address facetAddress = _diamondCut.facetAddress;
        bytes4[] memory functionSelectors = _diamondCut.functionSelectors;

        require(
            functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        require(
            facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );

        DiamondStorage storage ds = diamondStorage(); // store in "core" storage

        // where are we at in the selector array under this facet?
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[facetAddress].functionSelectors.length
        );

        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            // no selectors have been registered under this facet ever: hence, the facet does not exist; add it:
            _enforceHasContractCode(
                facetAddress,
                "LibDiamondCut: New facet has no code"
            );
            // store facet address
            ds.facetFunctionSelectors[facetAddress].facetAddressPosition = ds
                .facetAddresses
                .length;
            ds.facetAddresses.push(facetAddress);
        }

        // add each new incoming function selector to this facet
        for (
            uint256 selectorIndex;
            selectorIndex < functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = functionSelectors[selectorIndex];

            // ensure the facet does not already exist:
            address currentFacetAddressIfAny = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                currentFacetAddressIfAny == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );

            // ADD The function (selector) here:
            // map the selector to the position in the overall selector array and also map it to the facet address
            ds
                .selectorToFacetAndPosition[selector]
                .functionSelectorPosition = selectorPosition;
            ds.selectorToFacetAndPosition[selector].facetAddress = facetAddress;
            // we track the selectors in an array under the facet address
            ds.facetFunctionSelectors[facetAddress].functionSelectors.push(
                selector
            );

            selectorPosition++;
        }
        emit DiamondCut(_diamondCut);
    }

    /** ==================================================================
                            Core Diamond State
    =====================================================================*/

    // core diamond contract ownership:
    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address) {
        return diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            _msgSender() == contractOwner(),
            "LibDiamond: Must be contract owner"
        );
    }

    // private functions in this section

    function _enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) private view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

    function _msgSender() private view returns (address) {
        // put msg.sender behind a private view wall
        return msg.sender;
    }

    /** ==================================================================
                            General Diamond Storage Space
    =====================================================================*/

    /**
     * @notice Core diamond storage space (note that nft and erc20 are in different spaces)
     */
    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // owner of the diamond contract
        address contractOwner;
    }

    // access core storage via:
    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

contract Diamond {
    constructor(address _contractOwner) payable {
        LibDiamond.setContractOwner(_contractOwner);
    }

    /// Cut new facets into this diamond
    function diamondCut(LibDiamond.FacetCut calldata _diamondCut) external {
        // only the diamond owner can cut new facets
        LibDiamond.enforceIsContractOwner();
        // cut the facet into the diamond
        LibDiamond.diamondCut(_diamondCut);
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // get facet from function selector (which is == msg.sig)
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");

        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize()) // copies the calldata into memory (this is where delegatecall loads from)
            // execute function call against the relevant facet
            // note that we send in the entire calldata including the function selector
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                // delegate call failed
                revert(0, returndatasize()) // so revert
            }
            default {
                return(0, returndatasize()) // delegatecall succeeded, return any return data
            }
        }
    }

    receive() external payable {}
}

library LibERC20 {
    bytes32 constant ERC20_STORAGE_POSITION =
        keccak256("facet.erc20.diamond.storage");

    struct Storage {
        uint256 _totalSupply;
        mapping(address => uint256) _balances;
        mapping(address => mapping(address => uint256)) _allowances;
    }

    function getStorage() internal pure returns (Storage storage ds) {
        bytes32 position = ERC20_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function mint(uint256 amount) internal {
        require(msg.sender != address(0), "ERC20: mint  to the zero address");

        _beforeTokenTransfer(address(0), msg.sender, amount);

        Storage storage ds = getStorage();

        ds._totalSupply += amount;
        unchecked {
            ds._balances[msg.sender] += amount;
        }
        emit Transfer(address(0), msg.sender, amount);

        _afterTokenTransfer(address(0), msg.sender, amount);
    }

    function balanceOf(address account) internal view returns (uint256) {
        Storage storage ds = getStorage();
        return ds._balances[account];
    }

    function transferFrom(
        address spender,
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        _allowance(from, spender);
        _transfer(from, to, amount);
        return true;
    }

    function transfer(address to, uint256 amount) internal returns (bool) {
        address owner = _msgSender();

        _transfer(owner, to, amount);
        return true;
    }

    function _msgSender() private view returns (address) {
        return msg.sender;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        Storage storage ds = getStorage();

        uint256 fromBalance = ds._balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            ds._balances[from] = fromBalance - amount;
            ds._balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _allowance(address owner, address spender)
        internal
        view
        returns (uint256)
    {
        Storage storage ds = getStorage();
        return ds._allowances[owner][spender];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        Storage storage ds = getStorage();

        ds._allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}
}

contract ERC20Facet {
    function erc20mint(uint256 amount) external {
        LibERC20.mint(amount);
    }

    function approve(address spender, uint256 amount) external {
        address owner = _msgSender();
        LibERC20._approve(owner, spender, amount);
    }

    function balanceOf(address account) external view returns (uint256) {
        return LibERC20.balanceOf(account);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return LibERC20.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        address spender = _msgSender();
        return LibERC20.transferFrom(spender, from, to, amount);
    }

    function _msgSender() private view returns (address) {
        return msg.sender;
    }
}
