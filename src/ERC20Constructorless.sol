// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IERC20 } from "./interfaces/IERC20.sol";

import { ERC20StorageLayout } from "./ERC20StorageLayout.sol";

contract ERC20Constructorless is IERC20, ERC20StorageLayout {

    /**************************/
    /*** External Functions ***/
    /**************************/

    function approve(address spender, uint256 amount) external override virtual returns (bool) {
        _approve(spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external override virtual returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address owner, address recipient, uint256 amount) external override virtual returns (bool) {
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
