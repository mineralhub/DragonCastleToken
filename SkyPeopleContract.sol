pragma solidity ^0.4.23;

import "./Whitelist.sol";

contract SkyPeopleContract is Whitelist {
    bool public _enable;

    constructor() public {
        _enable = true;
    }

    // payable contract.
    function () payable external {
    }

    modifier enabled() {
        require (_enable == true, "require enable");
        _;
    }

    function setEnable(bool enable) external onlyGm {
        _enable = enable;
    }

    function withdraw(address addr, uint value) external onlyWhitelist {
        addr.transfer(value);
    }
}