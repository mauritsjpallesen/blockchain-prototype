pragma solidity 0.6.0;

/*

compound cEth contract address: 0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5
Found at https://compound.finance/docs#networks

To use this contract you need a fork of the Ethereum blockchain.
So far I've only been able to make it work using software called "ganache-cli".

Download it, set up a new workspace that forks from the following url:
https://mainnet.infura.io/v3/30c67003826d47e79c3034aafa1654cd
and also copy the port that ganache-cli uses (both are done in the "server" tab
when setting up a new work space).

In the remix IDE under "DEPLOY & RUN TRANSACTIONS"
select Web3 provider as the "ENVIRONMENT" and provide the endpoint in the pop-up

The endpoint is given by ganache-cli

*/

interface CEth {
    function mint() external payable;

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function balanceOfUnderlying(address) external returns (uint);
}

/* compound cEth contract address: 0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5
Found at https://compound.finance/docs#networks */

contract Project {

    address payable constant private freeCharity = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9;
    uint256 feeInWei = 10000;
    address payable ownerAddress;
    uint256 financialGoal;
    address[] donors;
    mapping (address => uint256) donations;

    constructor(uint256 _financialGoal) public {
        ownerAddress = msg.sender;
        financialGoal = _financialGoal;
    }

    function DonateToProject(address payable _cEtherContract) public payable
    {
        require(msg.value > 0, "Cannot donate 0 wei");
        SupplyToCompound(_cEtherContract);
        donations[msg.sender] += msg.value;
        donors.push(msg.sender);
    }

    function RetrieveDonation(uint256 amount, address payable _cEtherContract) public
    {
        require(donations[msg.sender] >= amount, "Cannot retrieve more than the amount that has already been donated");

        WithdrawFromCompound(amount, _cEtherContract);

        donations[msg.sender] -= amount;
        bool retrieveResult = msg.sender.send(amount);
        require(retrieveResult == true, "Failed to transfer retrieved Eth to donor");
    }

    function CompleteProject(address _cEtherContract) public
    {
        uint256 ethAvailableOnCompound = balanceOfUnderlying(_cEtherContract);

        uint256 amountToWithdrawForDonors = 0;
        for (uint i=0; i < donors.length; i++) {
            amountToWithdrawForDonors += donations[donors[i]];
        }

        uint256 minimumAmountToRetrieve = amountToWithdrawForDonors + financialGoal + feeInWei;
        require(minimumAmountToRetrieve <= ethAvailableOnCompound, "Not enough interest has been earned to complete this project");

        WithdrawFromCompound(ethAvailableOnCompound, _cEtherContract);
        for (uint i=0; i < donors.length; i++) {
            address donor = donors[i];
            bool retrieveResult = payable(donor).send(donations[donor]);
            require(retrieveResult == true, "Failed to transfer retrieved Eth to donor");
            donations[donor] = 0;
        }

        bool sendToOwnerResult = ownerAddress.send(financialGoal - feeInWei);
        bool sendToFreeCharityResult = freeCharity.send(feeInWei);
        require(sendToOwnerResult == true, "Failed to transfer financialGoal to project owner");
        require(sendToFreeCharityResult == true, "Failed to transfer fee to FreeCharity");
    }

    function SupplyToCompound(address payable _cEtherContract) private
    {
        CEth cToken = CEth(_cEtherContract);
        cToken.mint.value(msg.value).gas(250000)();
    }

    function WithdrawFromCompound(uint256 amount, address _cEtherContract) private
    {
        CEth cToken = CEth(_cEtherContract);
        uint256 redeemResult = cToken.redeemUnderlying(amount);
        require(redeemResult == 0, "An error occurred when redeeming from compound");
    }

    function balanceOfUnderlying(address _cEtherContract) private returns (uint256) {
        CEth cToken = CEth(_cEtherContract);
        return cToken.balanceOfUnderlying(address(this));
    }

    function DonationAmount() public view returns(uint256) {
        return donations[msg.sender];
    }

    // This is needed to receive ETH when calling `redeemCEth`
    receive() external payable { }
}
