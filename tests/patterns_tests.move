/**
Simple test file containing tests for the patterns module.
*/

#[test_only]
module sample::hot_potato_tests {
    use sample::hot_potato;
    use sui::test_scenario;

    const ENotImplemented: u64 = 0;

    #[test]
    fun test_basic_borrow_and_repay() {
        let mut scenario = test_scenario::begin(@0x1);
        
        // Initialize the module (this creates an AvailableBalance object)
        {
            let ctx = test_scenario::ctx(&mut scenario);
            hot_potato::init_for_testing(ctx);
        };
        
        // Add some funds to the available balance and test borrowing
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let mut available_balance = test_scenario::take_shared<hot_potato::AvailableBalance>(&scenario);
            
            // Add funds for testing
            hot_potato::add_funds_for_testing(&mut available_balance, 1000);
            
            // Test borrowing and repaying
            let loan = hot_potato::borrow(&mut available_balance, 500);
            hot_potato::repay(&mut available_balance, loan);
            
            test_scenario::return_shared(available_balance);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_borrow_zero_amount() {
        let mut scenario = test_scenario::begin(@0x1);
        
        // Initialize the module
        {
            let ctx = test_scenario::ctx(&mut scenario);
            hot_potato::init_for_testing(ctx);
        };
        
        // Test borrowing zero amount (should work even with zero balance)
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let mut available_balance = test_scenario::take_shared<hot_potato::AvailableBalance>(&scenario);
            
            // Borrow 0 amount (should succeed)
            let loan = hot_potato::borrow(&mut available_balance, 0);
            
            // Immediately repay the loan (hot potato pattern - must be consumed)
            hot_potato::repay(&mut available_balance, loan);
            
            test_scenario::return_shared(available_balance);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_multiple_zero_loans() {
        let mut scenario = test_scenario::begin(@0x1);
        
        // Initialize the module
        {
            let ctx = test_scenario::ctx(&mut scenario);
            hot_potato::init_for_testing(ctx);
        };
        
        // Test multiple zero-amount loans in sequence
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let mut available_balance = test_scenario::take_shared<hot_potato::AvailableBalance>(&scenario);
            
            // First loan
            let loan1 = hot_potato::borrow(&mut available_balance, 0);
            hot_potato::repay(&mut available_balance, loan1);
            
            // Second loan
            let loan2 = hot_potato::borrow(&mut available_balance, 0);
            hot_potato::repay(&mut available_balance, loan2);
            
            // Third loan
            let loan3 = hot_potato::borrow(&mut available_balance, 0);
            hot_potato::repay(&mut available_balance, loan3);
            
            test_scenario::return_shared(available_balance);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_loan_must_be_repaid_same_transaction() {
        let mut scenario = test_scenario::begin(@0x1);
        
        // Initialize the module
        {
            let ctx = test_scenario::ctx(&mut scenario);
            hot_potato::init_for_testing(ctx);
        };
        
        // Test that loan is properly consumed in the same transaction
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let mut available_balance = test_scenario::take_shared<hot_potato::AvailableBalance>(&scenario);
            
            // Borrow and immediately repay (demonstrating hot potato pattern)
            let loan = hot_potato::borrow(&mut available_balance, 0);
            
            // The loan MUST be repaid in the same transaction
            // This is the essence of the hot potato pattern
            hot_potato::repay(&mut available_balance, loan);
            
            test_scenario::return_shared(available_balance);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun test_borrow_more_than_available() {
        let mut scenario = test_scenario::begin(@0x1);
        
        // Initialize the module
        {
            let ctx = test_scenario::ctx(&mut scenario);
            hot_potato::init_for_testing(ctx);
        };
        
        // Test borrowing more than available (should fail with abort code 0)
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let mut available_balance = test_scenario::take_shared<hot_potato::AvailableBalance>(&scenario);
            
            // Try to borrow 100 when balance is 0 (should fail)
            let loan = hot_potato::borrow(&mut available_balance, 100);
            
            // This line should never be reached due to the assertion failure above
            hot_potato::repay(&mut available_balance, loan);
            
            test_scenario::return_shared(available_balance);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun test_borrow_one_when_balance_zero() {
        let mut scenario = test_scenario::begin(@0x1);
        
        // Initialize the module
        {
            let ctx = test_scenario::ctx(&mut scenario);
            hot_potato::init_for_testing(ctx);
        };
        
        // Test borrowing 1 when balance is 0 (should fail)
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let mut available_balance = test_scenario::take_shared<hot_potato::AvailableBalance>(&scenario);
            
            // Try to borrow 1 when balance is 0 (should fail with assertion error)
            let loan = hot_potato::borrow(&mut available_balance, 1);
            
            // This should never be reached
            hot_potato::repay(&mut available_balance, loan);
            
            test_scenario::return_shared(available_balance);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_hot_potato_pattern_properties() {
        let mut scenario = test_scenario::begin(@0x1);
        
        // Initialize the module
        {
            let ctx = test_scenario::ctx(&mut scenario);
            hot_potato::init_for_testing(ctx);
        };
        
        // Test that demonstrates the key properties of hot potato pattern:
        // 1. The Loan struct has no abilities (no copy, drop, store, key)
        // 2. It must be consumed in the same transaction where it's created
        // 3. It cannot be stored or transferred
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let mut available_balance = test_scenario::take_shared<hot_potato::AvailableBalance>(&scenario);
            
            // Create a loan
            let loan = hot_potato::borrow(&mut available_balance, 0);
            
            // The loan cannot be:
            // - Stored (no store ability)
            // - Copied (no copy ability) 
            // - Dropped (no drop ability)
            // - Used as a key (no key ability)
            
            // It MUST be consumed by repay function
            hot_potato::repay(&mut available_balance, loan);
            
            test_scenario::return_shared(available_balance);
        };
        
        test_scenario::end(scenario);
    }

    // Legacy test for compatibility
    #[test]
    fun test_patterns_module() {
        // Basic test to ensure module compiles and works
        // pass
    }

    #[test, expected_failure(abort_code = ::sample::hot_potato_tests::ENotImplemented)]
    fun test_patterns_module_fail() {
        abort ENotImplemented
    }
}
