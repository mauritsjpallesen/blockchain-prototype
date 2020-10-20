pragma solidity ^0.5.12;

interface CEth {
    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);
}

/* compound cEth contract address: 0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5
Found at https://compound.finance/docs#networks */

contract CompoundTest {

    function supplyEthToCompound(address payable _cEtherContract) public payable returns (bool)
    {
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherContract);

        cToken.mint.value(msg.value).gas(250000)();
        return true;
    }

    function redeemCEth(uint256 amount, bool redeemType, address _cEtherContract) public returns (bool) {
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherContract);

        // `amount` is scaled up by 1e18 to avoid decimals
        uint256 redeemResult = cToken.redeem(amount);

        // Error codes are listed here:
        // https://compound.finance/docs/ctokens#ctoken-error-codes
        if (redeemResult != 0) {
          return false;
        }

        return true;
    }

    // This is needed to receive ETH when calling `redeemCEth`
    function() external payable {}
}
