pragma solidity ^0.4.25;


//add more about the project like infos, structure, etc.


contract CrowdfundingCampaign{

    address public owner;
    mapping(address => bool) contributors;
    uint public contributorsCount;
    uint public minimumContribution;

    //Withdrawal request structure
    struct Withdrawal{
        string description;
        uint value;
        address recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }

    //Array with all withdrawals
    Withdrawal[] public withdrawals;
    

    //creates CrowdfundingCampaign, also can include more Infos about the project here
    constructor(uint minimum, address creator) public {
        owner = creator;
        minimumContribution = minimum;

    }


    function contribute() public payable {
        require(msg.value >= minimumContribution);
        contributors[msg.sender]= true;
        contributorsCount++;
    }

    //only owner can create withdrawal request
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    //only contributors can approve
    modifier onlyContributer{
        require(contributors[msg.sender]);
        _;
    }

    //only owner can create withdrawal request
    function createWithdrawal(string description, uint value, address recipient) public onlyOwner {
        Withdrawal memory newWithdrawal = Withdrawal({
            description: description, //for what they use the money
            value: value, //how much money they need
            recipient: recipient, //must be owner
            complete: false, //must be approved first
            approvalCount: 0
        });
        withdrawals.push(newWithdrawal); //add request to array
    }

     //only contributors can approve
    function approveWithdrawal(uint index) public onlyContributer {
        Withdrawal storage withdrawal = withdrawals[index];
        require(!withdrawal.approvals[msg.sender]);

        withdrawal.approvalCount++;
    }

    //to finalize/complete withdrawal approvalCount must be higher than 50% of ContributorsCount
    function finalizeWithdrawal(uint index) public onlyOwner {
         Withdrawal storage withdrawal = withdrawals[index];
         require(withdrawal.approvalCount > (contributorsCount / 2));
         require(!withdrawal.complete);

         withdrawal.recipient.transfer(withdrawal.value); //transfer money to project owner
         withdrawal.complete = true; //withdrawal complete, can't be executed a second time
    }


}
