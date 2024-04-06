// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./auction.sol";

contract SonyClient is WifiNftAuction {
    constructor(string memory _name, string memory _symbol)
    WifiNftAuction(_name, _symbol)
    {}

    struct NFTAuctionInfo {
        //Array of NFTs currently being auctioned
        uint256[] tokenIds;
        //Corresponding AP ID array
        string[] AP_IDs;
        //Corresponding beneficiary address array
        address[] beneficiaryList;
        //Corresponding bidding starting price array
        uint256[] bottomPriceList;
        //The corresponding array of highest bidders
        address[] highestBidderList;
        //Corresponding WiFi NFT highest bid array
        uint256[] highestBidList;
        //Corresponding auction end time array, unix time
        uint256[] auctionEndTimeList;
        //Corresponding array of usable WiFi duration, unix time
        uint256[] durationList;
        //The corresponding user bids for this NFT and waits for the refund amount.
        uint256[] pendingReturnList;
    }

    /**
     * @dev Retrieves information about the current auctioned WiFi NFTs.
     * @param _address The address of the user querying the information.
     * @return NFTAuctionInfo containing arrays of tokenIds, AP_IDs, beneficiaryList,
     * bottomPriceList, highestBidderList, highestBidList, auctionEndTimeList,
     * durationList, and pendingReturnList for the active auctions.
     */
    function getCurrentAuctionNFTs(address _address)
    external
    view
    returns (NFTAuctionInfo memory)
    {
        uint256[] memory tokenIds = new uint256[](auctionedNFTs.length);
        uint256 count = 0;
        for (uint256 i = 0; i < auctionedNFTs.length; i++) {
            if (!auctions[auctionedNFTs[i]].ended) {
                tokenIds[count] = auctionedNFTs[i];
                count++;
            }
        }
        uint256[] memory tokenIdList = new uint256[](count);
        string[] memory AP_IDList = new string[](count);
        address[] memory beneficiaryList = new address[](count);
        uint256[] memory bottomPriceList = new uint256[](count);
        address[] memory highestBidderList = new address[](count);
        uint256[] memory highestBidList = new uint256[](count);
        uint256[] memory auctionEndTimeList = new uint256[](count);
        uint256[] memory durationList = new uint256[](count);
        uint256[] memory pendingReturnList = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            tokenIdList[i] = tokenIds[i];
            AP_IDList[i] = nftMetadata[tokenIds[i]].AP_ID;
            beneficiaryList[i] = auctions[tokenIds[i]].beneficiary;
            bottomPriceList[i] = auctions[tokenIds[i]].bottomPrice;
            highestBidderList[i] = auctions[tokenIds[i]].highestBidder;
            highestBidList[i] = auctions[tokenIds[i]].highestBid;
            auctionEndTimeList[i] = auctions[tokenIds[i]].auctionEndTime;
            durationList[i] = nftMetadata[tokenIds[i]].durations;
            pendingReturnList[i] = auctions[tokenIds[i]].pendingReturns[
            _address
            ];
        }
        return
        NFTAuctionInfo(
            tokenIdList,
            AP_IDList,
            beneficiaryList,
            bottomPriceList,
            highestBidderList,
            highestBidList,
            auctionEndTimeList,
            durationList,
            pendingReturnList
        );
    }

    /**
     * @dev Returns the bottom price of the specified token auction.
     * @param tokenId The ID of the token to get the bottom price for.
     * @return The bottom price of the specified token auction.
     */
    function getBottomPrice(uint256 tokenId) public view returns (uint256) {
        return auctions[tokenId].bottomPrice;
    }

    /**
     * @dev Returns the beneficiary address of the specified token auction.
     * @param tokenId The ID of the token to get the beneficiary for.
     * @return The beneficiary address of the specified token auction.
     */
    function getBeneficiary(uint256 tokenId) public view returns (address) {
        return auctions[tokenId].beneficiary;
    }

    /**
     * @dev Returns the address of the highest bidder for the specified token auction.
     * @param tokenId The ID of the WiFi NFT.
     * @return The address of the highest bidder for the token auction.
     */
    function getHighestBidder(uint256 tokenId) public view returns (address) {
        return auctions[tokenId].highestBidder;
    }

    /**
     * @dev Returns the highest bid amount for the specified token auction.
     * @param tokenId The ID of the WiFi NFT.
     * @return The highest bid amount for the token auction.
     */
    function getHighestBid(uint256 tokenId) public view returns (uint256) {
        return auctions[tokenId].highestBid;
    }

    // function getPendingReturn(uint256 tokenId, address _address)
    //     public
    //     view
    //     returns (uint256)
    // {
    //     return auctions[tokenId].pendingReturns[_address];
    // }
}
