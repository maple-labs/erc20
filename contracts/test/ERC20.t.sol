// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { DSTest } from "../../modules/ds-test/src/test.sol";

import { ERC20User }     from "./accounts/ERC20User.sol";
import { MockERC20 }     from "./mocks/MockERC20.sol";

import { InvariantTest } from "./utils/InvariantTest.sol";
import { Vm }            from "./utils/Vm.sol";

contract ERC20Test is DSTest {

    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    bytes constant ARITHMETIC_ERROR = abi.encodeWithSignature("Panic(uint256)", 0x11);

    MockERC20 token;

    address internal immutable self = address(this);

    function setUp() public virtual {
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

    function test_mint(address account, uint256 amount) public {
        token.mint(account, amount);

        assertEq(token.totalSupply(),      amount);
        assertEq(token.balanceOf(account), amount);
    }

    function test_burn(address account, uint256 amount0, uint256 amount1) public {
        if (amount1 > amount0) return;  // Mint amount must exceed burn amount.

        token.mint(account, amount0);
        token.burn(account, amount1);

        assertEq(token.totalSupply(),      amount0 - amount1);
        assertEq(token.balanceOf(account), amount0 - amount1);
    }

    function test_approve(address account, uint256 amount) public {
        assertTrue(token.approve(account, amount));

        assertEq(token.allowance(self, account), amount);
    }

    function test_transfer(address account, uint256 amount) public {
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

    function test_transferFrom(address to, uint256 approval, uint256 amount) public {
        if (amount > approval) return;  // Owner must approve for more than amount.

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

    function test_transfer_insufficientBalance(address to, uint256 amount) public {
        amount = amount == 0 ? 1 : amount;

        ERC20User account = new ERC20User();

        token.mint(address(account), amount - 1);

        vm.expectRevert(ARITHMETIC_ERROR);
        account.erc20_transfer(address(token), to, amount);

        token.mint(address(account), 1);
        account.erc20_transfer(address(token), to, amount);

        assertEq(token.balanceOf(to), amount);
    }

    function test_transferFrom_insufficientAllowance(address to, uint256 amount) public {
        amount = amount == 0 ? 1 : amount;

        ERC20User owner = new ERC20User();

        token.mint(address(owner), amount);

        owner.erc20_approve(address(token), self, amount - 1);

        vm.expectRevert(ARITHMETIC_ERROR);
        token.transferFrom(address(owner), to, amount);

        owner.erc20_approve(address(token), self, amount);
        token.transferFrom(address(owner), to, amount);

        assertEq(token.balanceOf(to), amount);
    }

    function test_transferFrom_insufficientBalance(address to, uint256 amount) public {
        amount = amount == 0 ? 1 : amount;

        ERC20User owner = new ERC20User();

        token.mint(address(owner), amount - 1);
        owner.erc20_approve(address(token), self, amount);

        vm.expectRevert(ARITHMETIC_ERROR);
        token.transferFrom(address(owner), to, amount);

        token.mint(address(owner), 1);
        token.transferFrom(address(owner), to, amount);

        assertEq(token.balanceOf(to), amount);
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
