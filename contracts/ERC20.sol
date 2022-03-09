// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IERC20 } from "./interfaces/IERC20.sol";

/**
 * @title Modern and gas efficient ERC-20 implementation.
 * @dev   Acknowledgements to Solmate, OpenZeppelin, and DSS for inspiring this code.
 */
contract ERC20 is IERC20 {

    string public override name;
    string public override symbol;

    uint8 public immutable override decimals;

    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    /**
     * @param name_     The name of the token.
     * @param symbol_   The symbol of the token.
     * @param decimals_ The decimal precision used by the token.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name     = name_;
        symbol   = symbol_;
        decimals = decimals_;
    }

    /**************************/
    /*** External Functions ***/
    /**************************/

    function approve(address spender_, uint256 amount_) external override returns (bool success_) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    function decreaseAllowance(address spender_, uint256 subtractedAmount_) external override returns (bool success_) {
        _approve(msg.sender, spender_, allowance[msg.sender][spender_] - subtractedAmount_);
        return true;
    }

    function increaseAllowance(address spender_, uint256 addedAmount_) external override returns (bool success_) {
        _approve(msg.sender, spender_, allowance[msg.sender][spender_] + addedAmount_);
        return true;
    }

    function transfer(address recipient_, uint256 amount_) external override returns (bool success_) {
        if (recipient_ == address(this)) return false;
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    function transferFrom(address owner_, address recipient_, uint256 amount_) external override returns (bool success_) {
        if (recipient_ == address(this)) return false;
        _approve(owner_, msg.sender, allowance[owner_][msg.sender] - amount_);
        _transfer(owner_, recipient_, amount_);
        return true;
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function _approve(address owner_, address spender_, uint256 amount_) internal {
        emit Approval(owner_, spender_, allowance[owner_][spender_] = amount_);
    }

    function _burn(address owner_, uint256 amount_) internal {
        balanceOf[owner_] -= amount_;
        totalSupply       -= amount_;

        emit Transfer(owner_, address(0), amount_);
    }

    function _mint(address recipient_, uint256 amount_) internal {
        totalSupply           += amount_;
        balanceOf[recipient_] += amount_;

        emit Transfer(address(0), recipient_, amount_);
    }

    function _transfer(address owner_, address recipient_, uint256 amount_) internal {
        balanceOf[owner_]     -= amount_;
        balanceOf[recipient_] += amount_;

        emit Transfer(owner_, recipient_, amount_);
    }

}
