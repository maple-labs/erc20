// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IERC20 }       from "../../interfaces/IERC20.sol";
import { IERC20Permit } from "../../interfaces/IERC20Permit.sol";

contract ERC20User {

    function erc20_approve(address token_, address spender_, uint256 amount_) external {
        IERC20(token_).approve(spender_, amount_);
    }

    function erc20_transfer(address token_, address recipient_, uint256 amount_) external {
        IERC20(token_).transfer(recipient_, amount_);
    }

    function erc20_transferFrom(address token_, address owner_, address recipient_, uint256 amount_) external {
        IERC20(token_).transferFrom(owner_, recipient_, amount_);
    }

}

contract ERC20PermitUser is ERC20User {

    function erc20_permit(
        address mplToken_,
        address owner_,
        address spender_,
        uint256 amount_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    )
        external
    {
        IERC20Permit(mplToken_).permit(owner_, spender_, amount_, deadline_, v_, r_, s_);
    }

}