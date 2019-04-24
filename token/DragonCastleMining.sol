pragma solidity ^0.4.23;

import "./../lib/SafeMath.sol";
import "./../SkyPeopleContract.sol";
import "./ERC20.sol";

contract DragonCastleMining is SkyPeopleContract {
    using SafeMath for uint256;

    uint public _round;
    uint public _initailizeRoundRate;
    uint public _roundRateStep;
    uint public _roundRate;
    uint public _lastRound;

    uint public _roundMined;
    uint public _roundMiningStep;
    uint public _mined;

    ERC20 public _token;
    mapping (address => uint) _takeable;

    event UpdateMining(address miner, uint mined, uint round, uint totalMined);

    constructor(address token) public {
        setTokenContract(token);

        _round = 1;
        _initailizeRoundRate = 500;
        _roundRateStep = 10;
        _roundRate = getRoundRate(_round);
        _lastRound = 600;

        _roundMined = 0;
        _roundMiningStep = uint(1000000).mul(1 trx);
    }

    function withdrawToken(address to, uint value) external onlyWhitelist {
        _token.transfer(to, value);
    }

    function nextRound() private {
        _round = _round.add(1);
        _roundRate = getRoundRate(_round);
        _roundMined = _roundMiningStep.mul(_round - 1);
    }

    function getSeason() public view returns (uint) {
        return getSeason(_round);
    }

    function getSeason(uint round) public pure returns (uint) {
        return round.sub(1).div(50).add(1);
    }

    function getRound() public view returns (uint) {
        return _round;
    }

    function getRoundInSeason() public view returns (uint) {
        return getRoundInSeason(_round);
    }

    function getRoundInSeason(uint round) public pure returns (uint) {
        return round.sub(getSeason(round).sub(1) * 50);
    }

    function getRoundRate(uint round) public view returns (uint) {
        uint addSeason = getSeason(round).sub(1).mul(250);
        return _initailizeRoundRate.add(addSeason).add(_roundRateStep.mul(getRoundInSeason(round).sub(1)));
    }

    function mining(address addr, uint used) public onlyWhitelist enabled {
        if (_lastRound < _round)
            return;
        uint reward = used.div(_roundRate);
        if (reward == 0)
            return;
        uint nextRemain = _roundMined.add(_roundMiningStep).sub(_mined);
        uint result = 0;
        if (nextRemain <= reward) {
            _mined = _mined.add(nextRemain);
            result = result.add(nextRemain);
            uint remain = used - nextRemain.mul(_roundRate);
            nextRound();
            if (0 < remain)
                mining(addr, remain);
        } else {
            _mined = _mined.add(reward);
            result = result.add(reward);
        }
        _takeable[addr] = _takeable[addr].add(result);
        emit UpdateMining(addr, result, _round, _mined);
    }

    function getNextRemain() public view returns (uint) {
        return _roundMined.add(_roundMiningStep).sub(_mined);
    }

    function getTakeable() public view returns (uint) {
        return _takeable[msg.sender];
    }

    function transferTakeable() external enabled {
        require (1 trx <= _takeable[msg.sender], "required 1000000 <= takeable");
        _token.transfer(msg.sender, _takeable[msg.sender]);
        _takeable[msg.sender] = 0;
    }

    function setTokenContract(address addr) public onlyWhitelist {
        _token = ERC20(addr);
    }
}