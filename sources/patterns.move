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
