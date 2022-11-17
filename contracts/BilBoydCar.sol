pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BilBoydCar is ERC721, Ownable{
    
    struct Car {
        string model;
        string color;
        uint256 year;
        uint256 originalValue;
        uint256 milage;
    }

/*
    enum contractDuration {Day, Week, ThreeWeeks, Month};
    mapping(contractDuration => uint256) contractDurationToInt

    enum milageCap {Low, Medium, High, FreeRange}
    mapping(milageCap => uint256) milageCapToInt
*/

    // tokenId should be lenght of boydCars
    Car[] public boydCars;
    //list of cars, so we don't need to access the metadata. more memory but ok

    //Example: to get model of car with tokenID = 'id'
    //boyCars[id].model

    constructor () public ERC721 ("Bil Boyd Car", "BBCAR"){
        addCar("Honda s2000", "red", 2003, 400000, 2000);
        addCar("Toyota Yaris", "white", 2010, 289000, 2000);
        addCar("Audi A4", "black", 2018, 410000, 2000);
        addCar("Jaguar I-Pace S", "titanium", 2021, 724900, 2000);
    }

    function addCar(string memory model, string memory color, uint256 year, uint256 originalValue, uint256 milage) public onlyOwner returns(uint256){

        uint256 tokenId = boydCars.length;
        _safeMint(msg.sender, tokenId);

        boydCars.push(
            Car(
                model,
                color, 
                year, 
                originalValue,
                milage
            )
        );
        return tokenId;
    } 

    //milageCap and Contract duration could be changed to use a enum on mapping thingy instead.
    function getMontlyQuota(uint256 carTokenID, uint256 yearsOfDivingExperience, uint256 milageCap, uint256 contractDuration) 
    view public 
    returns(uint256 montlyQuota){
        //function just to check if things work
        return boydCars[carTokenID].originalValue;
    }

}