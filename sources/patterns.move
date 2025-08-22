/**
 *
 * Collection of useful patterns/ (Hot Potato, Capability Design, ...)
 *
 */

/// Hot potato pattern sample in Flash Loan scenario
module sample::hot_potato {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;

    public struct Loan {
        value: u64
    }

    public struct AvailableBalance has key {
        id: UID,
        amount: u64
    }

    fun init(ctx: &mut TxContext) {
        let available_balance = AvailableBalance {
            id: object::new(ctx),
            amount: 0
        };

        transfer::share_object(available_balance);
    }

    /// Initiates the loan by borrowing
    public fun borrow(available_balance: &mut AvailableBalance, amount: u64): Loan {
        assert!(amount <= available_balance.amount, 0);

        available_balance.amount = available_balance.amount - amount;
        
        let loan = Loan { value: amount };
        loan
    }

    /// Repay loan
    public fun repay(available_balance: &mut AvailableBalance, loan: Loan) {
        available_balance.amount = available_balance.amount + loan.value;
        
        let Loan { .. } = loan; // Destruct the loan
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }

    #[test_only]
    public fun add_funds_for_testing(available_balance: &mut AvailableBalance, amount: u64) {
        available_balance.amount = available_balance.amount + amount;
    }

}

/// Capability pattern sample for simple access control
module sample::capability_pattern {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;

    /// Admin capability - only holders can perform admin actions
    public struct AdminCap has key, store {
        id: UID,
    }

    /// A simple counter that can be modified
    public struct Counter has key {
        id: UID,
        value: u64,
    }

    fun init(ctx: &mut TxContext) {
        let counter = Counter {
            id: object::new(ctx),
            value: 0
        };

        let admin_cap = AdminCap {
            id: object::new(ctx),
        };

        transfer::share_object(counter);
        transfer::transfer(admin_cap, tx_context::sender(ctx));
    }

    /// Only admin can increment the counter
    public fun increment(_admin_cap: &AdminCap, counter: &mut Counter) {
        counter.value = counter.value + 1;
    }

    /// Only admin can set counter value
    public fun set_value(_admin_cap: &AdminCap, counter: &mut Counter, new_value: u64) {
        counter.value = new_value;
    }

    /// Anyone can read the counter value
    public fun get_value(counter: &Counter): u64 {
        counter.value
    }

    /// Only admin can mint new admin capabilities
    public fun mint_cap(_admin_cap: &AdminCap, to: address, ctx: &mut TxContext) {
        let new_admin_cap = AdminCap {
            id: object::new(ctx),
        };
        transfer::transfer(new_admin_cap, to);
    }

    /// Transfer admin capability to another address
    public fun transfer_cap(admin_cap: AdminCap, to: address) {
        transfer::transfer(admin_cap, to);
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }

    #[test_only]
    public fun create_admin_cap_for_testing(ctx: &mut TxContext): AdminCap {
        AdminCap {
            id: object::new(ctx),
        }
    }
}
