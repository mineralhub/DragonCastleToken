pragma solidity ^0.4.23;

contract Whitelist {
    address internal _owner;

    struct WhitelistInfo {
        uint index;
        uint lv; // 1 : whitelist, 2 : gm
        address addr;
    }

    mapping (address => WhitelistInfo) public _whitelist;
    address[] internal _keys;

    constructor() public {
        _owner = msg.sender;
        setWhitelist(_owner, 1);
    }

    modifier onlyOwner() {
        require (_owner == msg.sender, "require onlyOwner");
        _;
    }

    modifier onlyWhitelist() {
        require (_whitelist[msg.sender].lv == 1, "require onlyWhitelist");
        _;
    }

    modifier onlyGm() {
        require (_whitelist[msg.sender].lv == 1 || _whitelist[msg.sender].lv == 2, "require onlyGm");
        _;
    }

    function isWhitelist(address addr) public view returns (bool) {
        return _whitelist[addr].lv == 1;
    }

    function isGm(address addr) public view returns (bool) {
        return _whitelist[addr].lv == 2;
    }

    function setWhitelist(address addr, uint lv) public onlyOwner {
        WhitelistInfo storage info = _whitelist[addr];
        if (info.index == 0) {
            _keys.push(addr);
            info.index = _keys.length;
        }
        info.lv = lv;
        info.addr = addr;
    }

    function removeWhitelist(address addr) public onlyOwner {
        WhitelistInfo storage info = _whitelist[addr];
        uint last = _keys.length - 1;
        _whitelist[_keys[last]].index = info.index;
        _keys[info.index - 1] = _keys[last]; 
        _keys.length--;
        delete _whitelist[addr];
    }

    function getWhitelistLength() public view onlyWhitelist returns (uint) {
        return _keys.length;
    }

    function getWhitelist(address addr) public view onlyWhitelist returns (uint) {
        return _whitelist[addr].lv;
    }

    function getWhitelist(uint index) public view onlyWhitelist returns (address, uint) {
        return (_whitelist[_keys[index]].addr, _whitelist[_keys[index]].lv);
    }
}