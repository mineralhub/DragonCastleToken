pragma solidity ^0.4.23;

import "./../lib/SafeMath.sol";
import "./../SkyPeopleContract.sol";
import "./../CoinPool.sol";
import "./IApproveAndCallFallBack.sol";
import "./ERC20.sol";

contract DragonCastleFreeze is IApproveAndCallFallBack, SkyPeopleContract {
    using SafeMath for uint256;

    struct FreezeInfo {
        uint256 index; // 0은 default 값이기에 1부터 시작한다. index 접근할때는 -1 로.
        address addr;
        uint256 timestamp;
        uint256 value;
    }

    mapping (address => FreezeInfo) public _freeze;
    address[] internal _freezeKey;
    uint256 public _totalFreeze;

    bool public _lock;
    uint256 public _airdropTrx;
    uint256 public _airdroped;
    uint256 public _airdropStep;

    uint256 public _givebacked;
    uint256 public _givebackStep;

    ERC20 public _token;

    event UpdateFreeze(address addr, bool freeze, uint tokens, uint totalFreeze);

    constructor(address token) public {
        setTokenContract(token);
        setAirdropStep(300);
        setGivebackStep(100);
        _lock = false;
    }

    function withdrawToken(address to, uint value) external onlyWhitelist {
        _token.transfer(to, value);
    }

    function receiveApproval(address from, uint256 tokens, address token, bytes data) external {
        require (_lock == false, "locked");
        _token.transferFrom(from, this, tokens);
        FreezeInfo storage info = _freeze[from];
        if (0 == info.index) {
            _freezeKey.push(from);
            info.index = _freezeKey.length;
        }
        info.timestamp = block.timestamp;
        info.value = info.value.add(tokens);
        _totalFreeze = _totalFreeze.add(tokens);
        emit UpdateFreeze(from, true, tokens, _totalFreeze);
    }

    function unfreeze() public {
        require (_lock == false, "locked");
        FreezeInfo storage info = _freeze[msg.sender];
        require (info.index != 0, "require info.index != 0");
        require (info.timestamp <= block.timestamp - 24 hours, "require 24 hours");
        _token.transfer(msg.sender, info.value);
        _totalFreeze = _totalFreeze.sub(info.value);
        emit UpdateFreeze(msg.sender, false, info.value, _totalFreeze);

        // 마지막 데이터를 삭제할 데이터 위치로 옮김.
        uint last = _freezeKey.length - 1;
        _freeze[_freezeKey[last]].index = info.index;
        _freezeKey[info.index - 1] = _freezeKey[last]; 
        _freezeKey.length--;
        delete _freeze[msg.sender];
    }

    function getFreezeKeyLength() public view returns (uint256) {
        return _freezeKey.length;
    }

    function getFreezeKey(uint256 index) public view returns (address) {
        return _freezeKey[index];
    }

    function getFreeze() public view returns (uint256 value, uint256 timestamp) {
        return getFreeze(msg.sender);
    }

    function getFreeze(address addr) public view returns (uint256 value, uint256 timestamp) {
        return (_freeze[addr].value, _freeze[addr].timestamp);
    }

    function setAirdrop(uint value) external onlyWhitelist {
        _airdroped = 0;
        _airdropTrx = value;
        _lock = true;
    }

    function airdropTrx() external onlyWhitelist returns (bool) {
        require (_lock == true, "not locked");
        uint st = _airdroped;
        uint ed = _airdroped.add(_airdropStep);
        if (_freezeKey.length < ed) {
            ed = _freezeKey.length;
            _lock = false;
        }

        uint n = 1;
        while (_totalFreeze / 10**n != 0)
            ++n;
        
        uint precision = (10**n);
        for (uint256 i = st; i < ed; ++i) {
            uint256 ratio = _freeze[_freezeKey[i]].value.mul(precision).div(_totalFreeze);
            uint256 result = _airdropTrx.mul(ratio).div(precision);
            if (0 < result)
                _freezeKey[i].transfer(result);
        }
        _airdroped = ed;
        return _lock == false;
    }

    function setLock(bool lock) public onlyWhitelist {
        _lock = lock;
    }

    function setAirdropStep(uint step) public onlyWhitelist {
        _airdropStep = step;
    }

    function setTokenContract(address addr) public onlyWhitelist {
        _token = ERC20(addr);
    }

    function setGivebackStep(uint step) public onlyWhitelist {
        _givebackStep = step;
    }

    function setGivebackTokens() external onlyWhitelist {
        _givebacked = 0;
        _lock = true;
    }

    function givebackTokens() external onlyWhitelist returns (bool) {
        require (_lock == true, "not locked");
        uint st = _givebacked;
        uint ed = _givebacked.add(_givebackStep);
         if (_freezeKey.length < ed) {
            ed = _freezeKey.length;
            _lock = false;
        }

        for (uint256 i = st; i < ed; ++i) {
            _token.transfer(_freezeKey[i], _freeze[_freezeKey[i]].value);
            _freeze[_freezeKey[i]].value = 0;
        }       
        _givebacked = ed;
        return _lock == false;
    }
}