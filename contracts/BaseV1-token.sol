// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

contract BaseV1 {

    string public constant symbol = "SOLID";
    string public constant name = "Solidly";
    uint8 public constant decimals = 18;
    uint public totalSupply = 0;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    address public minter;
    address public anyswapRouter;
    address public pendingAnyswapRouter;
    uint256 public pendingRouterDelay;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        minter = msg.sender;
        _mint(msg.sender, 0);
    }

    // No checks as its meant to be once off to set minting rights to BaseV1 Minter
    function setMinter(address _minter) external {
        require(msg.sender == minter);
        minter = _minter;
    }

    function approve(address _spender, uint _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _getRouter() internal returns (address) {
        if (pendingRouterDelay != 0 && pendingRouterDelay < block.timestamp) {
            anyswapRouter = pendingAnyswapRouter;
            pendingRouterDelay = 0;
        }
        return anyswapRouter;
    }

    function _mint(address _to, uint _amount) internal returns (bool) {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
        emit Transfer(address(0x0), _to, _amount);
        return true;
    }

    function _transfer(address _from, address _to, uint _value) internal returns (bool) {
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint _value) external returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) external returns (bool) {
        uint allowed_from = allowance[_from][msg.sender];
        if (allowed_from != type(uint).max) {
            allowance[_from][msg.sender] -= _value;
        }
        return _transfer(_from, _to, _value);
    }

    function mint(address account, uint amount) external returns (bool) {
        require(msg.sender == minter || msg.sender == _getRouter());
        _mint(account, amount);
        return true;
    }

    function burn(address account, uint256 amount) external returns (bool) {
        require(msg.sender == _getRouter());
        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);

        emit Transfer(account, address(0), amount);
        return true;
    }

    function changeVault(address _pendingRouter) external returns (bool) {
        require(msg.sender == _getRouter());
        require(_pendingRouter != address(0), "AnyswapV3ERC20: address(0x0)");
        pendingAnyswapRouter = _pendingRouter;
        pendingRouterDelay = block.timestamp + 86400;
        emit LogChangeVault(anyswapRouter, _pendingRouter, pendingRouterDelay);
        return true;
    }
}
