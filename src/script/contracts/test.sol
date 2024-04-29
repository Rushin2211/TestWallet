/*
* @作者：周志贤
* @日期：2024/04/28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MyNFT is ERC721 {
    uint public tokenIdCounter;
    address public immutable owner;
    uint[] public tokenIdList;
    uint[] public auctionNFTList;
    uint[] public availableAuctionList;
    mapping(address => bool) public authorized;
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
        bool isAuction;
        bool ended;
    }
    mapping(uint => NFTAuctionInfo) public nftAuctionInfo;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        owner = msg.sender;
        authorized[owner] = true;
        tokenIdCounter = 1;
    }

    // NFT铸造事件
    event MintNFT(address _from, address _to, uint _tokenId);

    // NFT转移事件
    event TransferNFT(address _from, address _to, uint _tokenId);

    // NFT拍卖开始事件
    event AuctionStart(uint _token, uint _bottomPrice, uint _auctionEndTime);

    // 最高出价更新事件
    event HigestBidRefresh(uint _tokenId, uint _highestBid, address _highestBidder);

    // 修饰函数，仅管理员可调用
    modifier onlyAdmin() {
        require(authorized[msg.sender] == true, "Only Admin can call this function");
        _;
    }

    // 修饰函数，仅普通用户可调用
    modifier onlyRegularUser() {
        require(msg.sender != owner && authorized[msg.sender] == false, "Only regular user can all this function");
        _;
    }

    /*
     * @功能：铸造 ERC-721 代币（NFT）
     * @参数（_to）：NFT 接收者的以太坊地址
     * @事件：MintNFT
     */
    function mintERC721Token(address _to) public onlyAdmin {
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
    function transferERC721Token(address _to, uint _tokenId) public onlyAdmin {
        require(msg.sender == ownerOf(_tokenId), "Caller is not the owner of the NFT!");
        _transfer(msg.sender, _to, _tokenId);
        removeValue(_tokenId, msg.sender);
        removeValueFromAuctionNFTList(_tokenId);
        tokenIdListOfAccount[_to].push(_tokenId);
        nftAuctionInfo[_tokenId].isAuction = false;
        nftAuctionInfo[_tokenId].ended = true;

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
    ) public onlyAdmin {
        require(nftAuctionInfo[_tokenId].auctionEndTime == 0, "Auction for this NFT is already in progress");

        nftAuctionInfo[_tokenId].auctionEndTime = block.timestamp + _biddingDuration;
        nftAuctionInfo[_tokenId].beneficiary = _beneficiary;
        nftAuctionInfo[_tokenId].bottomPrice = _bottomPrice;
        nftAuctionInfo[_tokenId].isAuction = true;
        nftAuctionInfo[_tokenId].ended = false;
        auctionNFTList.push(_tokenId);

        emit AuctionStart(_tokenId, _bottomPrice, nftAuctionInfo[_tokenId].auctionEndTime);
    }


    /*
    * @功能：出价
    * @参数（_tokenId）：出价对应的NFT的ID
    * @事件：HigestBidRefresh
    */
    function bid(uint _tokenId) public payable onlyRegularUser {
        require(block.timestamp <= nftAuctionInfo[_tokenId].auctionEndTime, "Auction already ended.");
        require(nftAuctionInfo[_tokenId].isAuction == true, "This NFT has not yet started auctioning.");
        require(nftAuctionInfo[_tokenId].ended == false, "The auction of this NFT has ended.");

        // 更新上一个最高出价者的待退款金额
        address highestBidder = nftAuctionInfo[_tokenId].highestBidder;
        uint highestBid = nftAuctionInfo[_tokenId].highestBid;
        nftAuctionInfo[_tokenId].pendingReturns[highestBidder] = highestBid;

        // 更新当前最高出价
        nftAuctionInfo[_tokenId].highestBid = msg.value + nftAuctionInfo[_tokenId].pendingReturns[msg.sender];

        // 将当前最高出价者的待退款金额置为0
        nftAuctionInfo[_tokenId].pendingReturns[msg.sender] = 0;

        // 更新当前的最高出价者
        nftAuctionInfo[_tokenId].highestBidder = msg.sender;

        // 将当前的出价者添加到竞价者名单内
        nftAuctionInfo[_tokenId].bidder.push(msg.sender);

        emit HigestBidRefresh(_tokenId, nftAuctionInfo[_tokenId].highestBid, msg.sender);
    }

    /*
    * @功能：查询正在拍卖的NFT的tokenId
    * @返回：正在拍卖的NFT的tokenId
    */
    function getAuctionNFTList() public view returns(uint[] memory) {
        return auctionNFTList;
    }

    /*
    * @功能：查询竞价者列表
    * @返回：对应的NFT的竞价者列表
    */
    function getBidderList(uint _tokenId) public view returns(address[] memory) {
        return nftAuctionInfo[_tokenId].bidder;
    }

    /*
    * @功能：查询待退款金额
    * @返回：对应的待退款金额
    */
    function getPendingReturns(uint _tokenId, address _address) public view returns(uint) {
        return nftAuctionInfo[_tokenId].pendingReturns[_address];
    }
}