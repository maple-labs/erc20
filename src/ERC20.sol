// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IERC20 } from "./interfaces/IERC20.sol";

/**
 * @title Modern and gas efficient ERC-20 implementation. 
 * @dev   Code taken from https://github.com/maple-labs/erc-20
 * @dev   Acknowledgements to Solmate, OpenZeppelin, and DSS for inspiring this code.
 */
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

    /**************************/
    /*** External Functions ***/
    /**************************/
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address owner, address recipient, uint256 amount) external override returns (bool) {
        allowance[owner][msg.sender] -= amount;
        _transfer(owner, recipient, amount);
        return true;
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/
    function _approve(address spender, uint256 amount) internal {
        emit Approval(msg.sender, spender, allowance[msg.sender][spender] = amount);
    }

    function _transfer(address owner, address recipient, uint256 amount) internal {
        balanceOf[owner]     -= amount;
        balanceOf[recipient] += amount;

        emit Transfer(owner, recipient, amount);
    }

    function _mint(address recipient, uint256 amount) internal {
        totalSupply          += amount;
        balanceOf[recipient] += amount;

        emit Transfer(address(0), recipient, amount);
    }

    function _burn(address owner, uint256 amount) internal {
        balanceOf[owner] -= amount;
        totalSupply      -= amount;

        emit Transfer(owner, address(0), amount);
    }

}
