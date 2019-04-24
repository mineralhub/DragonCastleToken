pragma solidity ^0.4.23;

import "./SafeMath.sol";

library Utils {
    using SafeMath for *;

    function random(uint nonce) internal view returns(uint) {
        return uint(keccak256(abi.encodePacked(msg.sender, block.number, blockhash(block.number), nonce)));
    }

    // 100000000 : 100%
    function calculateRate(uint v, uint rate) internal pure returns(uint) {
        return v.mul(rate).div(100000000);
    }
}