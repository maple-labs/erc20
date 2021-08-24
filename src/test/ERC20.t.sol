// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { DSTest } from "../../lib/ds-test/src/test.sol";

import { ERC20User }     from "./accounts/ERC20User.sol";
import { MockERC20 }     from "./mocks/MockERC20.sol";
import { InvariantTest } from "./utils/InvariantTest.sol";

contract ERC20Test is DSTest {
    
    MockERC20 token;

    address internal immutable self = address(this);

    function setUp() public {
        token = new MockERC20("Token", "TKN", 18);
    }

    function invariant_metadata() public {
        assertEq(token.name(),     "Token");
        assertEq(token.symbol(),   "TKN");
        assertEq(token.decimals(), 18);
    }

    function test_metadata(string memory name, string memory symbol, uint8 decimals) public {
        MockERC20 mockToken = new MockERC20(name, symbol, decimals);

        assertEq(mockToken.name(),     name);
        assertEq(mockToken.symbol(),   symbol);
        assertEq(mockToken.decimals(), decimals);
    }

    function prove_mint(address account, uint256 amount) public {
        token.mint(account, amount);

        assertEq(token.totalSupply(),      amount);
        assertEq(token.balanceOf(account), amount);
    }

    function prove_burn(address account, uint256 amount0, uint256 amount1) public {
        if (amount1 > amount0) return; // Mint amount must exceed burn amount

        token.mint(account, amount0);
        token.burn(account, amount1);

        assertEq(token.totalSupply(),      amount0 - amount1);
        assertEq(token.balanceOf(account), amount0 - amount1);
    }

    function prove_approve(address account, uint256 amount) public {
        assertTrue(token.approve(account, amount));

        assertEq(token.allowance(self, account), amount);
    }

    function prove_increaseAllowance(address account, uint256 amount0, uint256 amount1) public {
        unchecked { if (amount0 + amount1 < amount0) return; }  // Only check non-overflow conditions
        
        assertTrue(token.approve(account, amount0));
        assertTrue(token.increaseAllowance(account, amount1));

        assertEq(token.allowance(self, account), amount0 + amount1);
    }

    function prove_decreaseAllowance(address account, uint256 amount0, uint256 amount1) public {
        unchecked { if (amount0 - amount1 > amount0) return; }  // Only check non-overflow conditions

        assertTrue(token.approve(account, amount0));
        assertTrue(token.decreaseAllowance(account, amount1));

        assertEq(token.allowance(self, account), amount0 - amount1);
    }

    function prove_transfer(address account, uint256 amount) public {
        token.mint(self, amount);

        assertTrue(token.transfer(account, amount));

        assertEq(token.totalSupply(), amount);

        if (self == account) {
            assertEq(token.balanceOf(self), amount);
        } else {
            assertEq(token.balanceOf(self),    0);
            assertEq(token.balanceOf(account), amount);
        }
    }

    function prove_transferFrom(address to, uint256 approval, uint256 amount) public {
        if (amount > approval) return; // Owner must approve for more than amount

        ERC20User owner = new ERC20User();

        token.mint(address(owner), amount);
        owner.erc20_approve(address(token), self, approval);

        assertTrue(token.transferFrom(address(owner), to, amount));

        assertEq(token.totalSupply(), amount);

        approval = address(owner) == self ? approval : approval - amount;

        assertEq(token.allowance(address(owner), self), approval);

        if (address(owner) == to) {
            assertEq(token.balanceOf(address(owner)), amount);
        } else {
            assertEq(token.balanceOf(address(owner)), 0);
            assertEq(token.balanceOf(to), amount);
        }
    }

    function proveFail_increaseAllowance_overflow(address account, uint256 amount0, uint256 amount1) public {
        unchecked { require(amount0 + amount1 < amount0); }  // Only check overflow conditions

        assertTrue(token.approve(account, amount0));
        assertTrue(token.increaseAllowance(account, amount1));

        assertEq(token.allowance(self, account), amount0 + amount1);
    }

    function proveFail_decreaseAllowance_overflow(address account, uint256 amount0, uint256 amount1) public {
        unchecked { require(amount0 - amount1 > amount0); }  // Only check overflow conditions

        assertTrue(token.approve(account, amount0));
        assertTrue(token.decreaseAllowance(account, amount1));

        assertEq(token.allowance(self, account), amount0 - amount1);
        assertTrue(false);
    }

    function proveFail_transfer_insufficientBalance(address to, uint256 mintAmount, uint256 sendAmount) public {
        require(mintAmount < sendAmount);

        ERC20User account = new ERC20User();

        token.mint(address(account), mintAmount);
        account.erc20_transfer(address(token), to, sendAmount);
    }

    function proveFail_transferFrom_insufficientAllowance(address to, uint256 approval, uint256 amount) public {
        require(approval < amount);

        ERC20User owner = new ERC20User();

        token.mint(address(owner), amount);
        owner.erc20_approve(address(token), self, approval);
        token.transferFrom(address(owner), to, amount);
    }

    function proveFail_transferFrom_insufficientBalance(address to, uint256 mintAmount, uint256 sendAmount) public {
        require(mintAmount < sendAmount);

        ERC20User owner = new ERC20User();

        token.mint(address(owner), mintAmount);
        owner.erc20_approve(address(token), self, sendAmount);
        token.transferFrom(address(owner), to, sendAmount);
    }

}

contract ERC20Invariants is DSTest, InvariantTest {

    BalanceSum balanceSum;

    function setUp() public {
        balanceSum = new BalanceSum();
        addTargetContract(address(balanceSum));
    }

    function invariant_balanceSum() public {
        assertEq(balanceSum.token().totalSupply(), balanceSum.sum());
    }

}

contract BalanceSum {

    MockERC20 public token = new MockERC20("Token", "TKN", 18);

    uint256 public sum;

    function mint(address account, uint256 amount) external {
        token.mint(account, amount);
        sum += amount;
    }

    function burn(address account, uint256 amount) external {
        token.burn(account, amount);
        sum -= amount;
    }

    function approve(address dst, uint256 amount) external {
        token.approve(dst, amount);
    }

    function transferFrom(address src, address dst, uint256 amount) external {
        token.transferFrom(src, dst, amount);
    }

    function transfer(address dst, uint256 amount) external {
        token.transfer(dst, amount);
    }

}
