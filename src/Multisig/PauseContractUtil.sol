// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


contract PauseContractUtil {
    bool public paused;

    event Paused(address indexed by);
    event Unpaused(address indexed by);

    modifier _NotPaused() {
        require(!paused, "paused");
        _;
    }

    modifier _Paused() {
        require(paused, "not paused");
        _;
    }

    function pause() internal {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() internal {
        paused = false;
        emit Unpaused(msg.sender);
    }
}