// SPDX-License-Identifier: MIT

/// @title Raffle Extended
/// @author Shehroz K. | Captain Unknown
/// @notice Contains extended read/view functions
pragma solidity ^0.8.21;

import "./Raffle.sol";

contract RaffleExtended {
    RaffleSystem private _raffleContract;

    struct Purchase {
        address wallet;
        uint32 ticketCount;
    }

    constructor(address raffleContractAddress) {
        _raffleContract = RaffleSystem(raffleContractAddress);
    }
    
    /// @notice Get an array of all the on going Raffles.
    /// @return An array of Raffle in on going state.
    function getOnGoing() public view returns (RaffleSystem.Raffle[] memory) {
        uint256[] memory onGoingIds = _raffleContract.getOngoingRaffles();
        RaffleSystem.Raffle[] memory onGoingRaffles = new RaffleSystem.Raffle[](onGoingIds.length);
        
        for (uint256 i = 0; i < onGoingIds.length; i++) {
            (uint32 raffleId, uint128 price, uint64 endTime, uint32 entriesCount, bool payableWithERC20,
            bool hasEnded, address winner, RaffleSystem.Prize memory prize) = _raffleContract.OnGoingRaffles(onGoingIds[i]);

            RaffleSystem.Raffle memory newRaffle = RaffleSystem.Raffle({
                raffleId: raffleId,
                price: price,
                endTime: endTime,
                entriesCount: entriesCount,
                payableWithERC20: payableWithERC20,
                hasEnded: hasEnded,
                winner: winner,
                rafflePrize: RaffleSystem.Prize({
                    NFTContract: prize.NFTContract,
                    NFTTokenId: prize.NFTTokenId
                })
            });
            onGoingRaffles[i] = newRaffle;
        }

        return onGoingRaffles;
    }

    /// @notice Get an array of all the ended Raffles.
    /// @return An array of Raffle in ended state.
    function getEnded() public view returns (RaffleSystem.Raffle[] memory) {
        uint256[] memory endedIds = _raffleContract.getEndedRaffles();
        RaffleSystem.Raffle[] memory endedRaffles = new RaffleSystem.Raffle[](endedIds.length);
        
        for (uint256 i = 0; i < endedIds.length; i++) {
            (uint32 raffleId, uint128 price, uint64 endTime, uint32 entriesCount, bool payableWithERC20,
            bool hasEnded, address winner, RaffleSystem.Prize memory prize) = _raffleContract.OnGoingRaffles(endedIds[i]);

            RaffleSystem.Raffle memory newRaffle = RaffleSystem.Raffle({
                raffleId: raffleId,
                price: price,
                endTime: endTime,
                entriesCount: entriesCount,
                payableWithERC20: payableWithERC20,
                hasEnded: hasEnded,
                winner: winner,
                rafflePrize: RaffleSystem.Prize({
                    NFTContract: prize.NFTContract,
                    NFTTokenId: prize.NFTTokenId
                })
            });
            endedRaffles[i] = newRaffle;
        }

        return endedRaffles;
    }

    /// @notice Gets number of entries held in a Raffle.
    /// @param raffleId ID of the Raffle to get the number of entries for.
    /// @return Number of entries held in the Raffle.
    function getMyEntries(uint256 raffleId) public view returns (uint256) {
        uint256 entriesFound = 0;
        address requestedAddress = msg.sender;
        uint256 length = _raffleContract.getTotalParticipants(raffleId);
        RaffleSystem.Entry memory entry;
        for (uint256 i = 0; i < length; i++) {
            (uint32 lowerBound, uint32 upperBound, address wallet) = _raffleContract.Entries(raffleId, length - (i + 1));
            if (wallet == requestedAddress) {
                entry = RaffleSystem.Entry(lowerBound, upperBound, wallet);
                entriesFound += (entry.upperBound - entry.lowerBound) + 1;
            }
        }

        return entriesFound;
    }

    /// @notice Gets most recent entries bought for a Raffle.
    /// @param raffleId ID of the Raffle to get the number of entries for.
    /// @param query Number of most recent entries to fetch.
    /// @param cursor Cursor for last query (to be used in case multiple reads are performed).
    /// @return An array of most recent entries of query length.
    function getRecentEntries(uint256 raffleId, uint256 query, uint256 cursor) public view returns (Purchase[] memory) {
        uint256 length = _raffleContract.getTotalParticipants(raffleId);
        if (length < query) query = length;
        if (length - cursor < 1) cursor = 0;
        Purchase[] memory lastPurchases = new Purchase[](query);
        RaffleSystem.Entry memory entry;

        for (uint256 i = 0; i < query; i++) {
            (uint32 lowerBound, uint32 upperBound, address wallet) = _raffleContract.Entries(raffleId, (length - cursor) - (i + 1));
            entry = RaffleSystem.Entry(lowerBound, upperBound, wallet);
            Purchase memory purchase;
            purchase.wallet = entry.wallet;
            purchase.ticketCount = (entry.upperBound - entry.lowerBound) + 1;
            lastPurchases[i] = purchase;
        }

        return lastPurchases;
    }
}