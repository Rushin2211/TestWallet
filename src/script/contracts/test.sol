/*
* @作者：周志贤
* @日期：2024/04/28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MyNFT is ERC721 {
    uint public tokenIdCounter;
    uint[] public tokenIdList;
    uint[] public auctionNFTList;
    uint[] public availableAuctionList;
    struct FromTokenIdGetNFTData {
        uint tokenId;
        address Owner;
    }
    mapping(uint => FromTokenIdGetNFTData) public fromTokenIdGetNFTData;

    mapping(address => uint[]) public tokenIdListOfAccount;

    struct NFTAuctionInfo {
        address payable beneficiary;
        address[] bidder;
        uint auctionEndTime;
        uint bottomPrice;
        address highestBidder;
        uint highestBid;
        mapping(address => uint) pendingReturns;
        bool ended;
    }
    mapping(uint => NFTAuctionInfo) public nftAuctionInfo;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        tokenIdCounter = 1;
    }

    // NFT铸造事件
    event MintNFT(address _from, address _to, uint _tokenId);

    // NFT转移事件
    event TransferNFT(address _from, address _to, uint _tokenId);

    // NFT拍卖开始事件
    event AuctionStart(uint _token, uint _bottomPrice, uint _auctionEndTime);

    /*
     * @功能：铸造 ERC-721 代币（NFT）
     * @参数（_to）：NFT 接收者的以太坊地址
     * @事件：MintNFT
     */
    function mintERC721Token(address _to) public {
        uint256 newTokenId = tokenIdCounter;
        _mint(_to, newTokenId);
        tokenIdCounter ++;
        fromTokenIdGetNFTData[newTokenId].tokenId = newTokenId;
        fromTokenIdGetNFTData[newTokenId].Owner = msg.sender;
        tokenIdListOfAccount[_to].push(newTokenId);
        tokenIdList.push(newTokenId);

        emit MintNFT(address(0), _to, newTokenId);
    }

    /*
    * @功能：转移ERC-721代币
    * @参数（_to）：接收者地址
    * @参数（_tokenId）：要转移的NFT的tokenId
    * @事件：TransferNFT
    */
    function transferERC721Token(address _to, uint _tokenId) public {
        require(msg.sender == ownerOf(_tokenId), "Caller is not the owner of the NFT!");
        _transfer(msg.sender, _to, _tokenId);
        removeValue(_tokenId, msg.sender);
        removeValueFromAuctionNFTList(_tokenId);
        tokenIdListOfAccount[_to].push(_tokenId);

        emit TransferNFT(msg.sender, _to, _tokenId);
    }

    /*
    * @功能：查询NFT的拥有者
    * @参数（_tokenId）：要查询的NFT的tokenId
    * @返回：NFT拥有者的以太坊地址
    */
    function ownerOfNFT(uint _tokenId) public view returns(address) {
        return ownerOf(_tokenId);
    }

    /*
    * @功能：查询以太坊地址下的所有NFT的tokenId
    * @参数（_address）：要查询的以太坊地址
    * @返回：该地址下所拥有的NFT的tokenId
    */
    function getAccountNFTInfo(address _address) public view returns(uint[] memory) {
        return tokenIdListOfAccount[_address];
    }

    /*
    * @功能：删除数组中的指定元素
    * @参数（_value）：需要删除的元素
    * @参数（_address）：以太坊地址
    */
    function removeValue(uint _value, address _address) public {
        for (uint i = 0; i < tokenIdListOfAccount[_address].length; i++) {
            if (tokenIdListOfAccount[_address][i] == _value) {
                for (uint j = i; j < tokenIdListOfAccount[_address].length - 1; j++) {
                    tokenIdListOfAccount[_address][j] = tokenIdListOfAccount[_address][j + 1];
                }
                tokenIdListOfAccount[_address].pop();
            }
        }
    }

    /*
    * @功能：删除数组中的指定元素
    * @参数（_value）：需要删除的元素
    */
    function removeValueFromAuctionNFTList(uint _value) public {
        for (uint i = 0; i < auctionNFTList.length; i++) {
            if (auctionNFTList[i] == _value) {
                for (uint j = i; j < auctionNFTList.length - 1; j++) {
                    auctionNFTList[j] = auctionNFTList[j + 1];
                }
                auctionNFTList.pop();
            }
        }
    }

    /*
    * @功能：开始NFT拍卖
    * @参数（_tokenId）：用于拍卖的NFT的ID
    * @参数（_biddingDuration）：拍卖持续时间
    * @参数（_beneficiary）：受益人
    * @参数（_bottomPrice）：底价
    * @事件：AuctionStart
    */
    function startAuction(
        uint _tokenId,
        uint _biddingDuration,
        address payable _beneficiary,
        uint _bottomPrice
    ) public {
        nftAuctionInfo[_tokenId].auctionEndTime = block.timestamp + _biddingDuration;
        nftAuctionInfo[_tokenId].beneficiary = _beneficiary;
        nftAuctionInfo[_tokenId].bottomPrice = _bottomPrice;
        nftAuctionInfo[_tokenId].ended = true;
        auctionNFTList.push(_tokenId);

        emit AuctionStart(_tokenId, _bottomPrice, nftAuctionInfo[_tokenId].auctionEndTime);
    }

    /*
    * @功能：查询正在拍卖的NFT的tokenId
    * @返回：正在拍卖的NFT的tokenId
    */
    function getAuctionNFTList() public view returns(uint[] memory) {
        return auctionNFTList;
    }
}