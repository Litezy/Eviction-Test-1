// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Access} from "./Access.sol";
import {PauseContractUtil} from "./PauseContractUtil.sol";


contract MultiSig is Access, PauseContractUtil {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
        uint256 submissionTime;
        uint256 executionTime;
    }

    mapping(uint256 => mapping(address => bool)) public confirmed;
    mapping(uint256 => Transaction) public transactions;
    uint256 public txCount;

    uint256 public constant TIMELOCK_DURATION = 1 hours;

    event Submission(uint256 indexed txId);
    event Confirmation(uint256 indexed txId, address indexed owner);
    event Execution(uint256 indexed txId, bool success);
    event ExecutionFailed(uint256 indexed txId, string reason);

    function submitTransaction( address to, uint256 value, bytes calldata data ) external onlyOwners _NotPaused returns (uint256) {
        require(to != address(0), "zero address");
        
        uint256 id = txCount++;
        transactions[id] = Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            confirmations: 1,
            submissionTime: block.timestamp,
            executionTime: 0
        });
        confirmed[id][msg.sender] = true;
        emit Submission(id);
        return id;
    }

    function confirmTransaction(uint256 txId) external onlyOwners _NotPaused {
        Transaction storage txn = transactions[txId];
        require(!txn.executed, "already executed");
        require(!confirmed[txId][msg.sender], "already confirmed");
        
        confirmed[txId][msg.sender] = true;
        txn.confirmations++;
        
        if (txn.confirmations == threshold) {
            txn.executionTime = block.timestamp + TIMELOCK_DURATION;
        }
        emit Confirmation(txId, msg.sender);
    }


   //execute a Tx that the timelock has reached
    function executeTransaction(uint256 txId) external _NotPaused returns (bool) {
        Transaction storage txn = transactions[txId];

        require(txn.confirmations >= threshold, "not enough confirmations to execute");
        
        require(!txn.executed, "already executed");

        require(block.timestamp >= txn.executionTime, "timelock not reached");
        txn.executed = true;
        
        (bool success, bytes memory returnData) = txn.to.call{value: txn.value}(txn.data);
        if (!success) {
            emit ExecutionFailed(txId, string(returnData));
            revert("execution didnt succeed");
        }
        
        emit Execution(txId, success);
        return success;
    }

      
      //get Tx details
    function getTransaction(uint256 txId) external view returns ( address to, uint256 value, bytes memory data, bool executed, uint256 confirmations, uint256 submissionTime, uint256 executionTime ) 
    {
        Transaction storage txn = transactions[txId];
        return (
            txn.to,
            txn.value,
            txn.data,
            txn.executed,
            txn.confirmations,
            txn.submissionTime,
            txn.executionTime
        );
    }


   //get Tx Count
    function getTxnCount() external view returns (uint) {
        return txCount;
    }

    //Check if Tx is confirmed
    function isConfirmed(uint256 txId, address owner) external view returns (bool) {
        return confirmed[txId][owner];
    }

    
}