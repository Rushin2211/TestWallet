//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./mint.sol";

contract WifiNftAuction is MintNFT {
    address public deployer;
    uint256[] public auctionedNFTs;
    struct Auction {
        address payable beneficiary;
        address[] bidders;
        uint256 auctionEndTime;
        uint256 bottomPrice;
        address highestBidder;
        uint256 highestBid;
        mapping(address => uint256) pendingReturns;
        bool ended;
    }
    mapping(uint256 => Auction) public auctions;

    constructor(string memory _name, string memory _symbol)
    MintNFT(_name, _symbol)
    {
        deployer = msg.sender;
    }

    event HighestBidIncreased(uint256 tokenId, address bidder, uint256 amount);
    event AuctionEnded(uint256 tokenId, address winner, uint256 amount);
    event BidWithdrawn(uint256 tokenId, address bidder, uint256 amount);
    event AuctionStarted(uint256 tokenId, uint256 endTime);

    /**
  * @dev Allows the owner of a WiFi NFT to start an auction for that NFT.
* @param _tokenId The token ID of the WiFi NFT.
* @param _durations The NFT being auctioned is available for a long time using WiFi.
* @param _biddingTime The duration for which bidding is allowed.
* @param _beneficiary The address of the beneficiary who will receive the highest bid amount.
* @param _bottomPrice The starting bid amount for the auction.
* @notice Only contract deployers or authorized personnel can call this function.
* @notice The WiFi NFT must not be currently for sale to be auctioned.
* @notice The token ID must be valid and not already in an ongoing auction.
* @notice The bidding time must be greater than 0.
* @dev Sets up the auction parameters and emits an event notifying the start of the auction.
*/
    function startAuction(
        uint256 _tokenId,
        uint256 _durations,
        uint256 _biddingTime,
        address payable _beneficiary,
        uint256 _bottomPrice
    ) public {
        require(
            isAuthorized(msg.sender) && balanceOf(msg.sender, _tokenId) >= 1,
            "Only contract deployers or authorized personnel can call"
        );

        require(
            nftMetadata[_tokenId].price == 0,
            "The wifiNft is for sale, can not be auctioned"
        );
        require(
            _tokenId < _getNextTokenId() && _tokenId > 0,
            "Token ID should be less than nextTokenId and greater than 0"
        );
        require(
            auctions[_tokenId].auctionEndTime == 0,
            "Auction for this NFT is already in progress"
        );
        require(_biddingTime > 0, "Bidding time should be greater than 0");
        nftMetadata[_tokenId].durations = _durations;
        auctions[_tokenId].beneficiary = _beneficiary;
        auctions[_tokenId].bottomPrice = _bottomPrice;
        auctions[_tokenId].auctionEndTime = block.timestamp + _biddingTime;
        auctions[_tokenId].ended = false;
        auctionedNFTs.push(_tokenId);
        emit AuctionStarted(_tokenId, auctions[_tokenId].auctionEndTime);
    }

    /**
     * @dev Allows a user to place a bid in the auction for a specific WiFi NFT.
     * @param _tokenId The token ID of the WiFi NFT.
     * @notice The bid amount must be greater than the starting bid for the auction.
     * @notice The bidder cannot be the highest bidder.
     * @notice The bidder cannot be the deployer or an authorized participant in the auction.
     * @notice The bid amount is added to the pending returns of the previous highest bidder.
     * @notice If the bid amount becomes the new highest bid, the pending returns of the previous highest bidder are reset to zero.
     * @notice The bidder becomes the new highest bidder.
     * @notice Emits an event notifying of an increased bid amount.
     */
    function bid(uint256 _tokenId) public payable {
        require(
            block.timestamp <= auctions[_tokenId].auctionEndTime,
            "Auction already ended."
        );
        require(
            msg.value > auctions[_tokenId].bottomPrice,
            "Your bid must be greater than the starting bid"
        );
        require(
            msg.value + auctions[_tokenId].pendingReturns[msg.sender] >
            auctions[_tokenId].highestBid,
            "There already is a higher bid."
        );
        require(
            msg.sender != auctions[_tokenId].highestBidder,
            "You are already the highest bidder"
        );
        require(
            msg.sender != deployer && !isAuthorized(msg.sender),
            "Auction contract deployers or grantee cannot participate in the auction"
        );

        auctions[_tokenId].pendingReturns[
        auctions[_tokenId].highestBidder
        ] += auctions[_tokenId].highestBid;
        auctions[_tokenId].bidders.push(msg.sender);

        auctions[_tokenId].highestBid =
        msg.value +
        auctions[_tokenId].pendingReturns[msg.sender];
        auctions[_tokenId].pendingReturns[msg.sender] = 0;
        auctions[_tokenId].highestBidder = msg.sender;
        emit HighestBidIncreased(
            _tokenId,
            msg.sender,
            auctions[_tokenId].highestBid
        );
    }

    /**
     * @dev Allows a bidder to withdraw their bid amount from the auction for a specific WiFi NFT.
     * @param _tokenId The token ID of the WiFi NFT.
     * @return A boolean value indicating whether the bid amount withdrawal was successful or not.
     * @notice The bidder must not be the highest bidder.
     * @notice The bidder can only withdraw their own bid amount.
     * @notice Emits an event notifying of a bid amount withdrawal.
     */
    function withdraw(uint256 _tokenId) public returns (bool) {
        require(
            msg.sender != auctions[_tokenId].highestBidder,
            "You are the highest bidder and cannot withdraw your bid"
        );

        uint256 amount = auctions[_tokenId].pendingReturns[msg.sender];
        if (amount > 0) {
            auctions[_tokenId].pendingReturns[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)) {
                auctions[_tokenId].pendingReturns[msg.sender] = amount;
                return false;
            }

            emit BidWithdrawn(_tokenId, msg.sender, amount);
            return true;
        }
        return false;
    }

    /**
     * @dev Ends the auction for a specific WiFi NFT.
     * @param _tokenId The token ID of the WiFi NFT.
     * @notice Can only be called by the owner of the NFT.
     * @notice Transfers the highest bid amount to the beneficiary.
     * @notice Emits an event notifying of the end of the auction.
     * @notice Resets the bidding information for the auction.
     */
    function auctionEnd(uint256 _tokenId) public {
        require(
            block.timestamp >= auctions[_tokenId].auctionEndTime,
            "Auction not yet ended."
        );
        require(
            !auctions[_tokenId].ended,
            "auctionEnd has already been called."
        );
        require(
            balanceOf(msg.sender, _tokenId) >= 1,
            "Only the owner of the NFT can end the auction"
        );
        require(
            auctions[_tokenId].auctionEndTime!=0,
            "The auction has not started yet"
        );
        auctions[_tokenId].ended = true;

        emit AuctionEnded(
            _tokenId,
            auctions[_tokenId].highestBidder,
            auctions[_tokenId].highestBid
        );

        for (uint256 i = 0; i < auctions[_tokenId].bidders.length; i++) {
            if (
                auctions[_tokenId].bidders[i] !=
                auctions[_tokenId].highestBidder
            ) {
                uint256 amount = auctions[_tokenId].pendingReturns[
                auctions[_tokenId].bidders[i]
                ];
                if (amount > 0) {
                    auctions[_tokenId].pendingReturns[
                    auctions[_tokenId].bidders[i]
                    ] = 0;
                    if (!payable(auctions[_tokenId].bidders[i]).send(amount)) {
                        auctions[_tokenId].pendingReturns[
                        auctions[_tokenId].bidders[i]
                        ] = amount;
                    }

                    emit BidWithdrawn(
                        _tokenId,
                        auctions[_tokenId].bidders[i],
                        amount
                    );
                }
            }
        }

        if (auctions[_tokenId].highestBidder != address(0)) {
            if (auctions[_tokenId].highestBid > 0) {
                auctions[_tokenId].beneficiary.transfer(
                    auctions[_tokenId].highestBid
                );
                sell(msg.sender, auctions[_tokenId].highestBidder, _tokenId);
            }
        }
        //Reset bidding information
        auctions[_tokenId].highestBidder = address(0);
        auctions[_tokenId].beneficiary = payable(address(0));
        auctions[_tokenId].highestBid = 0;
        auctions[_tokenId].auctionEndTime = 0;
        auctions[_tokenId].bottomPrice = 0;
        nftMetadata[_tokenId].durations = 0;
    }
}
