pragma solidity ^0.5.12;

/*

compound cEth contract address: 0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5
Found at https://compound.finance/docs#networks

To use this contract you need a fork of the Ethereuym blockchain.
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

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);
}

contract CompoundTest {

    event log(string, uint256);
    event addressLog(string, address);

    address payable constant public freeCharity = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9;

    struct Project {
        address payable ownerAddress;
        int256 financialGoal;
        mapping (address => uint256) donations;
    }

    mapping(string => Project) public projects;

    function CreateProject(string memory projectId, int256 financialGoal) public
    {
        address payable ownerAddress = msg.sender;
        Project memory project = Project(
        {
            ownerAddress: ownerAddress,
            financialGoal: financialGoal
        });

        projects[projectId] = project;
    }

    function DonateToProject(string memory projectId, address payable _cEtherContract) public payable
    {
        require(projects[projectId].ownerAddress != 0x0000000000000000000000000000000000000000, "Project does not exist");
        require(msg.value > 0, "Cannot donate 0 wei");
        SupplyToCompound(_cEtherContract);
        projects[projectId].donations[msg.sender] += msg.value;
    }

    function RetrieveDonation(string memory projectId, uint256 amount, address payable _cEtherContract) public
    {
        require(projects[projectId].donations[msg.sender] >= amount, "Cannot retrieve more than the amount that has already been donated");
        uint256 balanceBeforeWithdraw = address(this).balance;

        WithdrawFromCompound(amount, _cEtherContract);

        uint256 balanceAfterWithdraw = address(this).balance;
        uint256 amountToRetrieve = balanceAfterWithdraw - balanceBeforeWithdraw;

        projects[projectId].donations[msg.sender] -= amountToRetrieve;
        bool retrieveResult = msg.sender.send(amountToRetrieve);
        require(retrieveResult == true, "Failed to transfer retrieved Eth to donor");
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

    function BalanceOf() public view returns(uint256) {
        return address(this).balance;
    }

    function DonationAmount(string memory projectId) public view returns(uint256) {
        return projects[projectId].donations[msg.sender];
    }

    // This is needed to receive ETH when calling `redeemCEth`
    function() external payable { }
}
