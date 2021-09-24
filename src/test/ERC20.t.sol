// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { DSTest } from "../../lib/ds-test/src/test.sol";

import { ERC20User }     from "./accounts/ERC20User.sol";
import { InvariantTest } from "./utils/InvariantTest.sol";
import { MockERC20 }     from "./mocks/MockERC20.sol";

contract ERC20Test is DSTest {
    
    MockERC20 internal token;

    address internal immutable self = address(this);

    function setUp() external {
        token = new MockERC20("Token", "TKN", 18);
    }

    function invariant_metadata() external {
        assertEq(token.decimals(), 18);
        assertEq(token.name(),     "Token");
        assertEq(token.symbol(),   "TKN");
    }

    function test_metadata(string memory name_, string memory symbol_, uint8 decimals_) external {
        MockERC20 mockToken = new MockERC20(name_, symbol_, decimals_);

        assertEq(mockToken.decimals(), decimals_);
        assertEq(mockToken.name(),     name_);
        assertEq(mockToken.symbol(),   symbol_);
    }

    function prove_mint(address account_, uint256 amount_) external {
        token.mint(account_, amount_);

        assertEq(token.balanceOf(account_), amount_);
        assertEq(token.totalSupply(),       amount_);
    }

    function prove_burn(address account_, uint256 amount0_, uint256 amount1_) external {
        if (amount1_ > amount0_) return;  // Mint amount must exceed burn amount

        token.mint(account_, amount0_);
        token.burn(account_, amount1_);

        assertEq(token.balanceOf(account_), amount0_ - amount1_);
        assertEq(token.totalSupply(),       amount0_ - amount1_);
    }

    function prove_approve(address account_, uint256 amount_) external {
        assertTrue(token.approve(account_, amount_));

        assertEq(token.allowance(self, account_), amount_);
    }

    function prove_transfer(address account_, uint256 amount_) external {
        token.mint(self, amount_);

        assertTrue(token.transfer(account_, amount_));

        assertEq(token.totalSupply(), amount_);

        if (self == account_) {
            assertEq(token.balanceOf(self), amount_);
        } else {
            assertEq(token.balanceOf(self),    0);
            assertEq(token.balanceOf(account_), amount_);
        }
    }

    function prove_transferFrom(address recipient_, uint256 approval_, uint256 amount_) external {
        if (amount_ > approval_) return;  // Owner must approve for more than amount

        ERC20User owner = new ERC20User();

        token.mint(address(owner), amount_);
        owner.erc20_approve(address(token), self, approval_);

        assertTrue(token.transferFrom(address(owner), recipient_, amount_));

        assertEq(token.totalSupply(), amount_);

        approval_ = address(owner) == self ? approval_ : approval_ - amount_;

        assertEq(token.allowance(address(owner), self), approval_);

        if (address(owner) == recipient_) {
            assertEq(token.balanceOf(address(owner)), amount_);
        } else {
            assertEq(token.balanceOf(address(owner)), 0);
            assertEq(token.balanceOf(recipient_), amount_);
        }
    }

    function proveFail_transfer_insufficientBalance(address recipient_, uint256 mintAmount_, uint256 sendAmount_) external {
        require(mintAmount_ < sendAmount_);

        ERC20User account = new ERC20User();

        token.mint(address(account), mintAmount_);
        account.erc20_transfer(address(token), recipient_, sendAmount_);
    }

    function proveFail_transferFrom_insufficientAllowance(address recipient_, uint256 approval_, uint256 amount_) external {
        require(approval_ < amount_);

        ERC20User owner = new ERC20User();

        token.mint(address(owner), amount_);
        owner.erc20_approve(address(token), self, approval_);
        token.transferFrom(address(owner), recipient_, amount_);
    }

    function proveFail_transferFrom_insufficientBalance(address recipient_, uint256 mintAmount_, uint256 sendAmount_) external {
        require(mintAmount_ < sendAmount_);

        ERC20User owner = new ERC20User();

        token.mint(address(owner), mintAmount_);
        owner.erc20_approve(address(token), self, sendAmount_);
        token.transferFrom(address(owner), recipient_, sendAmount_);
    }

}

contract ERC20Invariants is DSTest, InvariantTest {

    BalanceSum internal balanceSum;

    function setUp() external {
        _addTargetContract(address(balanceSum = new BalanceSum()));
    }

    function invariant_balanceSum() external {
        assertEq(balanceSum.token().totalSupply(), balanceSum.sum());
    }

}

contract BalanceSum {

    MockERC20 public token = new MockERC20("Token", "TKN", 18);

    uint256 public sum;

    function mint(address account_, uint256 amount_) external {
        token.mint(account_, amount_);
        sum += amount_;
    }

    function burn(address account_, uint256 amount_) external {
        token.burn(account_, amount_);
        sum -= amount_;
    }

    function approve(address spender_, uint256 amount_) external {
        token.approve(spender_, amount_);
    }

    function transferFrom(address owner_, address recipient_, uint256 amount_) external {
        token.transferFrom(owner_, recipient_, amount_);
    }

    function transfer(address recipient_, uint256 amount_) external {
        token.transfer(recipient_, amount_);
    }

}
