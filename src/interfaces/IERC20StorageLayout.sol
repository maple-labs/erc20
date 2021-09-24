// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

interface IERC20StorageLayout {

    /***********************/
    /*** State Variables ***/
    /***********************/

    /**
     * @dev   Function that returns the allowance that one account has given another over their tokens.
     * @param owner   Account that tokens are approved from.
     * @param spender Account that tokens are approved for.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev   Returns the amount of tokens owned by a given account.
     * @param account Account that owns the tokens.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the decimal precision used by the token.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the total amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

}
