pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BilBoydCar is ERC721, Ownable{
    
    struct Car {
        string model;
        string color;
        uint256 year;
        uint256 originalValue;
    }
    // tokenId should be lenght of boydCars
    Car[] boydCars;
    //list of cars, so we don't need to access the metadata. more memory but ok

    constructor () public ERC721 ("Bil Boyd Car", "BBCAR"){

    }

    createCar(string memory) returns(uint tokenId){

    } 
}