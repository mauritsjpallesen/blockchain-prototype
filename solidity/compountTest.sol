pragma solidity ^0.5.12;

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

pragma solidity ^0.6.0;

interface CEth {
    function mint() external payable;

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function balanceOfUnderlying(address) external returns (uint);
}

/* compound cEth contract address: 0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5
Found at https://compound.finance/docs#networks */

contract CompoundTest {

    address payable constant private freeCharity = 0xE0f5206BBD039e7b0592d8918820024e2a7437b9;

    struct Project {
        address payable ownerAddress;
        uint256 financialGoal;
        address[] donors;
        mapping (address => uint256) donations;
    }

    mapping(string => Project) public projects;

    modifier projectIsNotNull(string memory projectId, string memory message) {
        require(projects[projectId].ownerAddress != 0x0000000000000000000000000000000000000000, message);
        _;
    }

    function CreateProject(string memory projectId, uint256 financialGoal) public
    {
        require(projects[projectId].ownerAddress == 0x0000000000000000000000000000000000000000, "Project with given ID already exists");

        address payable ownerAddress = msg.sender;
        address[] memory donors;
        Project memory project = Project(
        {
            ownerAddress: ownerAddress,
            financialGoal: financialGoal,
            donors: donors
        });

        projects[projectId] = project;
    }

    function DonateToProject(string memory projectId, address payable _cEtherContract) public projectIsNotNull(projectId, "The project does not exist") payable
    {
        require(msg.value > 0, "Cannot donate 0 wei");
        SupplyToCompound(_cEtherContract);
        projects[projectId].donations[msg.sender] += msg.value;
        projects[projectId].donors.push(msg.sender);
    }

    function RetrieveDonation(string memory projectId, uint256 amount, address payable _cEtherContract) public
    {
        require(projects[projectId].donations[msg.sender] >= amount, "Cannot retrieve more than the amount that has already been donated");

        WithdrawFromCompound(amount, _cEtherContract);

        projects[projectId].donations[msg.sender] -= amount;
        bool retrieveResult = msg.sender.send(amount);
        require(retrieveResult == true, "Failed to transfer retrieved Eth to donor");
    }

    function CompleteProject(string memory projectId, address _cEtherContract) public projectIsNotNull(projectId, "Cannot complete project that does not exist")
    {
        Project storage project = projects[projectId];

        uint256 ethAvailableOnCompound = balanceOfUnderlying(_cEtherContract);

        uint256 amountToWithdrawForDonors = 0;
        for (uint i=0; i < project.donors.length; i++) {
            amountToWithdrawForDonors += project.donations[project.donors[i]];
        }

        uint256 totalAmountToRetrieve = ethAvailableOnCompound + project.financialGoal;
        require(totalAmountToRetrieve > ethAvailableOnCompound, "Overflow");
        require(totalAmountToRetrieve >= amountToWithdrawForDonors, "Not enough interest has been earned to complete this project");

        WithdrawFromCompound(ethAvailableOnCompound + project.financialGoal, _cEtherContract);
        for (uint i=0; i < project.donors.length; i++) {
            address donor = project.donors[i];
            bool retrieveResult = payable(donor).send(project.donations[donor]);
            require(retrieveResult == true, "Failed to transfer retrieved Eth to donor");
            project.donations[project.donors[i]] = 0;
        }

        bool sendToOwnerResult = project.ownerAddress.send(project.financialGoal);
        require(sendToOwnerResult == true, "Failed to transfer financialGoal to project owner");
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

    function balanceOfUnderlying(address _cEtherContract) private returns (uint256) {
        CEth cToken = CEth(_cEtherContract);
        return cToken.balanceOfUnderlying(address(this));
    }

    function DonationAmount(string memory projectId) public view returns(uint256) {
        return projects[projectId].donations[msg.sender];
    }

    // This is needed to receive ETH when calling `redeemCEth`
    receive() external payable { }
}
