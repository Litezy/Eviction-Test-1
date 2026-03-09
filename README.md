# EvictionVault

A secure multi-signature vault with Merkle proof claims, built with Foundry.

## What It Does

This vault allows users to deposit, withdraw, and claim airdrops via Merkle proofs. Owners can submit and confirm transactions that require a 1-hour timelock before execution. The contract can be paused in emergencies.

## Vulnerabilities Fixed

The original single-file contract had several critical security issues that have been addressed:

1. **setMerkleRoot** - Was publicly callable by anyone → Now restricted to owners only
2. **emergencyWithdrawAll** - Was publicly accessible (drain risk) → Now requires owner approval  
3. **pause/unpause** - Single owner control → Now requires multi-sig (60% threshold)
4. **receive()** - Was using tx.origin → Now properly uses msg.sender
5. **withdraw & claim** - Was using .transfer (forwarding gas limited to 2300) → Now uses .call for safe ETH transfers
6. **Timelock** - Properly implemented with 1-hour delay between confirmation and execution

## Current Features

- Multi-sig transactions (requires 60% owner approval)
- 1-hour timelock before transaction execution
- Merkle proof-based airdrop claims (prevents double-claiming)
- Emergency pause/unpause by owners
- Deposit/withdraw functionality

## Clone Repo

```bash
git clone https://github.com/Litezy/Eviction-Test-1
```

```bash
forge install
```

## Build

```bash
forge build
```

## Run Tests

```bash
forge test
```



