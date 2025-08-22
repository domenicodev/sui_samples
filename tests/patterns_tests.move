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

#[test_only]
module sample::capability_pattern_tests {
    use sample::capability_pattern;
    use sui::test_scenario;

    #[test]
    fun test_basic_capability_pattern() {
        let mut scenario = test_scenario::begin(@0x1);
        
        // Initialize the module (creates Counter and AdminCap for sender)
        {
            let ctx = test_scenario::ctx(&mut scenario);
            capability_pattern::init_for_testing(ctx);
        };
        
        // Admin can increment counter
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let admin_cap = test_scenario::take_from_sender<capability_pattern::AdminCap>(&scenario);
            let mut counter = test_scenario::take_shared<capability_pattern::Counter>(&scenario);
            
            // Initially counter should be 0
            assert!(capability_pattern::get_value(&counter) == 0, 0);
            
            // Admin increments counter
            capability_pattern::increment(&admin_cap, &mut counter);
            assert!(capability_pattern::get_value(&counter) == 1, 1);
            
            // Admin sets counter value
            capability_pattern::set_value(&admin_cap, &mut counter, 42);
            assert!(capability_pattern::get_value(&counter) == 42, 2);
            
            test_scenario::return_to_sender(&scenario, admin_cap);
            test_scenario::return_shared(counter);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_capability_transfer() {
        let mut scenario = test_scenario::begin(@0x1);
        
        // Initialize with admin @0x1
        {
            let ctx = test_scenario::ctx(&mut scenario);
            capability_pattern::init_for_testing(ctx);
        };
        
        // Admin transfers capability to @0x2
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let admin_cap = test_scenario::take_from_sender<capability_pattern::AdminCap>(&scenario);
            
            // Transfer admin capability to @0x2
            transfer::public_transfer(admin_cap, @0x2);
        };
        
        // @0x2 can now use the admin capability
        test_scenario::next_tx(&mut scenario, @0x2);
        {
            let admin_cap = test_scenario::take_from_sender<capability_pattern::AdminCap>(&scenario);
            let mut counter = test_scenario::take_shared<capability_pattern::Counter>(&scenario);
            
            // @0x2 can increment because they have the capability
            capability_pattern::increment(&admin_cap, &mut counter);
            assert!(capability_pattern::get_value(&counter) == 1, 0);
            
            test_scenario::return_to_sender(&scenario, admin_cap);
            test_scenario::return_shared(counter);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_anyone_can_read() {
        let mut scenario = test_scenario::begin(@0x1);
        
        // Initialize
        {
            let ctx = test_scenario::ctx(&mut scenario);
            capability_pattern::init_for_testing(ctx);
        };
        
        // Admin sets counter value
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let admin_cap = test_scenario::take_from_sender<capability_pattern::AdminCap>(&scenario);
            let mut counter = test_scenario::take_shared<capability_pattern::Counter>(&scenario);
            
            capability_pattern::set_value(&admin_cap, &mut counter, 100);
            
            test_scenario::return_to_sender(&scenario, admin_cap);
            test_scenario::return_shared(counter);
        };
        
        // Anyone (@0x2) can read the counter value
        test_scenario::next_tx(&mut scenario, @0x2);
        {
            let counter = test_scenario::take_shared<capability_pattern::Counter>(&scenario);
            
            // @0x2 can read even without admin capability
            assert!(capability_pattern::get_value(&counter) == 100, 0);
            
            test_scenario::return_shared(counter);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_mint_cap() {
        let mut scenario = test_scenario::begin(@0x1);
        
        // Initialize
        {
            let ctx = test_scenario::ctx(&mut scenario);
            capability_pattern::init_for_testing(ctx);
        };
        
        // Admin mints new capability for @0x2
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let admin_cap = test_scenario::take_from_sender<capability_pattern::AdminCap>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            
            // Mint new admin capability for @0x2
            capability_pattern::mint_cap(&admin_cap, @0x2, ctx);
            
            test_scenario::return_to_sender(&scenario, admin_cap);
        };
        
        // @0x2 can now use their new admin capability
        test_scenario::next_tx(&mut scenario, @0x2);
        {
            let admin_cap = test_scenario::take_from_sender<capability_pattern::AdminCap>(&scenario);
            let mut counter = test_scenario::take_shared<capability_pattern::Counter>(&scenario);
            
            // @0x2 can increment because they have admin capability
            capability_pattern::increment(&admin_cap, &mut counter);
            assert!(capability_pattern::get_value(&counter) == 1, 0);
            
            test_scenario::return_to_sender(&scenario, admin_cap);
            test_scenario::return_shared(counter);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_transfer_cap() {
        let mut scenario = test_scenario::begin(@0x1);
        
        // Initialize
        {
            let ctx = test_scenario::ctx(&mut scenario);
            capability_pattern::init_for_testing(ctx);
        };
        
        // Admin transfers their capability to @0x2
        test_scenario::next_tx(&mut scenario, @0x1);
        {
            let admin_cap = test_scenario::take_from_sender<capability_pattern::AdminCap>(&scenario);
            
            // Transfer admin capability to @0x2
            capability_pattern::transfer_cap(admin_cap, @0x2);
        };
        
        // @0x2 now has the admin capability
        test_scenario::next_tx(&mut scenario, @0x2);
        {
            let admin_cap = test_scenario::take_from_sender<capability_pattern::AdminCap>(&scenario);
            let mut counter = test_scenario::take_shared<capability_pattern::Counter>(&scenario);
            
            // @0x2 can use admin functions
            capability_pattern::set_value(&admin_cap, &mut counter, 999);
            assert!(capability_pattern::get_value(&counter) == 999, 0);
            
            test_scenario::return_to_sender(&scenario, admin_cap);
            test_scenario::return_shared(counter);
        };
        
        test_scenario::end(scenario);
    }
}
