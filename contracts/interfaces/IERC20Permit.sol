// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

/// @title Interface of the ERC20 standard as defined in the EIP.
interface IERC20Permit {

    /**
     * @dev   Emits an event indicating that tokens have moved from one account to another.
     * @param owner_     Account that tokens have moved from.
     * @param recipient_ Account that tokens have moved to.
     * @param amount_    Amount of tokens that have been transferred.
     */
    event Transfer(address indexed owner_, address indexed recipient_, uint256 amount_);

    /**
     * @dev   Emits an event indicating that one account has set the allowance of another account over their tokens.
     * @param owner_   Account that tokens are approved from.
     * @param spender_ Account that tokens are approved for.
     * @param amount_  Amount of tokens that have been approved.
     */
    event Approval(address indexed owner_, address indexed spender_, uint256 amount_);

    /**
        @dev   Approve by signature.
        @param owner    Owner address that signed the permit
        @param spender  Spender of the permit
        @param amount   Permit approval spend limit
        @param deadline Deadline after which the permit is invalid
        @param v        ECDSA signature v component
        @param r        ECDSA signature r component
        @param s        ECDSA signature s component
     */
    function permit(address owner, address spender, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the permit type hash.
     * @return hash_ The typehash for the commit
     */
    function PERMIT_TYPEHASH() external pure returns (bytes32 hash_);
    
    /**
      * @dev   Returns the nonce for the given owner.
      * @param owner The addreses of the owner account
      * @return nonce_ The current nonce
     */
    function nonces(address owner) external view returns (uint256 nonce_);

    /**
     * @dev Returns the signature domain separator.
     * @return domain_ The domain for the contract
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32 domain_);

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
     *         Emits an {Approval} event.
     * @param  spender_ Account that tokens are approved for.
     * @param  amount_  Amount of tokens that have been approved.
     * @return success_ Boolean indicating whether the operation succeeded.
     */
    function approve(address spender_, uint256 amount_) external returns (bool success_);

    /**
     * @dev    Moves an amount of tokens from `msg.sender` to a specified account.
     *         Emits a {Transfer} event.
     * @param  recipient_ Account that receives tokens.
     * @param  amount_    Amount of tokens that are transferred.
     * @return success_   Boolean indicating whether the operation succeeded.
     */
    function transfer(address recipient_, uint256 amount_) external returns (bool success_);

    /**
     * @dev    Moves a pre-approved amount of tokens from a sender to a specified account.
     *         Emits a {Transfer} event.
     *         Emits an {Approval} event.
     * @param  owner_     Account that tokens are moving from.
     * @param  recipient_ Account that receives tokens.
     * @param  amount_    Amount of tokens that are transferred.
     * @return success_   Boolean indicating whether the operation succeeded.
     */
    function transferFrom(address owner_, address recipient_, uint256 amount_) external returns (bool success_);

}
