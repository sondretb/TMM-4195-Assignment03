//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BilBoydCar is ERC721, Ownable{
    

    //Stores the car attributes that decide the montly quota.
    struct Car {
        string model;
        uint256 year;
        uint256 originalValue;
        uint256 milage;
    }
    //list of cars, so we don't need to access the metadata. more memory but ok    
        // tokenId should be lenght of boydCars
    Car[] public boydCars;
    //Example: to get model of car with tokenID = 'id'
    //boyCars[id].model



    constructor () ERC721 ("Bil Boyd Car", "BBCAR"){
        addCar("Honda s2000", 2003, 400000, 2000);
        addCar("Toyota Yaris", 2010, 289000, 2000);
        addCar("Audi A4", 2018, 410000, 2000);
        addCar("Jaguar I-Pace S", 2021, 724900, 2000);
    }

    function getCarList() public view returns(Car[] memory){
        return boydCars;
    }


/*
    enum contractDuration {Day, Week, ThreeWeeks, Month};
    mapping(contractDuration => uint256) contractDurationToInt

    enum milageCap {Low, Medium, High, FreeRange}
    mapping(milageCap => uint256) milageCapToInt
*/

    function addCar(string memory model, uint256 year, uint256 originalValue, uint256 milage) public onlyOwner returns(uint256){

        uint256 tokenId = boydCars.length;
        _safeMint(address(this), tokenId);

        boydCars.push(
            Car(
                model, 
                year, 
                originalValue,
                milage
            )
        );

        //TODO: metadata to contain information about the car. colour year of matriculation etc.
        return tokenId;
    } 







    //milageCap and Contract duration could be changed to use a enum on mapping thingy instead.
    //you can traditionally lease a car for 24, 36 or 48 months

    function getMontlyQuota(uint256 tokenID, uint256 yearsOfDrivingExperience, uint256 milageCap, uint256 contractDuration) 
    view public 
    //Cost no gas unless called fro a SC
    returns(uint256 montlyQuota){

        //function just to check if things work
        return boydCars[tokenID].originalValue ether;
    }



    function makeDeal(uint256 tokenId, uint256 yearsOfDrivingExperience, uint256 milageCap, uint256 contractDuration)
    public payable{
        uint256 montlyQuota = getMontlyQuota(tokenId, yearsOfDrivingExperience, milageCap, contractDuration);
        require(3*montlyQuota == msg.value, "Downpayment must be equivalent to 3 monthly quotas. ")
    }
}