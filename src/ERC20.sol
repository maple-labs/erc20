// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.6;

import { IERC20 } from "./IERC20.sol";

/// @title  Modern and gas efficient ERC-20 implementation. 
contract ERC20 is IERC20 {

    string public override name;
    string public override symbol;

    uint8 public immutable override decimals;

    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name     = _name;
        symbol   = _symbol;
        decimals = _decimals;
    }

    /*********************************/
    /*** ERC-20 External Functions ***/
    /*********************************/
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 amount) external override returns (bool) {
        _approve(spender, allowance[msg.sender][spender] + amount);
        return true;
    }

    function decreaseAllowance(address spender, uint256 amount) external override returns (bool) {
        _approve(spender, allowance[msg.sender][spender] - amount);
        return true;
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }

    /*********************************/
    /*** ERC-20 Internal Functions ***/
    /*********************************/
    function _approve(address spender, uint256 amount) internal {
        emit Approval(msg.sender, spender, allowance[msg.sender][spender] = amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        balanceOf[from] -= amount;
        balanceOf[to]   += amount;

        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        totalSupply   += amount;
        balanceOf[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        balanceOf[from] -= amount;
        totalSupply     -= amount;

        emit Transfer(from, address(0), amount);
    }

}
