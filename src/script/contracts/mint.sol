// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MintNFT is ERC1155 {
    uint256 private nextTokenId;
    address payable private contractOwner;
    string public name;
    string public symbol;
    mapping(address => bool) public authorized;
    mapping(uint256 => address) private sellerAddress;
    struct NFTMetadata {
        string location;
        string channel;
        string AP_ID;
        uint256 price;
        uint256 durations;
        uint256 expirationTime;
    }

    struct AvailableNFTsInfo {
        uint256[] tokenIds;
        uint256[] price;
        string[] AP_IDs;
        uint256[] duration;
    }
    struct OwnedNFTsInfo {
        uint256[] tokenIds;
        uint256[] price;
        string[] AP_IDs;
        uint256[] expirationTime;
        uint256[] unExpiredNFTs;
        uint256[] expiredNFTs;
    }

    mapping(uint256 => NFTMetadata) public nftMetadata;

    constructor(string memory _name, string memory _symbol) ERC1155("") {
        nextTokenId = 1;
        contractOwner = payable(msg.sender);
        authorized[contractOwner] = true;
        name = _name;
        symbol = _symbol;
    }

    /**
     * @dev Mint WIFI NFT - Create and distribute a new WIFI NFT to a specified address
     * @param _to The address to which the WIFI NFT will be minted and distributed
     * @param _quantity The number of WIFI NFTs to mint and distribute
     * @param _location The location of the WIFI NFT
     * @param _channel The channel of the WIFI NFT
     * @param AP_ID The AP ID of the WIFI NFT
     */
    //When minting NFT, only assign location, channel and apid.
    function mint_WIFI_NFT(
        address _to,
        uint256 _quantity,
        string memory _location,
        string memory _channel,
        string memory AP_ID
    ) external {
        require(
            isAuthorized(msg.sender),
            "Only contract deployers or authorized personnel can call"
        );
        uint256[] memory tokens = new uint256[](_quantity);
        uint256[] memory amounts = new uint256[](_quantity);
        for (uint256 i = 0; i < _quantity; i++) {
            tokens[i] = nextTokenId + i;
            amounts[i] = 1;
        }
        _mintNFT(_to, tokens, amounts, _location, _channel, AP_ID);
        nextTokenId += _quantity;
    }

    /**
     * @dev Mint NFT - This function is used to mint a new NFT and distribute it to the specified address
     * @param _to The address to which the NFT will be minted and distributed
     * @param _ids An array of token IDs for the NFTs to be minted
     * @param _amounts An array of token amounts for each corresponding token ID
     * @param _location The location of the NFT
     * @param _channel The channel of the NFT
     * @param AP_ID The AP ID of the NFT
     */
    function _mintNFT(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        string memory _location,
        string memory _channel,
        string memory AP_ID
    ) internal {
        _mintBatch(_to, _ids, _amounts, bytes(""));
        for (uint256 i = _ids[0]; i < _ids[0] + _ids.length; i++) {
            nftMetadata[i] = NFTMetadata(_location, _channel, AP_ID, 0, 0, 0);
        }
    }

    /**
     * @dev Get the location of a specific NFT
     * @param tokenId The ID of the NFT
     * @return The location of the NFT
     */
    function getLocation(uint256 tokenId)
    external
    view
    returns (string memory)
    {
        require(tokenId < nextTokenId, "Invalid token ID");
        return nftMetadata[tokenId].location;
    }

    /**
     * @dev Get the channel of a specific NFT
     * @param tokenId The ID of the NFT
     * @return The channel of the NFT
     */
    function getChannels(uint256 tokenId)
    external
    view
    returns (string memory)
    {
        require(tokenId < nextTokenId, "Invalid token ID");
        return nftMetadata[tokenId].channel;
    }

    /**
     * @dev Get the duration of a specific NFT
     * @param tokenId The ID of the NFT
     * @return The duration of the NFT
     */
    function getDuration(uint256 tokenId) external view returns (uint256) {
        require(tokenId < nextTokenId, "Invalid token ID");
        return nftMetadata[tokenId].durations;
    }

    /**
     * @dev Get the expiration date of a specific NFT
     * @param tokenId The ID of the NFT
     * @return The expiration date of the NFT
     */
    function getExpirationTime(uint256 tokenId)
    external
    view
    returns (uint256)
    {
        require(tokenId < nextTokenId, "Invalid token ID");
        return nftMetadata[tokenId].expirationTime;
    }

    /**
     * @dev Get the remaining usage time of a specific NFT.
     * @param tokenId The ID of the NFT.
     * @return The remaining usage time of the NFT.
     */
    function getRemainingUsageTime(uint256 tokenId)
    public
    view
    returns (int256)
    {
        int256 remainingTime = int256(
            int256(nftMetadata[tokenId].expirationTime) -
            int256(block.timestamp)
        );
        return remainingTime > 0 ? remainingTime : int256(0);
    }

    /**
     * @dev Get the price of a specific NFT
     * @param tokenId The ID of the NFT
     * @return The price of the NFT
     */
    function getPrice(uint256 tokenId) external view returns (uint256) {
        require(tokenId < nextTokenId, "Invalid token ID");
        return nftMetadata[tokenId].price;
    }

    /**
     * @dev Get the AP ID of a specific NFT
     * @param tokenId The ID of the NFT
     * @return The AP ID of the NFT
     */
    function getAP_ID(uint256 tokenId) external view returns (string memory) {
        require(tokenId < nextTokenId, "Invalid token ID");
        return nftMetadata[tokenId].AP_ID;
    }

    /**
     * @dev Get the next token ID that will be minted
     * @return The next token ID
     */
    function _getNextTokenId() internal view returns (uint256) {
        return nextTokenId;
    }

    /**
     * @dev Get the metadata of a specific NFT
     * @param _tokenId The ID of the NFT
     * @return The metadata of the NFT including location, channel, AP ID, price, duration, and expiration time
     */
    function getNFTMetadata(uint256 _tokenId)
    public
    view
    returns (NFTMetadata memory)
    {
        require(_tokenId > 0, "Invalid token ID");

        return nftMetadata[_tokenId];
    }

    /**
     * @dev Sets the authorization status of an address.
     * @param _address The address for which the authorization status is being set.
     * @param _authorized The authorization status to be set for the address.
     * Requirements:
     * - Only contract deployers can call this function.
     */
    function setAuthorized(address _address, bool _authorized) public {
        require(
            msg.sender == contractOwner,
            "Only contract deployers can call"
        );
        authorized[_address] = _authorized;
    }

    /**
     * @dev Checks if the given address is authorized.
     *
     * @param _address The address to check authorization for
     *
     * @return True if the address is authorized, false otherwise
     */
    function isAuthorized(address _address) internal view returns (bool) {
        return authorized[_address];
    }

    /**
     * @dev Sets the location of a specific NFT.
     * @param tokenId The ID of the NFT.
     * @param location The new location for the NFT.
     * Requirements:
     * - The caller must be authorized to make this change.
     */
    function setLocation(uint256 tokenId, string memory location) external {
        require(tokenId < nextTokenId, "Invalid token ID");
        require(isAuthorized(msg.sender), "Only authorized personnel can call");

        nftMetadata[tokenId].location = location;
    }

    /**
     * @dev Sets the channel of a specific NFT.
     * @param tokenId The ID of the NFT.
     * @param channels The new channel for the NFT.
     * Requirements:
     * - The caller must be authorized to make this change.
     */
    function setChannels(uint256 tokenId, string memory channels) external {
        require(tokenId < nextTokenId, "Invalid token ID");
        require(isAuthorized(msg.sender), "Only authorized personnel can call");

        nftMetadata[tokenId].channel = channels;
    }

    /**
     * @dev Sets the expiration time of a specific NFT.
     * @param tokenId The ID of the NFT.
     * @param time The new expiration time for the NFT.
     */
    function _setExpirationTime(uint256 tokenId, uint256 time) internal {
        require(tokenId < nextTokenId, "Invalid token ID");
        nftMetadata[tokenId].expirationTime = time;
    }

    /**
     * @dev List NFT for sale - This function is used to list NFTs for sale. It sets the price and duration for the NFTs.
     * @param tokenIds An array of token IDs for the NFTs to be listed for sale
     * @param price The price at which these NFTs are sold
     * @param durations How long these Wi-Fi NFTs can be connected to Wi-Fi
     * Requirements:
     * - The price must be greater than 0
     * - Only contract deployers or authorized personnel can call this function
     * - The NFTs must belong to the caller and not already be listed for sale
     */
    //Here is to put the NFT in the sales mall, and assign values ​​to price and durations here.
    function listNFTForSale(
        uint256[] memory tokenIds,
        uint256 price,
        uint256 durations
    ) external {
        require(price > 0, "Price must greater than 0");
        require(
            isAuthorized(msg.sender),
            "Only contract deployers or authorized personnel can call"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                balanceOf(msg.sender, tokenIds[i]) == 1 &&
                nftMetadata[tokenIds[i]].price == 0 &&
                nftMetadata[tokenIds[i]].durations == 0,
                "This NFT does not belong to you or is already for sale or auction "
            );
            nftMetadata[tokenIds[i]].price = price;
            nftMetadata[tokenIds[i]].durations = durations;
            sellerAddress[tokenIds[i]] = msg.sender;
        }
    }

    /**
     * @dev Get the information about available NFTs.
     * @return Returns an array of token IDs available for sale, their prices, AP IDs, and durations.
     */
    function getAvailableNFTsInfo()
    external
    view
    returns (AvailableNFTsInfo memory)
    {
        uint256[] memory tokenIds = new uint256[](nextTokenId - 1);
        uint256 count = 0;
        for (uint256 i = 1; i < nextTokenId; i++) {
            //如果这个NFT的price和durations不等于0，说明这个NFT正在出售中
            if (nftMetadata[i].price > 0 && nftMetadata[i].durations > 0) {
                tokenIds[count] = i;
                count++;
            }
            //如果这个NFT的price等于0，durations不等于0，说明这个NFT正在拍卖
        }
        uint256[] memory availableNFTs = new uint256[](count);
        uint256[] memory priceList = new uint256[](count);
        string[] memory AP_IDs = new string[](count);
        uint256[] memory durationList = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            availableNFTs[i] = tokenIds[i];
            priceList[i] = nftMetadata[tokenIds[i]].price;
            AP_IDs[i] = nftMetadata[tokenIds[i]].AP_ID;
            durationList[i] = nftMetadata[tokenIds[i]].durations;
        }
        return
        AvailableNFTsInfo(availableNFTs, priceList, AP_IDs, durationList);
    }

    /**
     * @dev Checks if the specified account is authorized to connect to Wi-Fi using the NFT.
     *
     * @param account The address of the account to check authorization for.
     * @param tokenId The ID of the NFT to be used for Wi-Fi authentication.
     *
     * @return True if the account is authorized to connect to Wi-Fi using the specified NFT, false otherwise.
     */
    function connectToWifiAuthentication(address account, uint256 tokenId)
    external
    view
    returns (bool)
    {
        return
        balanceOf(account, tokenId) >= 1 &&
        block.timestamp < nftMetadata[tokenId].expirationTime
        ? true
        : false;
    }

    /**
     * @dev Get the information about owned NFTs.
     *
     * @param account The address of the account for which the owned NFTs information is retrieved.
     *
     * @return Returns an object of type OwnedNFTsInfo containing the arrays of token IDs, prices, AP IDs, expiration times, and counts of unexpired and expired NFTs.
     */
    function getOwnedNFTs(address account)
    external
    view
    returns (OwnedNFTsInfo memory)
    {
        uint256[] memory tokenIds = new uint256[](nextTokenId - 1);
        uint256 count = 0;
        uint256 unExpiredCount = 0;
        uint256 expiredCount = 0;
        uint256 unExpiredIndex = 0;
        uint256 expiredIndex = 0;
        for (uint256 i = 1; i < nextTokenId; i++) {
            if (balanceOf(account, i) >= 1) {
                tokenIds[count] = i;
                count++;
                if (getRemainingUsageTime(i) > 0) {
                    unExpiredCount++;
                } else if (getRemainingUsageTime(i) == 0) {
                    expiredCount++;
                }
            }
        }
        uint256[] memory ownedNFTs = new uint256[](count);
        uint256[] memory priceList = new uint256[](count);
        string[] memory AP_IDs = new string[](count);
        uint256[] memory expirationTimeList = new uint256[](count);
        uint256[] memory unExpiredNfts = new uint256[](unExpiredCount);
        uint256[] memory expiredNfts = new uint256[](expiredCount);
        for (uint256 i = 0; i < count; i++) {
            ownedNFTs[i] = tokenIds[i];
            priceList[i] = nftMetadata[tokenIds[i]].price;
            AP_IDs[i] = nftMetadata[tokenIds[i]].AP_ID;
            expirationTimeList[i] = nftMetadata[tokenIds[i]].expirationTime;
            if (getRemainingUsageTime(tokenIds[i]) > 0) {
                unExpiredNfts[unExpiredIndex++] = tokenIds[i];
            } else if (getRemainingUsageTime(tokenIds[i]) == 0) {
                expiredNfts[expiredIndex++] = tokenIds[i];
            }
        }
        return
        OwnedNFTsInfo(
            ownedNFTs,
            priceList,
            AP_IDs,
            expirationTimeList,
            unExpiredNfts,
            expiredNfts
        );
    }

    /**
     * @dev Purchase NFT - This function is used to purchase an NFT by sending the required payment amount.
     * @param _tokenId The ID of the NFT to purchase
     * Requirements:
     * - The payment amount must be equal to the price of the NFT
     * - The NFT must be available for purchase and have a positive price
     * - The caller must not already own the NFT
     * - The payment amount must be sent along with the function call
     */
    //If the price and duration of this NFT are not equal to 0, it means that this NFT is on sale and you can buy it.
    function purchaseNFT(uint256 _tokenId) public payable {
        NFTMetadata memory metadata = nftMetadata[_tokenId];

        require(
            msg.value == metadata.price && metadata.price > 0,
            "Incorrect payment amount or this NFT can not be purchased"
        );
        require(
            balanceOf(msg.sender, _tokenId) == 0,
            "You already have this NFT, no need to purchase it"
        );
        payable(address(sellerAddress[_tokenId])).transfer(msg.value);
        //一旦这个NFT被售出，这个NFT的expirationTime参数就不为0
        sell(address(sellerAddress[_tokenId]), msg.sender, _tokenId);
    }

    /**
     * @dev Sell Function
     *
     * This internal function is used to sell an NFT from one address to another.
     *
     * @param from The address from which the NFT is being sold.
     * @param to The address to which the NFT is being sold.
     * @param tokenId The ID of the NFT being sold.
     *
     * Requirements:
     * - The caller must have sufficient balance of the NFT to sell.
     * - The duration of the NFT must be set.
     * - The expiration time of the NFT must be calculated and set.
     * - The price of the NFT must be set to 0 after the sale.
     */
    function sell(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        _safeTransferFrom(from, to, tokenId, 1, bytes(""));
        _setExpirationTime(
            tokenId,
            block.timestamp + nftMetadata[tokenId].durations
        );

        nftMetadata[tokenId].price = 0;
    }
}
