//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../../src/CoinMintingAndManaging/RWA_Types.sol";

contract RWA_NFTMock is ERC721URIStorage, Ownable, ERC721Burnable {
    error RWA_NFT__NotZeroAddress();
    error RWA_NFT__TokenDoesNotExist();
    
    struct Metadata {
        string name;
        string description;
        string image;
        string ipfsUri;
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
    ) external onlyOwner returns (bool) {
        if (address(0) == _to) {
            revert RWA_NFT__NotZeroAddress();
        }
        uint256 tokenCounter = s_tokenCounter;
        _safeMint(_to, s_tokenCounter);
        _tokenMetadata[s_tokenCounter] = Metadata({
            name: _assetName,
            description: string(
                abi.encodePacked(
                    "Asset Type: ",
                    uint256(_assetType),
                    ", Asset Name: ",
                    _assetName,
                    ", Value in USD: ",
                    valueInUSD
                )
            ),
            image: "",
            ipfsUri: _tokenURI
        });
        _setTokenURI(s_tokenCounter, _tokenURI);
        s_tokenCounter += 1;
        emit CreatedNFT(tokenCounter);
        return true;
    }
    
    function burn(uint256 tokenId) public override(ERC721Burnable) onlyOwner {
        if (!_exists(tokenId)) {
            revert RWA_NFT__TokenDoesNotExist();
        }
        _burn(tokenId);
        delete _tokenMetadata[tokenId];
    }
    
    function setImageUri(uint256 tokenId, string memory imageUri) public onlyOwner {
        if (!_exists(tokenId)) {
            revert RWA_NFT__TokenDoesNotExist();
        }
        _setTokenURI(tokenId, imageUri);
        _tokenMetadata[tokenId].image = imageUri;
    }
    
    function getTokenCounter() external view returns (uint256) {
        return s_tokenCounter;
    }
    
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        if (!_exists(tokenId)) {
            revert RWA_NFT__TokenDoesNotExist();
        }
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
