//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Reciever.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BilBoydCar is ERC721, IERC721Reciever, Ownable{
    

    //Stores the car attributes that decide the montly quota.
    struct Car {
        string model;
        uint256 year;
        uint256 originalValue;
        uint256 milage;
        bool isAvailable;
    }

    struct leaseContract {
        uint256 carToken;
        contractDuration duration;
        milageCap milageCap;
        uint256 monthlyQuota;
        bool isActive;
    }

    enum ContractDuration {TwoYears = 24, ThreeYears = 36, FourYears = 48};
    enum MilageCap {Low = 30000, Medium = 45000, High = 60000}


    //list of cars, so we don't need to access the metadata. more memory but ok    
        // tokenId should be lenght of boydCars
    Car[] public boydCars;
    mapping(address => leaseContract) addressToContract;
    
    

    constructor () ERC721 ("Bil Boyd Car", "BBCAR"){
        addCar("Honda s2000", 2003, 400000, 2000);
        addCar("Toyota Yaris", 2010, 289000, 2000);
        addCar("Audi A4", 2018, 410000, 2000);
        addCar("Jaguar I-Pace S", 2021, 724900, 2000);
    }


    function getCarList() public view returns(Car[] memory){
        return boydCars;
    }

    function addCar(string memory model, uint256 year, uint256 originalValue, uint256 milage) public onlyOwner returns(uint256){

        uint256 tokenId = boydCars.length;
        _safeMint(address(this), tokenId);

        boydCars.push(
            Car(
                model, 
                year, 
                originalValue,
                milage,
                true
            )
        );

        //TODO: metadata to contain information about the car. colour year of matriculation etc.
        return tokenId;
    } 



    //milageCap and Contract duration could be changed to use a enum on mapping thingy instead.

    function getMontlyQuota(uint256 tokenID, uint256 yearsOfDrivingExperience, uint256 milageCap, uint256 contractDuration) 
    view public 
    //Cost no gas unless called fro a SC
    returns(uint256 montlyQuota){

        //function just to check if things work
        return boydCars[tokenID].originalValue ether;
    }

    function isCarAvailable(uint256 tokenId) internal view returns(bool){
        return boydCars[tokenId].isAvailable;
    }
    
    function hasActiveContract(address customer) view internal{
        return addressToContract[customer].isActive;
    }

    function makeDeal(uint256 tokenId, uint256 yearsOfDrivingExperience, MilageCap milageCap, ContractDuration contractDuration)
    external payable{
        require(isCarAvailable(), "That Car is not available");
        require(!hasActiveContract, "You're already leasing a car. Only one car per customer.");
        delete addressToContract[msg.sender];

        uint256 montlyQuota = getMontlyQuota(tokenId, yearsOfDrivingExperience, milageCap, contractDuration);
        require(msg.value <= 4*montlyQuota, "First payment must include downpayment of 3 monthly quotas and payment for the first month.\n Run \"getMontlyQuota(uint256 tokenID, uint256 yearsOfDrivingExperience, uint256 milageCap, uint256 contractDuration)\" to see mothly quota");
        uint change = msg.value - 4*montlyQuota;
        msg.sender.transfer(change);
        leaseContract newDeal = new leaseContract(tokenId, contractduration, milageCap, montlyQuota);
        addressToContract[msg.sender] = newDeal;
    }

    function denyDeal(address payable customer) external onlyOwner{
        require(!hasActiveContract(customer), "You cannot deny an active contract");
        customer.transfer(4*addressToContract[customer].montlyQuota);
        delete addressToContract[customer];
    }

    function withDrawDeal() external {
        require(!hasActiveContract(msg.sender), "You cannot withdraw an active contract");
        customer.transfer(4*addressToContract[msg.sender].montlyQuota);
        delete addressToContract[msg.sender];
    }

    function approveDeal(address customer) external onlyOwner {
        addressToContract[customer].isActive == true;
        safeTransferFrom(address(this), customer, addressToContract[customer].tokenId);
    }
}