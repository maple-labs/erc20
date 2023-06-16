// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import { AbstractERC20 } from "./AbstractERC20.sol";

contract ERC20 is AbstractERC20 {

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name     = name_;
        symbol   = symbol_;
        decimals = decimals_;
    }

}
