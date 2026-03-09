// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MultiSig} from "src/Multisig/MultiSig.sol";
import {MerkleRoot} from "src/merkle/MerkleRoot.sol";
import {Access} from "src/Multisig/Access.sol";
import {PausableUtil} from "src/Multisig/PausableUtil.sol";

contract EvictionVault is Access, PausableUtil, MultiSig, MerkleRoot {
    mapping(address => uint256) public balances;
    uint256 public totalVaultValue;

    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed withdrawer, uint256 amount);
    event Claim(address indexed claimant, uint256 amount);
    event EmergencyWithdraw(address indexed to, uint256 amount);

    constructor(address[] memory _owners) payable Access(_owners) {
        totalVaultValue = msg.value;
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function deposit() external payable _NotPaused {
        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function transferGateway(address to, uint amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "transfer failed");
    }

    function withdraw(uint256 amount) external _NotPaused {
        require(balances[msg.sender] >= amount, "insufficient funds");

        balances[msg.sender] -= amount;

        totalVaultValue -= amount;

        transferGateway(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);
    }

    function setMerkleRoot(bytes32 root) external override onlyOwners {
        merkleRoot = root;
        emit MerkleRootSet(root);
    }

    // claim now has to be when contract isnt paused and must be verified
    function claim(
        bytes32[] calldata proof,
        uint256 amount
    ) external _NotPaused {
        require(verifySignatry(proof, msg.sender, amount), "invalid proof");

        require(!this.isClaimed(msg.sender), "already claimed airdrop");

        require(totalVaultValue >= amount, "insufficient vault balance");

        markClaimed(msg.sender);

        totalVaultValue -= amount;

        transferGateway(msg.sender, amount);

        emit Claim(msg.sender, amount);
    }

    function emergencyWithdrawAll(address to) external onlyOwners _NotPaused {
        require(to != address(0), "Address ) detected");

        uint256 balance = address(this).balance;

        require(balance > 0, "Insufficient balance in vault");

        totalVaultValue = 0; //reset
        transferGateway(to, balance);
        emit EmergencyWithdraw(to, balance);
    }

    // some getters
    function getVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getTotalVaultValue() external view returns (uint256) {
        return totalVaultValue;
    }

    function pauseContract() external onlyOwners {
        pause();
    }

    function unpauseContract() external onlyOwners {
        unpause();
    }

    function getUserBalance(
        address account
    ) external view returns (uint256) {
        return balances[account];
    }
}
