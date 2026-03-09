// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Access {
    //access controls
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public threshold;

    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event ThresholdChanged(uint256 newThreshold);

    constructor(address[] memory _owners) {
        require(_owners.length > 0, "no owners");

        // set threshold to be 60% of owners
        threshold = (_owners.length * 60 + 99) / 100;

        for (uint256 i = 0; i < _owners.length; i++) {
            address o = _owners[i];
            require(o != address(0), "zero address owner");
            require(!isOwner[o], "duplicate owner");
            isOwner[o] = true;
            owners.push(o);
        }
    }

    // modifier onlyOwnerWithThreshold(uint256 _threshold) {
    //     require(isOwner[msg.sender], "not owner");
    //     require(
    //         _threshold > 0 && _threshold <= owners.length,
    //         "invalid threshold"
    //     );
    //     _;
    // }

    modifier onlyOwners() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    function getAllOwnsersCount() external view returns (uint) {
        return owners.length;
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    
}
