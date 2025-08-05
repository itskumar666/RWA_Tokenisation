//SPDX--License-Identifier: MIT

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.20;
import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./RWA_Types.sol";

/*
@title RWA_NFT
@Author Ashutosh Kumar
@Minting NFT against different assets like carbon copy, digital gold may be real estate

*/

contract RWA_NFT is ERC721URIStorage, Ownable, ERC721Burnable {
    error RWA_NFT__NotZeroAddress();
    error RWA_NFT__TokenDoesNotExist();
   
    // Optimized: Pack struct to use single storage slot where possible
    struct Metadata {
        string name;
        string description;
        string image; // optional, on-chain image (can also be a base64 SVG or URL)
        string ipfsUri; // IPFS metadata URI
    }
    
    mapping(uint256 => Metadata) private _tokenMetadata;
    uint256 private s_tokenCounter;

    event CreatedNFT(uint256 indexed tokenId);

    constructor() ERC721("TokenizedRWA", "TRWA") Ownable(msg.sender) {}

    function mint(
        address _to, 
        string memory _tokenURI,
        RWA_Types.assetType _assetType, 
        string memory _assetName,
        uint256 valueInUSD
    ) external onlyOwner returns(bool) {
        if (_to == address(0)) {
            revert RWA_NFT__NotZeroAddress();
        }
        
        uint256 tokenId = s_tokenCounter;
        
        // Optimized: Use unchecked increment for gas efficiency
        unchecked {
            s_tokenCounter = tokenId + 1;
        }
        
        _safeMint(_to, tokenId);
        
        // Optimized: Direct assignment instead of using abi.encodePacked in description
        _tokenMetadata[tokenId] = Metadata({
            name: _assetName,
            description: string.concat(
                "Asset Type: ", 
                uint2str(uint256(_assetType)),
                ", Asset Name: ", 
                _assetName,
                ", Value in USD: ", 
                uint2str(valueInUSD)
            ),
            image: "", // Optional, can be set later
            ipfsUri: _tokenURI // Assuming the tokenURI is an IPFS URI
        });
        
        _setTokenURI(tokenId, _tokenURI);
        emit CreatedNFT(tokenId);
        return true;
    }

    // Optimized helper function to convert uint to string
    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function burn(uint256 tokenId) public override onlyOwner {
        _burn(tokenId);
    }

    function setImageUri(uint256 tokenId, string memory imageUri) public onlyOwner {
        if (_ownerOf(tokenId) == address(0)) {
            revert RWA_NFT__TokenDoesNotExist();
        }
        _setTokenURI(tokenId, imageUri);
        _tokenMetadata[tokenId].ipfsUri = imageUri;
    }

    function getTokenMetadata(uint256 tokenId) public view returns (Metadata memory) {
        if (_ownerOf(tokenId) == address(0)) {
            revert RWA_NFT__TokenDoesNotExist();
        }
        return _tokenMetadata[tokenId];
    }

    function getTokenURI(
        uint256 tokenId
    ) public view returns (string memory) {
        return super.tokenURI(tokenId);
    }

    // Explicitly override tokenURI to resolve inheritance conflict
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
