/**
 * Simple Tests for Transfer Policy Rules
 * 
 * Tests the 3 basic rules without complex transfer policy setup:
 * 1. Witness Rule
 * 2. Fee Rule  
 * 3. Time Rule
 */

#[test_only]
module sample::transfer_policy_tests {
    use sui::test_scenario::{Self as test};
    use sui::transfer_policy::{Self as policy};
    use sui::coin::{Self};
    use sui::sui::SUI;
    use sui::clock::{Self};
    use sample::transfer_policy_simple::{
        Self as tp,
        ExampleNFT,
        AdminWitness,
    };

    // Test addresses
    const ADMIN: address = @0xA;
    const USER: address = @0xB;

    #[test]
    /// Test creating NFT and witnesses
    fun test_basic_creation() {
        let mut scenario = test::begin(ADMIN);
        
        // Test NFT creation
        let nft = tp::create_nft_for_testing(test::ctx(&mut scenario));
        assert!(tp::nft_name(&nft) == &std::string::utf8(b"Test NFT"));
        
        // Test witness creation
        let admin_witness = tp::create_admin_witness();
        let user_witness = tp::create_user_witness();
        
        // Clean up witnesses using helper functions
        tp::destroy_admin_witness_for_testing(admin_witness);
        tp::destroy_user_witness_for_testing(user_witness);
        
        // Clean up NFT (transfer to sender since it wasn't taken from them)
        sui::transfer::public_transfer(nft, ADMIN);
        test::end(scenario);
    }

    #[test]
    /// Test witness rule setup
    fun test_witness_rule_setup() {
        let mut scenario = test::begin(ADMIN);
        
        // Initialize the module (creates policy and cap automatically)
        tp::init_for_testing(test::ctx(&mut scenario));
        
        // Move to next transaction to access the created objects
        test::next_tx(&mut scenario, ADMIN);
        
        // Take the policy and cap that were created in init
        let mut policy = test::take_shared<policy::TransferPolicy<ExampleNFT>>(&scenario);
        let cap = test::take_from_sender<policy::TransferPolicyCap<ExampleNFT>>(&scenario);
        
        // Add witness rule - this should not fail
        tp::add_witness_rule<ExampleNFT, AdminWitness>(&mut policy, &cap);
        
        // Return objects
        test::return_shared(policy);
        test::return_to_sender(&scenario, cap);
        test::end(scenario);
    }

    #[test]
    /// Test fee rule setup
    fun test_fee_rule_setup() {
        let mut scenario = test::begin(ADMIN);
        
        // Initialize the module
        tp::init_for_testing(test::ctx(&mut scenario));
        test::next_tx(&mut scenario, ADMIN);
        
        // Take the policy and cap
        let mut policy = test::take_shared<policy::TransferPolicy<ExampleNFT>>(&scenario);
        let cap = test::take_from_sender<policy::TransferPolicyCap<ExampleNFT>>(&scenario);
        
        // Add fee rule - this should not fail
        let fee_amount = 100;
        tp::add_fee_rule(&mut policy, &cap, fee_amount);
        
        // Return objects
        test::return_shared(policy);
        test::return_to_sender(&scenario, cap);
        test::end(scenario);
    }

    #[test]
    /// Test time rule setup
    fun test_time_rule_setup() {
        let mut scenario = test::begin(ADMIN);
        
        // Initialize the module
        tp::init_for_testing(test::ctx(&mut scenario));
        test::next_tx(&mut scenario, ADMIN);
        
        // Take the policy and cap
        let mut policy = test::take_shared<policy::TransferPolicy<ExampleNFT>>(&scenario);
        let cap = test::take_from_sender<policy::TransferPolicyCap<ExampleNFT>>(&scenario);
        
        // Add time rule - this should not fail
        let start_time = 1000;
        tp::add_time_rule(&mut policy, &cap, start_time);
        
        // Return objects
        test::return_shared(policy);
        test::return_to_sender(&scenario, cap);
        test::end(scenario);
    }

    #[test]
    /// Test multiple rules setup
    fun test_multiple_rules_setup() {
        let mut scenario = test::begin(ADMIN);
        
        // Initialize the module
        tp::init_for_testing(test::ctx(&mut scenario));
        test::next_tx(&mut scenario, ADMIN);
        
        // Take the policy and cap
        let mut policy = test::take_shared<policy::TransferPolicy<ExampleNFT>>(&scenario);
        let cap = test::take_from_sender<policy::TransferPolicyCap<ExampleNFT>>(&scenario);
        
        // Add all three rules
        tp::add_witness_rule<ExampleNFT, AdminWitness>(&mut policy, &cap);
        tp::add_fee_rule(&mut policy, &cap, 200);
        tp::add_time_rule(&mut policy, &cap, 1000);
        
        // Return objects
        test::return_shared(policy);
        test::return_to_sender(&scenario, cap);
        test::end(scenario);
    }

    #[test]
    /// Test clock functionality
    fun test_clock_operations() {
        let mut scenario = test::begin(USER);
        
        // Create clock for testing
        let mut clock = clock::create_for_testing(test::ctx(&mut scenario));
        
        // Test setting time
        clock::set_for_testing(&mut clock, 1500);
        assert!(clock::timestamp_ms(&clock) == 1500);
        
        // Test incrementing time
        clock::increment_for_testing(&mut clock, 500);
        assert!(clock::timestamp_ms(&clock) == 2000);
        
        // Clean up
        clock::destroy_for_testing(clock);
        test::end(scenario);
    }

    #[test]
    /// Test coin operations
    fun test_coin_operations() {
        let mut scenario = test::begin(USER);
        
        // Create test coin
        let mut coin = coin::mint_for_testing<SUI>(1000, test::ctx(&mut scenario));
        assert!(coin::value(&coin) == 1000);
        
        // Split coin
        let coin2 = coin::split(&mut coin, 300, test::ctx(&mut scenario));
        assert!(coin::value(&coin) == 700);
        assert!(coin::value(&coin2) == 300);
        
        // Join coins back
        coin::join(&mut coin, coin2);
        assert!(coin::value(&coin) == 1000);
        
        // Clean up
        coin::burn_for_testing(coin);
        test::end(scenario);
    }

    #[test]
    /// Test transfer with witness enforcement
    fun test_transfer_with_witness() {
        let mut scenario = test::begin(ADMIN);
        
        // Initialize module and set up policy with witness rule
        tp::init_for_testing(test::ctx(&mut scenario));
        test::next_tx(&mut scenario, ADMIN);
        
        let mut policy = test::take_shared<policy::TransferPolicy<ExampleNFT>>(&scenario);
        let cap = test::take_from_sender<policy::TransferPolicyCap<ExampleNFT>>(&scenario);
        
        // Add witness rule
        tp::add_witness_rule<ExampleNFT, AdminWitness>(&mut policy, &cap);
        
        // Test the transfer enforcement
        let nft = tp::create_nft_for_testing(test::ctx(&mut scenario));
        let item_id = object::id(&nft);
        let admin_witness = tp::create_admin_witness();
        
        // This should succeed - we have the required witness
        tp::transfer_with_witness<ExampleNFT, AdminWitness>(
            &policy, 
            admin_witness, 
            item_id, 
            1000, 
            object::id_from_address(@0x123)
        );
        
        // Clean up
        sui::transfer::public_transfer(nft, ADMIN);
        test::return_shared(policy);
        test::return_to_sender(&scenario, cap);
        test::end(scenario);
    }

    #[test]
    /// Test transfer with fee enforcement
    fun test_transfer_with_fee() {
        let mut scenario = test::begin(ADMIN);
        
        // Initialize and set up policy with fee rule
        tp::init_for_testing(test::ctx(&mut scenario));
        test::next_tx(&mut scenario, ADMIN);
        
        let mut policy = test::take_shared<policy::TransferPolicy<ExampleNFT>>(&scenario);
        let cap = test::take_from_sender<policy::TransferPolicyCap<ExampleNFT>>(&scenario);
        
        // Add fee rule (100 MIST)
        tp::add_fee_rule(&mut policy, &cap, 100);
        
        // Test the transfer enforcement
        let nft = tp::create_nft_for_testing(test::ctx(&mut scenario));
        let item_id = object::id(&nft);
        let payment = coin::mint_for_testing<SUI>(100, test::ctx(&mut scenario));
        
        // This should succeed - we pay the required fee
        tp::transfer_with_fee<ExampleNFT>(
            &mut policy, 
            payment, 
            item_id, 
            1000, 
            object::id_from_address(@0x123)
        );
        
        // Clean up
        sui::transfer::public_transfer(nft, ADMIN);
        test::return_shared(policy);
        test::return_to_sender(&scenario, cap);
        test::end(scenario);
    }

    #[test]
    /// Test transfer with time enforcement
    fun test_transfer_with_time() {
        let mut scenario = test::begin(ADMIN);
        
        // Initialize and set up policy with time rule
        tp::init_for_testing(test::ctx(&mut scenario));
        test::next_tx(&mut scenario, ADMIN);
        
        let mut policy = test::take_shared<policy::TransferPolicy<ExampleNFT>>(&scenario);
        let cap = test::take_from_sender<policy::TransferPolicyCap<ExampleNFT>>(&scenario);
        
        // Add time rule (allow transfers after timestamp 1000)
        tp::add_time_rule(&mut policy, &cap, 1000);
        
        // Test the transfer enforcement
        let nft = tp::create_nft_for_testing(test::ctx(&mut scenario));
        let item_id = object::id(&nft);
        
        // Create clock with time after the allowed time
        let mut clock = clock::create_for_testing(test::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 2000);
        
        // This should succeed - current time is after start_time
        tp::transfer_with_time_check<ExampleNFT>(
            &policy, 
            &clock, 
            item_id, 
            1000, 
            object::id_from_address(@0x123)
        );
        
        // Clean up
        sui::transfer::public_transfer(nft, ADMIN);
        clock::destroy_for_testing(clock);
        test::return_shared(policy);
        test::return_to_sender(&scenario, cap);
        test::end(scenario);
    }

    #[test]
    /// Test transfer with ALL rules enforcement
    fun test_transfer_with_all_rules() {
        let mut scenario = test::begin(ADMIN);
        
        // Initialize and set up policy with all rules
        tp::init_for_testing(test::ctx(&mut scenario));
        test::next_tx(&mut scenario, ADMIN);
        
        let mut policy = test::take_shared<policy::TransferPolicy<ExampleNFT>>(&scenario);
        let cap = test::take_from_sender<policy::TransferPolicyCap<ExampleNFT>>(&scenario);
        
        // Add all three rules
        tp::add_witness_rule<ExampleNFT, AdminWitness>(&mut policy, &cap);
        tp::add_fee_rule(&mut policy, &cap, 200);
        tp::add_time_rule(&mut policy, &cap, 1000);
        
        // Test the transfer enforcement with all requirements
        let nft = tp::create_nft_for_testing(test::ctx(&mut scenario));
        let item_id = object::id(&nft);
        let admin_witness = tp::create_admin_witness();
        let payment = coin::mint_for_testing<SUI>(200, test::ctx(&mut scenario));
        
        let mut clock = clock::create_for_testing(test::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 1500);
        
        // This should succeed - we satisfy all rules
        tp::transfer_with_all_rules<ExampleNFT, AdminWitness>(
            &mut policy,
            admin_witness,
            payment,
            &clock,
            item_id,
            1000,
            object::id_from_address(@0x123)
        );
        
        // Clean up
        sui::transfer::public_transfer(nft, ADMIN);
        clock::destroy_for_testing(clock);
        test::return_shared(policy);
        test::return_to_sender(&scenario, cap);
        test::end(scenario);
    }

    #[test]
    /// Test complete transfer flow with rule satisfaction
    fun test_complete_transfer_flow() {
        let mut scenario = test::begin(ADMIN);
        
        // Set up policy with all rules
        tp::init_for_testing(test::ctx(&mut scenario));
        test::next_tx(&mut scenario, ADMIN);
        
        let mut policy = test::take_shared<policy::TransferPolicy<ExampleNFT>>(&scenario);
        let cap = test::take_from_sender<policy::TransferPolicyCap<ExampleNFT>>(&scenario);
        
        // Add all rules
        tp::add_witness_rule<ExampleNFT, AdminWitness>(&mut policy, &cap);
        tp::add_fee_rule(&mut policy, &cap, 100);
        tp::add_time_rule(&mut policy, &cap, 1000);
        
        // Create a transfer request
        let item_id = object::id_from_address(@0x456);
        let mut request = tp::create_transfer_request<ExampleNFT>(
            item_id,
            1000,
            object::id_from_address(@0x123)
        );
        
        // Satisfy all rules
        let admin_witness = tp::create_admin_witness();
        tp::confirm_witness(admin_witness, &policy, &mut request);
        
        let payment = coin::mint_for_testing<SUI>(100, test::ctx(&mut scenario));
        tp::pay_fee(&mut policy, &mut request, payment);
        
        let mut clock = clock::create_for_testing(test::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 1500);
        tp::confirm_time(&policy, &mut request, &clock);
        
        // Complete the transfer - this will succeed because all rules are satisfied
        tp::complete_transfer(&policy, request);
        
        // Clean up
        clock::destroy_for_testing(clock);
        test::return_shared(policy);
        test::return_to_sender(&scenario, cap);
        test::end(scenario);
    }

    #[test]
    #[expected_failure] // This should fail because fake_confirm_witness doesn't add receipt
    /// Test that using fake witness function fails (no receipt added)
    fun test_fake_witness_fails() {
        let mut scenario = test::begin(ADMIN);
        
        // Set up policy with witness rule
        tp::init_for_testing(test::ctx(&mut scenario));
        test::next_tx(&mut scenario, ADMIN);
        
        let mut policy = test::take_shared<policy::TransferPolicy<ExampleNFT>>(&scenario);
        let cap = test::take_from_sender<policy::TransferPolicyCap<ExampleNFT>>(&scenario);
        
        // Add witness rule
        tp::add_witness_rule<ExampleNFT, AdminWitness>(&mut policy, &cap);
        
        // Create transfer request
        let item_id = object::id_from_address(@0x456);
        let mut request = tp::create_transfer_request<ExampleNFT>(
            item_id,
            1000,
            object::id_from_address(@0x123)
        );
        
        // Use FAKE witness function (doesn't add receipt)
        let admin_witness = tp::create_admin_witness();
        tp::fake_confirm_witness(admin_witness, &policy, &mut request);
        
        // This should FAIL because no receipt was added
        tp::complete_transfer(&policy, request); // 💥 Should abort here
        
        // Clean up (won't reach here due to expected failure)
        test::return_shared(policy);
        test::return_to_sender(&scenario, cap);
        test::end(scenario);
    }

    #[test]
    #[expected_failure] // This should fail because fake_pay_fee doesn't add receipt
    /// Test that using fake fee function fails (no receipt added)
    fun test_fake_fee_fails() {
        let mut scenario = test::begin(ADMIN);
        
        // Set up policy with fee rule
        tp::init_for_testing(test::ctx(&mut scenario));
        test::next_tx(&mut scenario, ADMIN);
        
        let mut policy = test::take_shared<policy::TransferPolicy<ExampleNFT>>(&scenario);
        let cap = test::take_from_sender<policy::TransferPolicyCap<ExampleNFT>>(&scenario);
        
        // Add fee rule
        tp::add_fee_rule(&mut policy, &cap, 100);
        
        // Create transfer request
        let item_id = object::id_from_address(@0x456);
        let mut request = tp::create_transfer_request<ExampleNFT>(
            item_id,
            1000,
            object::id_from_address(@0x123)
        );
        
        // Use FAKE fee function (doesn't add receipt)
        let payment = coin::mint_for_testing<SUI>(100, test::ctx(&mut scenario));
        tp::fake_pay_fee(&mut policy, &mut request, payment);
        
        // This should FAIL because no receipt was added
        tp::complete_transfer(&policy, request); // 💥 Should abort here
        
        // Clean up (won't reach here due to expected failure)
        test::return_shared(policy);
        test::return_to_sender(&scenario, cap);
        test::end(scenario);
    }

    #[test]
    #[expected_failure] // This should fail because fake_confirm_time doesn't add receipt
    /// Test that using fake time function fails (no receipt added)
    fun test_fake_time_fails() {
        let mut scenario = test::begin(ADMIN);
        
        // Set up policy with time rule
        tp::init_for_testing(test::ctx(&mut scenario));
        test::next_tx(&mut scenario, ADMIN);
        
        let mut policy = test::take_shared<policy::TransferPolicy<ExampleNFT>>(&scenario);
        let cap = test::take_from_sender<policy::TransferPolicyCap<ExampleNFT>>(&scenario);
        
        // Add time rule
        tp::add_time_rule(&mut policy, &cap, 1000);
        
        // Create transfer request
        let item_id = object::id_from_address(@0x456);
        let mut request = tp::create_transfer_request<ExampleNFT>(
            item_id,
            1000,
            object::id_from_address(@0x123)
        );
        
        // Use FAKE time function (doesn't add receipt)
        let mut clock = clock::create_for_testing(test::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, 1500);
        tp::fake_confirm_time(&policy, &mut request, &clock);
        
        // This should FAIL because no receipt was added
        tp::complete_transfer(&policy, request); // 💥 Should abort here
        
        // Clean up (won't reach here due to expected failure)
        clock::destroy_for_testing(clock);
        test::return_shared(policy);
        test::return_to_sender(&scenario, cap);
        test::end(scenario);
    }

    #[test]
    #[expected_failure] // This should fail - mix of real and fake functions
    /// Test mixing real and fake functions fails
    fun test_mixed_real_and_fake_fails() {
        let mut scenario = test::begin(ADMIN);
        
        // Set up policy with multiple rules
        tp::init_for_testing(test::ctx(&mut scenario));
        test::next_tx(&mut scenario, ADMIN);
        
        let mut policy = test::take_shared<policy::TransferPolicy<ExampleNFT>>(&scenario);
        let cap = test::take_from_sender<policy::TransferPolicyCap<ExampleNFT>>(&scenario);
        
        // Add multiple rules
        tp::add_witness_rule<ExampleNFT, AdminWitness>(&mut policy, &cap);
        tp::add_fee_rule(&mut policy, &cap, 100);
        
        // Create transfer request
        let item_id = object::id_from_address(@0x456);
        let mut request = tp::create_transfer_request<ExampleNFT>(
            item_id,
            1000,
            object::id_from_address(@0x123)
        );
        
        // Use REAL witness function (adds receipt) ✅
        let admin_witness = tp::create_admin_witness();
        tp::confirm_witness(admin_witness, &policy, &mut request);
        
        // Use FAKE fee function (doesn't add receipt) ❌
        let payment = coin::mint_for_testing<SUI>(100, test::ctx(&mut scenario));
        tp::fake_pay_fee(&mut policy, &mut request, payment);
        
        // This should FAIL because fee receipt is missing
        tp::complete_transfer(&policy, request); // 💥 Should abort here
        
        // Clean up (won't reach here due to expected failure)
        test::return_shared(policy);
        test::return_to_sender(&scenario, cap);
        test::end(scenario);
    }

    #[test]
    /// Test withdrawing fees from transfer policy
    fun test_withdraw_fees() {
        let mut scenario = test::begin(ADMIN);
        
        // Initialize and set up policy with fee rule
        tp::init_for_testing(test::ctx(&mut scenario));
        test::next_tx(&mut scenario, ADMIN);
        
        let mut policy = test::take_shared<policy::TransferPolicy<ExampleNFT>>(&scenario);
        let cap = test::take_from_sender<policy::TransferPolicyCap<ExampleNFT>>(&scenario);
        
        // Add fee rule (100 MIST)
        tp::add_fee_rule(&mut policy, &cap, 100);
        
        // Make several fee payments to accumulate balance
        let nft = tp::create_nft_for_testing(test::ctx(&mut scenario));
        let item_id = object::id(&nft);
        
        // First payment
        let payment1 = coin::mint_for_testing<SUI>(100, test::ctx(&mut scenario));
        tp::transfer_with_fee<ExampleNFT>(
            &mut policy, 
            payment1, 
            item_id, 
            1000, 
            object::id_from_address(@0x123)
        );
        
        // Second payment
        let payment2 = coin::mint_for_testing<SUI>(150, test::ctx(&mut scenario));
        tp::transfer_with_fee<ExampleNFT>(
            &mut policy, 
            payment2, 
            item_id, 
            1000, 
            object::id_from_address(@0x124)
        );
        
        // Now withdraw partial amount (100 MIST)
        let withdrawn_partial = tp::withdraw_fees<ExampleNFT>(
            &mut policy, 
            &cap, 
            std::option::some(100), 
            test::ctx(&mut scenario)
        );
        assert!(coin::value(&withdrawn_partial) == 100);
        
        // Withdraw remaining balance (all remaining funds)
        let withdrawn_all = tp::withdraw_fees<ExampleNFT>(
            &mut policy, 
            &cap, 
            std::option::none(), 
            test::ctx(&mut scenario)
        );
        assert!(coin::value(&withdrawn_all) == 150); // 250 total - 100 already withdrawn
        
        // Clean up
        coin::burn_for_testing(withdrawn_partial);
        coin::burn_for_testing(withdrawn_all);
        sui::transfer::public_transfer(nft, ADMIN);
        test::return_shared(policy);
        test::return_to_sender(&scenario, cap);
        test::end(scenario);
    }
}