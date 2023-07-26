# ERC721 Raffle System 📜 ![ERC721 Raffle System](https://img.shields.io/badge/1.0.0-brightgreen)

This is a smart contract that implements an ERC-721 Raffle System. It allows for the creation and management of multiple concurrent raffles. Users can buy tickets for a raffle, and at the end of the raffle, a winner is selected using a binary search algorithm.

![Code Snippet](https://i.imgur.com/1PfU32X.png)

### Prerequisites

This contract requires the following dependencies:

- OpenZeppelin Contracts v4.3.0
- OpenZeppelin Contracts-upgradeable v4.3.0

## Usage 📐

1. Deploy RaffleSystem & RaffleExtended contracts.
2. Initialize the RaffleSystem contract with the following parameters:
   - `token`: The address of the ERC20 token used for payment.
   - `maxEntriesPerPurchase`: The maximum number of entries a user can purchase in a single transaction.
3. The contract owner can add or remove admin addresses using the `addAdmin` and `removeAdmin` functions.
4. Admins can start a new raffle using the `startRaffle` function. They need to own the prize NFT for the raffle.
   - Parameters:
     - `price`: The price for a single entry in the raffle.
     - `payableWithERC20`: Whether users can pay with ERC20 tokens or Ether.
     - `duration`: The duration of the raffle in seconds.
     - `prizeNFTContract`: The address of the prize NFT contract.
     - `prizeNFTTokenId`: The token ID of the prize NFT.
5. Users can buy tickets for a raffle using the `buyTicket` function.
   - Parameters:
     - `raffleId`: The ID of the raffle to buy tickets for.
     - `entryCount`: The number of entries to buy.
6. The raffle owner or admin can end a raffle using the `endRaffle` function.
   - Parameters:
     - `raffleId`: The ID of the raffle to end.
     - `seed`: A random number used to select the winning entry.
7. The contract owner can withdraw all funds from the contract using the `withdrawAll` function.
8. The contract owner can withdraw ERC20 tokens from the contract using the `withdrawToken` function.
   - Parameters:
     - `amount`: The amount of ERC20 tokens to withdraw.

## Functions of `RaffleSystem` 💾

#### `startRaffle(uint128 _price, bool _payableWithERC20, uint64 _duration, address _prizeNFTContract, uint32 _prizeNFTTokenId)`

```solidity
function startRaffle(uint128 _price, bool _payableWithERC20, uint64 _duration, address _prizeNFTContract, uint32 _prizeNFTTokenId) public
```

- Description: Starts a new raffle.
- Parameters:
  - `_price`: The price for a single entry in the raffle.
  - `_payableWithERC20`: Whether users can pay with ERC20 tokens or Ether.
  - `_duration`: The duration of the raffle in seconds.
  - `_prizeNFTContract`: The address of the prize NFT contract.
  - `_prizeNFTTokenId`: The token ID of the prize NFT.

#### `endRaffle(uint32 _RaffleId, uint256 seed)`

```solidity
function endRaffle(uint32 _RaffleId, uint256 seed) public
```

- Description: Ends a raffle and determines the winner.
- Parameters:
  - `_RaffleId`: The ID of the raffle to end.
  - `seed`: A random winning entry.

#### `buyTicket(uint32 _RaffleId, uint32 entryCount)`

```solidity
function buyTicket(uint32 _RaffleId, uint32 entryCount) public payable
```

- Description: Allows users to buy entries in a raffle.
- Parameters:
  - `_RaffleId`: The ID of the raffle to buy entries for.
  - `entryCount`: The number of entries to buy.

#### `withdrawAll()`

```solidity
function withdrawAll() public payable onlyOwner
```

- Description: Withdraws all the funds (including ERC20 tokens and Ether) from the contract.

#### `withdrawEth(uint256 amount)`

```solidity
function withdrawEth(uint256 amount) public payable onlyOwner
```

- Description: Withdraws the specified amount of Ether from the contract.
- Parameters:
  - `amount`: The amount of Ether to withdraw.

#### `withdrawToken(uint256 amount)`

```solidity
function withdrawToken(uint256 amount) public payable onlyOwner
```

- Description: Withdraws the specified amount of ERC20 tokens from the contract.
- Parameters:
  - `amount`: The amount of ERC20 tokens to withdraw.

#### `addAdmin(address _admin)`

```solidity
function addAdmin(address _admin) public onlyOwner
```

- Description: Whitelists the provided address as an admin.
- Parameters:
  - `_admin`: The address to whitelist as an admin.

#### `removeAdmin(address _admin)`

```solidity
function removeAdmin(address _admin) public onlyOwner
```

- Description: Removes the provided address from the admin role.
- Parameters:
  - `_admin`: The address to remove from admin.

#### `raffleExists(uint32 _RaffleId)`

```solidity
function raffleExists(uint32 _RaffleId) public view returns (bool)
```

- Description: Checks whether the raffle exists with the provided ID.
- Parameters:
  - `_RaffleId`: The ID of the raffle to validate.
- Returns: Whether the raffle exists.

#### `getTotalParticipants(uint256 _RaffleId)`

```solidity
function getTotalParticipants(uint256 _RaffleId) public view returns (uint256)
```

- Description: Gets the number of total participants in a raffle.
- Parameters:
  - `_RaffleId`: The ID of the raffle to get the total participants of.
- Returns: The number of participants in the raffle.

#### `getOngoingRaffles()`

```solidity
function getOngoingRaffles() public view returns (uint256[] memory)
```

- Description: Gets all the IDs of ongoing raffles.
- Returns: An array containing the IDs of ongoing raffles.

#### `getEndedRaffles()`

```solidity
function getEndedRaffles() public view returns (uint256[] memory)
```

- Description: Gets all the IDs of ended raffles.
- Returns: An array containing the IDs of ended raffles.

## Functions of `RaffleExtended` 💾

#### `getOnGoing()`

```solidity
function getOnGoing() public view returns (RaffleSystem.Raffle[] memory)
```

- Description: Retrieves an array of all ongoing raffles.
- Returns: An array of RaffleSystem.Raffle structs representing the ongoing raffles.

#### `getEnded()`

```solidity
function getEnded() public view returns (RaffleSystem.Raffle[] memory)
```

- Description: Retrieves an array of all ended raffles.
- Returns: An array of RaffleSystem.Raffle structs representing the ended raffles.

#### `getMyEntries(uint256 raffleId)`

```solidity
function getMyEntries(uint256 raffleId) public view returns (uint256)
```

- Description: Retrieves the number of entries held by the caller in a specific raffle.
- Parameters:
  - `raffleId`: The ID of the raffle to get the number of entries for.
- Returns: The number of entries held by the caller in the specified raffle.

#### `getRecentEntries(uint256 raffleId, uint256 query, uint256 cursor)`

```solidity
function getRecentEntries(uint256 raffleId, uint256 query, uint256 cursor) public view returns (Purchase[] memory)
```

- Description: Retrieves an array of the most recent entries bought for a specific raffle.
- Parameters:
  - `raffleId`: The ID of the raffle to get the entries for.
  - `query`: The number of most recent entries to fetch.
  - `cursor`: The cursor for the last query (to be used in case multiple reads are performed).
- Returns: An array of Purchase structs representing the most recent entries.


## Events ⏰

The contract emits the following events:

- `RaffleStarted(uint256 indexed raffleId, uint256 price, uint256 endTime, Prize rafflePrize)`: Triggered when a new raffle is started.
- `Winner(uint256 indexed raffleId, address winner)`: Triggered when a raffle is ended and a winner is selected.

## TODOs ✅

- [x] ERC20 Support
- [x] Cursor for `getRecentEntries` function in `RaffleExtended`.
- [ ] Support for ERC1155 Raffles
- [ ] Support for Eth Raffles
