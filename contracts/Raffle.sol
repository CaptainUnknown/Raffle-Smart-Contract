// SPDX-License-Identifier: MIT

/// @title An ERC-721 Raffle System Smart Contract
/// @author Shehroz K. | Captain Unknown
/// @notice Contract can handle multiple concurrent Raffles.
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IERC20{
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract RaffleSystem is Ownable, Initializable {
    using Counters for Counters.Counter;
    Counters.Counter public currentRaffleId;

    struct Entry {
        uint32 lowerBound;
        uint32 upperBound;
        address wallet;
    }

    struct Prize {
        address NFTContract;
        uint32 NFTTokenId;
    }

    struct Raffle {
        uint32 raffleId;
        uint128 price;
        uint64 endTime;
        uint32 entriesCount;
        bool payableWithERC20;
        bool hasEnded;
        address winner;
        Prize rafflePrize;
    }

    // Context
    address public immutable token;
    uint8 public immutable maxEntriesPerPurchase;

    mapping (address => bool) private Admin;
    mapping (uint256 => Raffle) public OnGoingRaffles;
    mapping (uint256 => Entry[]) public Entries;

    event RaffleStarted(uint256 indexed raffleId, uint256 price, uint256 endTime, Prize rafflePrize);
    event Winner(uint256 indexed raffleId, address winner);

    /// @param _token ERC20 Token to be used as for buying entries.
    /// @param _maxEntriesPerPurchase Cap for entries per single buy transaction.
    constructor(address _token, uint8 _maxEntriesPerPurchase) {
        token = _token;
        maxEntriesPerPurchase = _maxEntriesPerPurchase;
        _disableInitializers();
    }

    /// @notice Starts a Raffle (Admin needs to own the prize NFT).
    /// @param _price Price for a single entry.
    /// @param _payableWithERC20 Whether user can pay in ERC20 or Eth.
    /// @param _duration Duration to run the raffle for.
    /// @param _prizeNFTContract SC Address of the Prize NFT.
    /// @param _prizeNFTTokenId TokenID of the Prize NFT.
    function startRaffle(uint128 _price, bool _payableWithERC20, uint64 _duration, address _prizeNFTContract, uint32 _prizeNFTTokenId) public {
        require(Admin[msg.sender], "Permission denied");
        uint64 _endTime = uint64(block.timestamp) + _duration;

        Raffle memory newRaffle = Raffle({
            raffleId: uint32(currentRaffleId.current()),
            price: _price,
            endTime: _endTime,
            entriesCount: 0,
            payableWithERC20: _payableWithERC20,
            hasEnded: false,
            winner: address(0),
            rafflePrize: Prize({
                NFTContract: _prizeNFTContract,
                NFTTokenId: _prizeNFTTokenId
            })
        });
        OnGoingRaffles[currentRaffleId.current()] = newRaffle;
        currentRaffleId.increment();

        IERC721(_prizeNFTContract).transferFrom(msg.sender, address(this), _prizeNFTTokenId);

        emit RaffleStarted(newRaffle.raffleId, _price, newRaffle.endTime, newRaffle.rafflePrize);
    }

    /// @notice For the end-user to buy an entry (or multiple entries) in a Raffle.
    /// @dev Stores entries bought as a range specified by a lowerBound and a upperBound along with the user address.
    /// @param _RaffleId Raffle ID to buy the entries for.
    /// @param entryCount Number of entries to buy.
    function buyTicket(uint32 _RaffleId, uint32 entryCount) public payable {
        require(raffleExists(_RaffleId), "Invalid ID");
        Raffle storage raffle = OnGoingRaffles[_RaffleId];

        require(block.timestamp < raffle.endTime, "Raffle entry time ended");
        require(!raffle.hasEnded, "Raffle has ended");
        require(entryCount > 0, "Zero entries requested");
        require(entryCount <= maxEntriesPerPurchase, "Exceeds max entries limit");

        if (raffle.payableWithERC20) {
            require(IERC20(token).transferFrom(msg.sender, address(this), raffle.price * entryCount), "ERC20 Transfer Failed");
        } else {
            require(raffle.price * entryCount == msg.value, "Incorrect amount");
        }

        Entry[] storage raffleEntries = Entries[_RaffleId];
        Entry memory lastEntry = raffleEntries.length > 0 ? raffleEntries[raffleEntries.length - 1] : Entry(0, 0, address(0));
        if (lastEntry.wallet == msg.sender) {
            raffleEntries[raffleEntries.length - 1].upperBound += entryCount;
        } else {
            uint32 newUpperBound = lastEntry.upperBound + entryCount;
            raffleEntries.push(Entry(lastEntry.upperBound + 1, newUpperBound, msg.sender));
        }
        raffle.entriesCount += entryCount;
    }

    /// @notice Ends a Raffle (Can only be called after the _duration has elapsed).
    /// @dev Uses a binary search to look for the winning entry.
    /// @param _RaffleId ID of the Raffle to end.
    /// @param seed A random winning entry.
    function endRaffle(uint32 _RaffleId, uint256 seed) public {
        require(msg.sender == owner() || Admin[msg.sender], "Permission denied");

        Raffle storage raffle = OnGoingRaffles[_RaffleId];
        require(raffleExists(_RaffleId), "Invalid ID");
        require(block.timestamp >= raffle.endTime, "Raffle hasn't ended yet");
        require(!raffle.hasEnded, "Raffle already ended");
        raffle.hasEnded = true;

        if (raffle.entriesCount == 0) {
            IERC721(raffle.rafflePrize.NFTContract).safeTransferFrom(address(this), owner(), raffle.rafflePrize.NFTTokenId);
            emit Winner(_RaffleId, address(0));
        } else {
            Entry[] storage raffleEntries = Entries[_RaffleId];
            uint256 winnerIndex = seed % raffle.entriesCount;

            uint256 left = 0;
            uint256 right = raffleEntries.length - 1;
            while (left < right) {
                uint256 mid = (left + right) / 2;

                if (winnerIndex < raffleEntries[mid].lowerBound) {
                    right = mid - 1;
                } else if (winnerIndex >= raffleEntries[mid].upperBound) {
                    left = mid + 1;
                } else {
                    left = mid;
                    break;
                }
            }

            address winner = raffleEntries[left].wallet;
            raffle.winner = winner;

            IERC721(raffle.rafflePrize.NFTContract).safeTransferFrom(address(this), raffle.winner, raffle.rafflePrize.NFTTokenId);
            emit Winner(_RaffleId, winner);
        }
    }

    // Utilities

    /// @notice Withdraws all the funds (including ERC20 Tokens & Eth) from the contract.
    function withdrawAll() public payable onlyOwner {
        require(address(this).balance > 0 || IERC20(token).balanceOf(address(this)) > 0, "Out of funds");
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        payable(msg.sender).transfer(address(this).balance);
    }

    /// @notice Withdraws specified amount of Eth from the contract.
    /// @param amount The amount of Eth to withdraw.
    function withdrawEth(uint256 amount) public payable onlyOwner {
        require(address(this).balance >= amount, "Amount exceeds balance");
        payable(msg.sender).transfer(amount);
    }

    /// @notice Withdraws specified amount ERC20 tokens from the contract.
    /// @param amount The amount of ERC20 tokens to withdraw.
    function withdrawToken(uint256 amount) public payable onlyOwner {
        require(IERC20(token).balanceOf(address(this)) >= amount, "Amount exceeds balance");
        IERC20(token).transfer(msg.sender, amount);
    }

    /// @notice Whitelists the provided address as an admin.
    /// @param _admin The address to whitelist as an admin.
    function addAdmin(address _admin) public onlyOwner {
        Admin[_admin] = true;
    }

    /// @notice Removes the provided address from an admin role.
    /// @param _admin The address to remove from admin.
    function removeAdmin(address _admin) public onlyOwner {
        Admin[_admin] = false;
    }

    // Read functions

    /// @notice Checks whether the Raffle exists with provided ID.
    /// @param _RaffleId The RaffleId to validate.
    /// @return Whether Raffle exists.
    function raffleExists(uint32 _RaffleId) public view returns (bool) {
        return _RaffleId < currentRaffleId.current();
    }

    /// @notice Gets number of total participants in a Raffle.
    /// @param _RaffleId The RaffleId to get total participants of.
    /// @return Number of participants in the Raffle.
    function getTotalParticipants(uint256 _RaffleId) public view returns (uint256) {
        return Entries[_RaffleId].length;
    }

    /// @notice Gets all the IDs of on going Raffles.
    /// @return An Array containing IDs of on going Raffles.
    function getOngoingRaffles() public view returns (uint256[] memory) {
        uint256[] memory raffleIds = new uint256[](currentRaffleId.current());
        uint256 count = 0;
        for (uint256 i = 0; i < currentRaffleId.current(); i++) {
            if (!OnGoingRaffles[i].hasEnded) {
                raffleIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = raffleIds[i];
        }
        return result;
    }

    /// @notice Gets all the IDs of ended Raffles.
    /// @return An Array containing IDs of ended Raffles.
    function getEndedRaffles() public view returns (uint256[] memory) {
        uint256[] memory raffleIds = new uint256[](currentRaffleId.current());
        uint256 count = 0;
        for (uint256 i = 0; i < currentRaffleId.current(); i++) {
            if (OnGoingRaffles[i].hasEnded) {
                raffleIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = raffleIds[i];
        }
        return result;
    }
}