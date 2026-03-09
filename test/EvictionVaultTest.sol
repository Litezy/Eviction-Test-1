// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MerkleProof} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {EvictionVault} from "src/Eviction/EvictionVault.sol";


contract EvictionVaultTest is Test {
    EvictionVault public evault;

    uint256 public constant Initial_depo = 10 ether;

    address[] public owners;
    
    address public user1 = makeAddr("user1");

    address public user2 = makeAddr("user2");

    address public hacker = makeAddr("hacker");

    bytes32[] public proof;

    bytes32 public merkleRoot;
    

    function setUp() public {
        owners = new address[](5);
        
        owners[0] = makeAddr("owner1");
        owners[1] = makeAddr("owner2");
        owners[2] = makeAddr("owner3");
        owners[3] = makeAddr("owner4");
        owners[4] = makeAddr("owner5");
        //add 10 ether to the vault
        evault = new EvictionVault{value: Initial_depo}(owners);
        bytes32 leaf = keccak256(abi.encodePacked(user1, uint256(1 ether)));
        merkleRoot = keccak256(abi.encodePacked(leaf, leaf));
        vm.prank(owners[0]);
       evault.setMerkleRoot(merkleRoot);
    }


    function testForDeposit() public {
        uint256 depoAmt = 1 ether;
        uint256 initialBalance = evault.getUserBalance(user1);
        //add amount and fetch current balances to ascertain
        vm.deal(user1, depoAmt);
        vm.prank(user1);
        evault.deposit{value: depoAmt}();
        uint256 sumOfInitialBal = initialBalance + depoAmt;
        uint256 sumOfInitalBalAndDepo = Initial_depo + depoAmt;

        assertEq(evault.getUserBalance(user1), sumOfInitialBal );
        assertEq(evault.getTotalVaultValue(), sumOfInitalBalAndDepo);
    }

    function testForWithdrawal() public {
        uint256 depoAmt = 2 ether;
        uint256 withdrawAmount = 0.7 ether;
        //user deposits
        vm.deal(user1, depoAmt);
        vm.prank(user1);
        evault.deposit{value: depoAmt}();
        // balance after deposit
        uint256 initialBalance = evault.getUserBalance(user1);

        vm.prank(user1);
        evault.withdraw(withdrawAmount);
        //check final figures
        uint256 balanceAfterWithdraw = depoAmt - withdrawAmount;

        assertEq(evault.getUserBalance(user1), balanceAfterWithdraw);
    }

   
    function testForReceiveToUseMsgSender() public {
        uint256 sendAmount = 0.5 ether;
        vm.deal(user2, sendAmount);
        vm.prank(user2);
        (bool success,) = address(evault).call{value: sendAmount}("");
        require(success, "transfer failed");
        // balance to be sent to msg.sender and not tx.origin
        assertEq(evault.getUserBalance(user2), sendAmount);
    }

  
    
    function testForClaimWithValidMerkleProof() public {
        bytes32 leaf = keccak256(abi.encodePacked(user1, uint256(1 ether)));
        bytes32[] memory proof = new bytes32[](1);
        // root
        proof[0] = leaf;
    
        uint256 initialVaultValue = evault.getTotalVaultValue();
        uint256 initialUserBalance = user1.balance;
        uint amtDiff = initialVaultValue - 1 ether;
        
        vm.prank(user1);
        evault.claim(proof, 1 ether);
        // assertions 
        assertTrue(evault.isClaimed(user1), "claim not marked");
        assertEq(evault.getTotalVaultValue(),amtDiff);
    }


    function testForNonOwnerCannotSetTheMerkleRoot() public {
        bytes32 newRoot = keccak256("new root");
        //prank hacker
        vm.prank(hacker);
        //expect to fail as non-owner
        vm.expectRevert("not owner");
        evault.setMerkleRoot(newRoot);
        assertEq(evault.merkleRoot(), merkleRoot);
    }

    
    function testForSubmitAndConfirmTx() public {
        address recipient = makeAddr("user3");
        uint256 amount = 0.5 ether;
        
        vm.prank(owners[0]);
        uint256 txnId = evault.submitTransaction(recipient, amount, "");
        
        //get initial count of Txn, which should be 1
        assertEq(evault.getTxnCount(), 1, "tx count not updated");
        
        vm.prank(owners[1]);
        evault.confirmTransaction(txnId);
        
        //destructure to get only confirmations from the get transaction call as its our only interest.
        (,,,,uint256 confirmations,,) = evault.getTransaction(txnId);
        assertEq(confirmations, 2);
    }

    // God abeg make this test no fail tomorrow😢

    
}

    