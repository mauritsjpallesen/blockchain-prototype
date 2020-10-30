blockchain-prototype

To use this contract you need a fork of the Ethereum blockchain.
So far I've only been able to make it work using software called "ganache-cli".

Download it, set up a new workspace that forks from the following url:
https://mainnet.infura.io/v3/30c67003826d47e79c3034aafa1654cd
and also copy the port that ganache-cli uses (both are done in the "server" tab
when setting up a new work space).

In the remix IDE under "DEPLOY & RUN TRANSACTIONS"
select Web3 provider as the "ENVIRONMENT" and provide the endpoint in the pop-up

The endpoint is given by ganache-cli, but per default it is 127.0.0.1:7545

For several of our functions you need to give the cEth contract address as the parameter. Below we provide the address of the contract on the Ethereum mainnet, and the link where it can be found.

compound cEth contract address: 0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5
Found at https://compound.finance/docs#networks
