// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { ERC20Permit } from "../../ERC20Permit.sol";

contract MockERC20Permit is ERC20Permit {

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20Permit(name_, symbol_, decimals_) {}

    function mint(address to_, uint256 value_) external {
        _mint(to_, value_);
    }

    function burn(address from_, uint256 value_) external {
        _burn(from_, value_);
    }

}
