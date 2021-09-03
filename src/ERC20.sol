// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { ERC20Constructorless } from "./ERC20Constructorless.sol";
import { ERC20Initializer }     from "./ERC20Initializer.sol";

contract ERC20 is ERC20Constructorless, ERC20Initializer {

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        _initialize(_name, _symbol, _decimals);
    }

}
