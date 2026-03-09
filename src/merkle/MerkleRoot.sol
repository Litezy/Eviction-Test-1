// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MerkleProof} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";


contract MerkleRoot {
    event MerkleRootSet(bytes32 indexed newRoot);
    event Claimed(address indexed claimant);
    bytes32 public merkleRoot;
    
    // to hold for claims and usedhashe
    mapping(bytes32 => bool) public usedHashes;
    mapping(address => bool) public claimed;
    


    function verifySignatry( bytes32[] calldata proof, address claimant, uint256 amount ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(claimant, amount));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }


    function setMerkleRoot(bytes32 root) external virtual {
        require(root != bytes32(0), "No root found");
        merkleRoot = root;
        emit MerkleRootSet(root);
    }

    function markClaimed(address claimant) internal {
        claimed[claimant] = true;
        emit Claimed(claimant);
    }

    function isClaimed(address claimant) external view returns (bool) {
        return claimed[claimant];
    }
}