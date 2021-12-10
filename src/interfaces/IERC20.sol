// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

/// @title Interface of the ERC20 standard as defined in the EIP.
interface IERC20 {

    /**
     * @dev   Emits an event indicating that tokens have moved from one account to another.
     * @param from   Account that tokens have moved from.
     * @param to     Account that tokens have moved to.
     * @param amount Amount of tokens that have been transferred.
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev   Emits an event indicating that one account has set the allowance of another account over their tokens.
     * @param owner   Account that tokens are approved from.
     * @param spender Account that tokens are approved for.
     * @param amount  Amount of tokens that have been approved.
     */
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory name_);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory symbol_);

    /**
     * @dev Returns the decimal precision used by the token.
     */
    function decimals() external view returns (uint8 decimals_);

    /**
     * @dev Returns the total amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256 totalSupply_);

    /**
     * @dev   Returns the amount of tokens owned by a given account.
     * @param account_ Account that owns the tokens.
     */
    function balanceOf(address account_) external view returns (uint256 balance_);

    /**
     * @dev   Function that returns the allowance that one account has given another over their tokens.
     * @param owner_   Account that tokens are approved from.
     * @param spender_ Account that tokens are approved for.
     */
    function allowance(address owner_, address spender_) external view returns (uint256 allowance_);

    /**
     * @dev    Function that allows one account to set the allowance of another account over their tokens.
     * @dev    Emits an {Approval} event.
     * @param  spender_ Account that tokens are approved for.
     * @param  amount_  Amount of tokens that have been approved.
     * @return success_ Boolean indicating whether the operation succeeded.
     */
    function approve(address spender_, uint256 amount_) external returns (bool success_);

    /**
     * @dev    Moves an amount of tokens from `msg.sender` to a specified account.
     * @dev    Emits a {Transfer} event.
     * @param  recipient_ Account that receives tokens.
     * @param  amount_    Amount of tokens that are transferred.
     * @return success_   Boolean indicating whether the operation succeeded.
     */
    function transfer(address recipient_, uint256 amount_) external returns (bool success_);

    /**
     * @dev    Moves a pre-approved amount of tokens from a sender to a specified account.
     * @dev    Emits a {Transfer} event.
     * @dev    Emits an {Approval} event.
     * @param  owner_     Account that tokens are moving from.
     * @param  recipient_ Account that receives tokens.
     * @param  amount_    Amount of tokens that are transferred.
     * @return success_   Boolean indicating whether the operation succeeded.
     */
    function transferFrom(address owner_, address recipient_, uint256 amount_) external returns (bool success_);

}
