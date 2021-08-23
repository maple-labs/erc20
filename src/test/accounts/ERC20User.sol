// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.6;

import { ERC20 } from "../../ERC20.sol";

contract ERC20User {

    ERC20 token;

    constructor(ERC20 _token) {
        token = _token;
    }

    // Add trys
    function approve(address dst, uint256 amt) external {
        token.approve(dst, amt);
    }

    function transfer(address dst, uint256 amt) external {
        token.transfer(dst, amt);
    }

    function transferFrom( address src, address dst, uint256 amt) external {
        token.transferFrom(src, dst, amt);
    }

}
