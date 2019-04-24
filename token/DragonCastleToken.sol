pragma solidity ^0.4.23;

import "./ERC20Burnable.sol";

contract DragonCastleToken is ERC20Burnable {
    string public name = "DragonCastle";
    string public symbol = "DC";
    uint public decimals = 6;
    uint public INITIAL_SUPPLY = 1000000000 * (10 ** decimals);
    
    constructor() public {
        _totalSupply = INITIAL_SUPPLY;
        _balances[msg.sender] = INITIAL_SUPPLY;
    }
}