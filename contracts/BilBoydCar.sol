//SPDX-License-Identifier: MIT

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
        bool isAvailable;
    }

    struct LeaseContract {
        uint256 tokenId;
        uint256 yearsOfDrivingExperience;
        ContractDuration duration;
        MilageCap milageCap;
        uint256 monthlyQuota;
        bool isActive;
        uint256 contractEndDate;
        uint256 lastPayment;
    }

    uint256 billMaturityTime = 2 weeks;

    enum ContractDuration {OneYear, TwoYears, ThreeYears, FourYears}
    enum MilageCap {Low, Medium, High}
    //Low = 30000, Medium = 45000, High = 60000


    //list of cars, so we don't need to access the metadata. more memory but ok    
        // tokenId should be lenght of boydCars
    Car[] public boydCars;
    mapping(address => LeaseContract) addressToContract;
    mapping(address => uint256) addressToTransferedPayment;

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
        _safeMint(owner(), tokenId);
        approve(address(this),tokenId);

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

    function milageCapToMiles(MilageCap milageCap) internal pure returns(uint256){
        return (uint(milageCap)+2)*15000;
    }


    //milageCap and Contract duration could be changed to use a enum on mapping thingy instead.

    function getMontlyQuota(uint256 tokenID, uint256 yearsOfDrivingExperience, MilageCap milageCap, ContractDuration contractDuration) 
    view public 
    //Cost no gas unless called fro a SC
    returns(uint256 montlyQuota){

        //function just to check if things work
        return boydCars[tokenID].originalValue;
    }

    function isCarAvailable(uint256 tokenId) internal view returns(bool){
        return boydCars[tokenId].isAvailable;
    }
    
    function hasActiveContract(address customer) view internal returns(bool){
        return addressToContract[customer].isActive;
    }

    function hasContract(address customer) view internal returns(bool){
        return addressToContract[customer].monthlyQuota != 0;
    }

    function makeDeal(uint256 tokenId, uint256 yearsOfDrivingExperience, MilageCap milageCap, ContractDuration contractDuration)
    external payable{
        require(isCarAvailable(tokenId), "That Car is not available");
        require(!hasActiveContract(msg.sender), "You're already leasing a car. Only one car per customer.");
        delete addressToContract[msg.sender];

        uint256 montlyQuota = getMontlyQuota(tokenId, yearsOfDrivingExperience, milageCap, contractDuration);
        require(msg.value >= 4*montlyQuota, "First payment must include downpayment of 3 monthly quotas and payment for the first month.\n Run \"getMontlyQuota(uint256 tokenID, uint256 yearsOfDrivingExperience, uint256 milageCap, uint256 contractDuration)\" to see mothly quota");
        uint change = msg.value - 4*montlyQuota;
        payable(msg.sender).transfer(change);

        LeaseContract memory newDeal = LeaseContract(tokenId, yearsOfDrivingExperience, contractDuration, milageCap, montlyQuota, false, 0, 0);
        addressToContract[msg.sender] = newDeal;
        addressToTransferedPayment[msg.sender] += 4*montlyQuota;
    }

    function denyDeal(address payable customer) external onlyOwner{
        require(!hasActiveContract(customer), "You cannot deny an active contract");
        customer.transfer(4*addressToContract[customer].monthlyQuota);
        delete addressToContract[customer];
    }

    function withDrawDeal() external {
        require(!hasActiveContract(msg.sender), "You cannot withdraw an active contract");
        payable(msg.sender).transfer(4*addressToContract[msg.sender].monthlyQuota);
        delete addressToContract[msg.sender];
    }


    function approveDeal(address customer) external onlyOwner {
        require(!hasActiveContract(customer), "Contract allready approve.");
        require(hasContract(customer), "This customer has no pending contract.");
        uint256 tokenId = addressToContract[customer].tokenId;
        require(isCarAvailable(tokenId), "This car has allready been collected");
        addressToContract[customer].isActive = true;
        addressToContract[customer].contractEndDate = block.timestamp + (uint(addressToContract[customer].duration) + 1)*52 weeks;
        addressToContract[customer].lastPayment = block.timestamp;
        approve(customer, addressToContract[customer].tokenId);
        boydCars[tokenId].isAvailable = false;
    }

    function transferPaymentFromCustomer(address customer) external onlyOwner{
        require(hasActiveContract(customer), "No active contract with this customer, approve pending contract or wait for contract proposal");
        payable(owner()).transfer(addressToTransferedPayment[customer]);
    }

    function collectCar() external {
        uint256 tokenId = addressToContract[msg.sender].tokenId;
        require(hasActiveContract(msg.sender), "No contract of yours has been approved");
        require(isCarAvailable(tokenId), "This car has allready been collected");
        safeTransferFrom(owner(), msg.sender, tokenId);
        approve(owner(), tokenId);
    }

    function isPaymentOverdue(address customer) view internal returns(bool){
        return block.timestamp >= addressToContract[customer].lastPayment + 4 weeks + billMaturityTime;
    }

    function hasPendingBill(address customer) view internal returns(bool){
        return block.timestamp >= addressToContract[customer].lastPayment + 4 weeks;
    }

    function isContractDurationFinished(address customer) view internal returns(bool){
        return block.timestamp >= addressToContract[customer].contractEndDate;
    }

    function calculateLeasingBill(address customer) view public returns(uint256){
        uint256 standardMonthlyQuota = addressToContract[customer].monthlyQuota;

        require(!isContractDurationFinished(customer), "Contract is finished, return the car if you haven't yet to collect your downpayment.");
        if (isPaymentOverdue(customer)){
            uint256 timeOverdue = block.timestamp - addressToContract[customer].lastPayment + 4 weeks + billMaturityTime;
            uint256 adjustedBill = standardMonthlyQuota*(1+timeOverdue/(2 weeks));
            return adjustedBill;
        }
        else{
            return standardMonthlyQuota;
        }
    }

    function registerMontlyPayment(address customer) internal {


        if (isPaymentOverdue(customer)){
            uint256 timeOverdue = block.timestamp - addressToContract[customer].lastPayment + 4 weeks + billMaturityTime;
            addressToContract[customer].lastPayment += 4 weeks + timeOverdue;
        }
        else {
        addressToContract[customer].lastPayment += 4 weeks;
        }
    }

    function makeMonthlyPayment() external payable {
        require(hasActiveContract(msg.sender), "You have no active contract to pay for");
        require(hasPendingBill(msg.sender), "You have paid your mothly bill");
        uint256 bill = calculateLeasingBill(msg.sender);

        if (isPaymentOverdue(msg.sender)){
            require(msg.value >= bill, "Your bill has increased due to late payment. Use 'calculateLeasingBill(address customer)' to see what you owe");
        }
        else{
            require(msg.value >= bill, "Payment to low. Use 'calculateLeasingBill(address customer)' to see what you owe");
        }
        uint256 change = msg.value-bill;
        payable(msg.sender).transfer(change);
        addressToTransferedPayment[msg.sender] += bill;
    }

    //An insolent customer is over one month overdue 
    function isInsolentCustomer(address customer) view internal returns(bool){
        uint256 overDueLine = 4 weeks;

        return block.timestamp >= addressToContract[customer].lastPayment + 4 weeks + billMaturityTime + overDueLine;
    }


    function towLeasedCar(address customer) external onlyOwner {
        require(hasActiveContract(customer), "This customer has no active contract");

        uint256 tokenId = addressToContract[customer].tokenId;
        require(isInsolentCustomer(customer), "This customer has been a good boy. you cannot tow the car!");

        uint256 downPayment = addressToContract[customer].monthlyQuota*3;
        safeTransferFrom(customer, owner(), tokenId);
        boydCars[tokenId].isAvailable = true;
        delete addressToContract[customer];

        addressToTransferedPayment[customer] += downPayment;
    }


    //DEV FUNCTION
    function simulateWeekWithCustomer(address customer) external onlyOwner{
        addressToContract[customer].lastPayment -= 1 weeks;
        addressToContract[customer].contractEndDate -= 1 weeks;
    } 

    //task 5
    function returnCarAndTerminateContract() external {
        require (hasActiveContract(msg.sender), "You don't have an active contract and therefore no leased car.");
        require(isContractDurationFinished(msg.sender), "Your contract is not yet finished.");
        uint256 tokenId = addressToContract[msg.sender].tokenId;
        require(ownerOf(tokenId) == msg.sender, "You don't have the car in your contract.");

        uint256 downPayment = addressToContract[msg.sender].monthlyQuota*3;
        payable(msg.sender).transfer(downPayment);

        safeTransferFrom(msg.sender, owner(), tokenId);

        delete addressToContract[msg.sender];
        boydCars[tokenId].isAvailable = true;
    }

    function extendContractByOneYear(MilageCap newMilageCap) external payable{
        require (hasActiveContract(msg.sender), "You don't have an active contract and therefore no leased car.");
        require(isContractDurationFinished(msg.sender), "Your contract is not yet finished.");
        uint256 tokenId = addressToContract[msg.sender].tokenId;
        require(ownerOf(tokenId) == msg.sender, "You need to be in possession of the car in you contract");

        LeaseContract storage customerContract = addressToContract[msg.sender];
        customerContract.yearsOfDrivingExperience += uint(customerContract.duration) + 1;

        boydCars[tokenId].milage += milageCapToMiles(customerContract.milageCap);
        customerContract.contractEndDate = block.timestamp + 52 weeks;
        customerContract.milageCap = newMilageCap;
        uint256 oldMonthlyQuota = customerContract.monthlyQuota;
        uint256 newMonthlyQuota = getMontlyQuota(tokenId, 
        customerContract.yearsOfDrivingExperience, 
        customerContract.milageCap, 
        customerContract.duration);
        require((3*oldMonthlyQuota + msg.value) >= 4*newMonthlyQuota, "Previous downpayment does not cover new downpayment and payment for the first month.");
        uint256 change = (3*oldMonthlyQuota + msg.value) - 4*newMonthlyQuota;
        payable(msg.sender).transfer(change);

        addressToContract[msg.sender] = customerContract;
    }
}