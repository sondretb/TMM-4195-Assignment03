//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract BilBoydCar is ERC721, ERC721URIStorage, Ownable{

    //Implementing and overriding needed functions
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    //Override the transfers so that the customer cant run of with the nft
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        if (ownerOf(tokenId) != owner()){
            require(to == owner(), "This is bilboyds car, you cannot give it away");
            if (msg.sender == owner()){
                require(isContractDurationFinished(from), "This customer has no active Contract with you"); //Bug fixed
                require(isInsolentCustomer(to), "This customer is not isolent");
            }
        }

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        if (ownerOf(tokenId) != owner()){
            require(to == owner(), "This is bilboyds car, you cannot give it away");
            if (msg.sender == owner()){
                require(isContractDurationFinished(from), "This customer has no active Contract with you"); //Bug fixed
                require(isInsolentCustomer(to), "This customer is not isolent");
            }
        }
        _safeTransfer(from, to, tokenId, data);
    }
    



    //Stores the car attributes, most of which help calculate the monthlyQuota
    struct Car {
        string model;
        uint256 year;
        uint256 originalValue;
        uint256 milage;
        string color;
        bool isAvailable;
    }

    //Stores information about a contract
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

    //The maturity time of the monthly bills to customers
    uint256 billMaturityTime = 2 weeks;

    enum ContractDuration {OneYear, TwoYears, ThreeYears, FourYears}
    enum MilageCap {Low, Medium, High}
    //Low = 30000, Medium = 45000, High = 60000


    //list of cars, so we don't need to access the metadata.   
    // tokenId is the index
    Car[] public boydCars;
    mapping(address => LeaseContract) addressToContract;
    mapping(address => uint256) addressToTransferedPayment;


    constructor () ERC721 ("Bil Boyd Car", "BBCAR"){
        //cars to start with
        addCar("Honda s2000", 2003, 400000, 210000, "Red", "https://ipfs.io/ipfs/QmTkcQkAHDSExyHSPZQgDi2dAVmDKEg4WC8FdyrNZ9T3i5?filename=Honda s2000.json");
        addCar("Toyota Yaris", 2010, 289000, 96000, "White", "https://ipfs.io/ipfs/QmNtRysb4Lp35WzhbnTn8mdLsYZE8BDhxzRfg3ZFNiuSGd?filename=Toyota Yaris.json");
        addCar("Audi A4", 2018, 410000, 32000, "Black", "https://ipfs.io/ipfs/QmUff9JzAQCP4YiXSGgBYZMWXADTjWnGV3AktPpyM88frV?filename=Audi A4.json");
        addCar("Jaguar I-Pace S", 2021, 724900, 12000, "Titanium", "https://ipfs.io/ipfs/QmbzWwvE1FMXcHebTNFHdh9w1vB8NaZ4aRuZXTeDKu5fNJ?filename=Jaguar I-Pace S.json");
    }

    


    function getCarList() public view returns(Car[] memory){
        return boydCars;
    }

    //Function to add a new car to bilBoyd
    function addCar(string memory model, uint256 year, uint256 originalValue, uint256 milage, string memory color, string memory tokenUri) public onlyOwner returns(uint256){

        uint256 tokenId = boydCars.length;
        _safeMint(owner(), tokenId);
        _setTokenURI(tokenId, tokenUri);
        approve(address(this),tokenId);

        boydCars.push(
            Car(
                model, 
                year, 
                originalValue,
                milage,
                color,
                true
            )
        );
        return tokenId;
    } 


    //Internal functions needed for implementation
    function milageCapToMiles(MilageCap milageCap) internal pure returns(uint256){
        return (uint(milageCap)+2)*15000;
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

    function isPaymentOverdue(address customer) view internal returns(bool){
        return block.timestamp >= addressToContract[customer].lastPayment + 4 weeks + billMaturityTime;
    }

    function hasPendingBill(address customer) view internal returns(bool){
        return block.timestamp >= addressToContract[customer].lastPayment + 4 weeks;
    }

    function isContractDurationFinished(address customer) view internal returns(bool){
        return block.timestamp >= addressToContract[customer].contractEndDate;
    }

    function isInsolentCustomer(address customer) view internal returns(bool){
        uint256 overDueLine = 4 weeks;

        return block.timestamp >= addressToContract[customer].lastPayment + 4 weeks + billMaturityTime + overDueLine;
    }



    //TASK2


    //Function that calculated the montly quota based on parameters.
    function getMontlyQuota(uint256 tokenID, uint256 yearsOfDrivingExperience, MilageCap milageCap, ContractDuration contractDuration) 
    view public 
    //Cost no gas unless called fro a SC
    returns(uint256 montlyQuota){
        uint256 milageFactor = (uint(milageCap))*4 gwei;
        uint256 durationFactor = (uint(contractDuration)+1)*boydCars[tokenID].originalValue*1 gwei/10000;
        uint256 experiencePrize;
        uint256 milagePrizeReduction = boydCars[tokenID].milage * 1 gwei / 6000;
        if (yearsOfDrivingExperience >= 5){
            experiencePrize = 0; //Bug Fixed
        }
        else{
            experiencePrize = 1 gwei/5;
        }
        
        //function just to check if things work
        return milageFactor + durationFactor + experiencePrize - milagePrizeReduction;
    }



    //TASK3    

    //Function to make a deal proposal for car 'tokenId'
    function makeDeal(uint256 tokenId, uint256 yearsOfDrivingExperience, MilageCap milageCap, ContractDuration contractDuration)
    public payable{
        require(isCarAvailable(tokenId), "That Car is not available");
        require(!hasActiveContract(msg.sender), "You're already leasing a car. Only one car per customer.");
        delete addressToContract[msg.sender];

        uint256 montlyQuota = getMontlyQuota(tokenId, yearsOfDrivingExperience, milageCap, contractDuration);
        require(msg.value >= 4*montlyQuota, "First payment must include downpayment of 3 monthly quotas and payment for the first month.\n Run \"getMontlyQuota(uint256 tokenID, uint256 yearsOfDrivingExperience, uint256 milageCap, uint256 contractDuration)\" to see mothly quota");
        uint change = msg.value - 4*montlyQuota;
        payable(msg.sender).transfer(change);

        LeaseContract memory newDeal = LeaseContract(tokenId, yearsOfDrivingExperience, contractDuration, milageCap, montlyQuota, false, 0, 0);
        addressToContract[msg.sender] = newDeal;
    }

    //Owner has the right to deny the deal proposal
    function denyDeal(address payable customer) external onlyOwner{
        require(!hasActiveContract(customer), "You cannot deny an active contract");
        require(hasContract(customer), "You don't have a contract");
        customer.transfer(4*addressToContract[customer].monthlyQuota);
        delete addressToContract[customer];
    }

    //Customer can withdraw the deal proposal
    function withDrawDeal() external {
        require(!hasActiveContract(msg.sender), "You cannot withdraw an active contract");
        payable(msg.sender).transfer(4*addressToContract[msg.sender].monthlyQuota);
        delete addressToContract[msg.sender];
    }

    //Function to approve a pending deal. This gives the cutomer the right to Collect the car, and the owner can collect the montly payment, the donwPayment stays locked.
    function approveDeal(address customer) external onlyOwner {
        require(!hasActiveContract(customer), "Contract allready approve.");
        require(hasContract(customer), "This customer has no pending contract.");
        uint256 tokenId = addressToContract[customer].tokenId;
        require(isCarAvailable(tokenId), "This car has allready been collected");
        addressToContract[customer].isActive = true;
        addressToContract[customer].contractEndDate = block.timestamp + (uint(addressToContract[customer].duration) + 1)*52 weeks;
        addressToContract[customer].lastPayment = block.timestamp;
        approve(customer, addressToContract[customer].tokenId);
        addressToTransferedPayment[customer] += addressToContract[customer].monthlyQuota;
        boydCars[tokenId].isAvailable = false;
    }

    //Owner can collect payment from customer.
    function transferPaymentFromCustomer(address customer) external onlyOwner{
        require(hasActiveContract(customer), "No active contract with this customer, approve pending contract or wait for contract proposal");
        payable(owner()).transfer(addressToTransferedPayment[customer]);
        addressToTransferedPayment[customer] = 0;
    }

    //Customer can collect the car when the deal is accepted.
    function collectCar() external {
        uint256 tokenId = addressToContract[msg.sender].tokenId;
        require(hasActiveContract(msg.sender), "No contract of yours has been approved");
        require(ownerOf(tokenId) == owner(), "This car has allready been collected");
        safeTransferFrom(owner(), msg.sender, tokenId);
        approve(owner(), tokenId);
    }


   //TASK4

    //Calculated the mothly bill, you pay more if the payment is overdue.
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

    //Registers that the monthly payment payed, if the payment is overdue the next payment is shifted.
    function registerMontlyPayment(address customer) internal {
        if (isPaymentOverdue(customer)){
            uint256 timeOverdue = block.timestamp - addressToContract[customer].lastPayment + 4 weeks + billMaturityTime;
            addressToContract[customer].lastPayment += 4 weeks + timeOverdue;
        }
        else {
        addressToContract[customer].lastPayment += 4 weeks;
        }
    }

    //Called each month to pay the bill, bill is higher if maturity period is over.
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
        registerMontlyPayment(msg.sender);
    }

    //Owner can tow the car if the customer is insolent (overdue more than a month), and reclaim the NFT.
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


     //TASK 5

    //when the contract is over the customer can terminate the contract
    function returnCarAndTerminateContract() public {
        require (hasActiveContract(msg.sender), "You don't have an active contract and therefore no leased car.");
        require(isContractDurationFinished(msg.sender), "Your contract is not yet finished.");
        uint256 tokenId = addressToContract[msg.sender].tokenId;
        require(ownerOf(tokenId) == msg.sender, "You don't have the car in your contract.");

        uint256 downPayment = addressToContract[msg.sender].monthlyQuota*3;
        payable(msg.sender).transfer(downPayment);

        safeTransferFrom(msg.sender, owner(), tokenId);

        boydCars[tokenId].milage += milageCapToMiles(addressToContract[msg.sender].milageCap);
        delete addressToContract[msg.sender];
        boydCars[tokenId].isAvailable = true;
    }

    //When the contract is over the customer can extend the contract with new rates.
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

    //When the contract is over the customer can lease a new vehicle.
    function returnCarAndLeaseNewVechicle(uint256 newCarTokenId, MilageCap newMilageCap, ContractDuration newContractDuration) external payable {
        //TODO - Worst case, terminate the contract and make a new one
        uint256 yearsOfDrivingExperience = addressToContract[msg.sender].yearsOfDrivingExperience + uint(addressToContract[msg.sender].duration) + 1;
        returnCarAndTerminateContract();
        makeDeal(newCarTokenId, yearsOfDrivingExperience, newMilageCap, newContractDuration); 


    }


    //DEV FUNCTION
    //Skip forward one week with one customer.
    function simulateWeekWithCustomer(address customer) external {
        addressToContract[customer].lastPayment -= 1 weeks;
        addressToContract[customer].contractEndDate -= 1 weeks;
    }

    function simulateyearWithCustomer(address customer) external {
        addressToContract[customer].lastPayment -= 52 weeks;
        addressToContract[customer].contractEndDate -= 52 weeks;
    }
}