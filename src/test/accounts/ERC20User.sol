// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.6;

import { ERC20 } from "../../ERC20.sol";

contract ERC20User {

    ERC20 token;

    constructor(ERC20 _token) {
        token = _token;
    }

    /************************/
    /*** Direct Functions ***/
    /************************/
    function erc20_approve(address recipient, uint256 amount) external {
        token.approve(recipient, amount);
    }

    function erc20_transfer(address recipient, uint256 amount) external {
        token.transfer(recipient, amount);
    }

    function erc20_transferFrom(address owner, address recipient, uint256 amount) external {
        token.transferFrom(owner, recipient, amount);
    }

    /************************/
    /*** Try Functions ***/
    /************************/
    function try_erc20_approve(address recipient, uint256 amount) external {
        token.approve(recipient, amount);
    }

    function try_erc20_transfer(address recipient, uint256 amount) external {
        token.transfer(recipient, amount);
    }

    function try_erc20_transferFrom( address owner, address recipient, uint256 amount) external {
        token.transferFrom(owner, recipient, amount);
    }

}
