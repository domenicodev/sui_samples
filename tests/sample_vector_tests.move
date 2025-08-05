/**
Simple test file containing tests for the sample_vector module.

The tests are written in a way that is easy to understand and follow.
The Move pattern without '{}' is used to show that the modules can be written without it too.

Useful differences between Sui Move and Aptos Move that can be seen in this module:
- The module is initialized with a transaction context, and not with a signer
- To operate with global object, this pattern is used:
    start scenario -> take_from_sender -> mutable edit -> return_to_sender -> end scenario
- When accessing and editing objects multiple times in the same test, scenario::next_tx must be used as
    one object cannot be mutated multiple times in the same transaction.
*/

#[test_only]
module sample_vector::sample_vector_tests;

use sample_vector::sample_vector;
use std::string;
use sui::test_scenario;

const ENotImplemented: u64 = 0;

#[test]
fun test_say_hi() {
    let name = string::utf8(b"Sui");
    let result = sample_vector::say_hi(name);
    assert!(result == string::utf8(b"Sui"), 0);
}

#[test]
fun test_add_user() {
    let mut scenario = test_scenario::begin(@0x1);
    
    // Initialize the module (this creates a Users object with John)
    {
        let ctx = test_scenario::ctx(&mut scenario);
        sample_vector::init_for_testing(ctx);
    };
    
    // Take the Users object from the sender
    test_scenario::next_tx(&mut scenario, @0x1);
    {
        let mut users = test_scenario::take_from_sender<sample_vector::Users>(&scenario);
        
        // Test adding a user
        let name = string::utf8(b"Bob");
        let age = 30;
        let email = string::utf8(b"bob@example.com");
        
        sample_vector::add_user(&mut users, name, age, email);
        
        // Verify the user was added (should have John at index 0, Bob at index 1)
        let (name, age, email) = sample_vector::get_user(&users, 1);
        assert!(name == string::utf8(b"Bob"), 1);
        assert!(age == 30, 2);
        assert!(email == string::utf8(b"bob@example.com"), 3);
        
        test_scenario::return_to_sender(&scenario, users);
    };
    
    test_scenario::end(scenario);
}

#[test]
fun test_add_multiple_users() {
    let mut scenario = test_scenario::begin(@0x1);
    
    // Initialize the module
    {
        let ctx = test_scenario::ctx(&mut scenario);
        sample_vector::init_for_testing(ctx);
    };
    
    // Take the Users object and add multiple users
    test_scenario::next_tx(&mut scenario, @0x1);
    {
        let mut users = test_scenario::take_from_sender<sample_vector::Users>(&scenario);
        
        // Add users (John is already at index 0)
        sample_vector::add_user(&mut users, string::utf8(b"Alice"), 25, string::utf8(b"alice@example.com"));
        sample_vector::add_user(&mut users, string::utf8(b"Bob"), 30, string::utf8(b"bob@example.com"));
        sample_vector::add_user(&mut users, string::utf8(b"Charlie"), 35, string::utf8(b"charlie@example.com"));
        
        // Verify all users (John=0, Alice=1, Bob=2, Charlie=3)
        let (name1, age1, _) = sample_vector::get_user(&users, 1);
        let (name2, age2, _) = sample_vector::get_user(&users, 2);
        let (name3, age3, _) = sample_vector::get_user(&users, 3);
        
        assert!(name1 == string::utf8(b"Alice"), 4);
        assert!(age1 == 25, 5);
        
        assert!(name2 == string::utf8(b"Bob"), 6);
        assert!(age2 == 30, 7);
        
        assert!(name3 == string::utf8(b"Charlie"), 8);
        assert!(age3 == 35, 9);
        
        test_scenario::return_to_sender(&scenario, users);
    };
    
    test_scenario::end(scenario);
}

#[test]
fun test_get_user() {
    let mut scenario = test_scenario::begin(@0x1);
    
    // Initialize the module
    {
        let ctx = test_scenario::ctx(&mut scenario);
        sample_vector::init_for_testing(ctx);
    };
    
    // Take the Users object and test getting users
    test_scenario::next_tx(&mut scenario, @0x1);
    {
        let mut users = test_scenario::take_from_sender<sample_vector::Users>(&scenario);
        
        // Add a test user
        let test_name = string::utf8(b"TestUser");
        let test_age = 42;
        let test_email = string::utf8(b"test@example.com");
        
        sample_vector::add_user(&mut users, test_name, test_age, test_email);
        
        // Get the test user (at index 1, since John is at index 0)
        let (name, age, email) = sample_vector::get_user(&users, 1);
        assert!(name == string::utf8(b"TestUser"), 10);
        assert!(age == 42, 11);
        assert!(email == string::utf8(b"test@example.com"), 12);
        
        test_scenario::return_to_sender(&scenario, users);
    };
    
    test_scenario::end(scenario);
}

#[test]
fun test_remove_user() {
    let mut scenario = test_scenario::begin(@0x1);
    
    // Initialize the module
    {
        let ctx = test_scenario::ctx(&mut scenario);
        sample_vector::init_for_testing(ctx);
    };
    
    // Take the Users object and test user removal
    test_scenario::next_tx(&mut scenario, @0x1);
    {
        let mut users = test_scenario::take_from_sender<sample_vector::Users>(&scenario);
        
        // Add three users (John is already at index 0)
        sample_vector::add_user(&mut users, string::utf8(b"User1"), 20, string::utf8(b"user1@example.com"));
        sample_vector::add_user(&mut users, string::utf8(b"User2"), 25, string::utf8(b"user2@example.com"));
        sample_vector::add_user(&mut users, string::utf8(b"User3"), 30, string::utf8(b"user3@example.com"));
        
        // Verify we have User2 at index 2
        let (name_before, _, _) = sample_vector::get_user(&users, 2);
        assert!(name_before == string::utf8(b"User2"), 13);
        
        // Remove the middle user (index 2)
        sample_vector::remove_user(&mut users, 2);
        
        // Verify the user was removed and remaining users shifted
        let (name_after, _, _) = sample_vector::get_user(&users, 2);
        assert!(name_after == string::utf8(b"User3"), 14); // User3 should now be at index 2
        
        let (first_name, _, _) = sample_vector::get_user(&users, 1);
        assert!(first_name == string::utf8(b"User1"), 15); // User1 should still be at index 1
        
        test_scenario::return_to_sender(&scenario, users);
    };
    
    test_scenario::end(scenario);
}

#[test]
fun test_remove_first_user() {
    let mut scenario = test_scenario::begin(@0x1);
    
    // Initialize the module
    {
        let ctx = test_scenario::ctx(&mut scenario);
        sample_vector::init_for_testing(ctx);
    };
    
    // Take the Users object and test first user removal
    test_scenario::next_tx(&mut scenario, @0x1);
    {
        let mut users = test_scenario::take_from_sender<sample_vector::Users>(&scenario);
        
        // Add two users (John is already at index 0)
        sample_vector::add_user(&mut users, string::utf8(b"First"), 20, string::utf8(b"first@example.com"));
        sample_vector::add_user(&mut users, string::utf8(b"Second"), 25, string::utf8(b"second@example.com"));
        
        // Remove the first user (John at index 0)
        sample_vector::remove_user(&mut users, 0);
        
        // Verify "First" is now at index 0
        let (name, age, _) = sample_vector::get_user(&users, 0);
        assert!(name == string::utf8(b"First"), 16);
        assert!(age == 20, 17);
        
        test_scenario::return_to_sender(&scenario, users);
    };
    
    test_scenario::end(scenario);
}

#[test]
fun test_remove_last_user() {
    let mut scenario = test_scenario::begin(@0x1);
    
    // Initialize the module
    {
        let ctx = test_scenario::ctx(&mut scenario);
        sample_vector::init_for_testing(ctx);
    };
    
    // Take the Users object and test last user removal
    test_scenario::next_tx(&mut scenario, @0x1);
    {
        let mut users = test_scenario::take_from_sender<sample_vector::Users>(&scenario);
        
        // Add two users (John is already at index 0)
        sample_vector::add_user(&mut users, string::utf8(b"First"), 20, string::utf8(b"first@example.com"));
        sample_vector::add_user(&mut users, string::utf8(b"Last"), 25, string::utf8(b"last@example.com"));
        
        // Remove the last user (index 2)
        sample_vector::remove_user(&mut users, 2);
        
        // Verify "First" is still at index 1
        let (name, age, _) = sample_vector::get_user(&users, 1);
        assert!(name == string::utf8(b"First"), 18);
        assert!(age == 20, 19);
        
        test_scenario::return_to_sender(&scenario, users);
    };
    
    test_scenario::end(scenario);
}

#[test]
fun test_user_struct_properties() {
    let mut scenario = test_scenario::begin(@0x1);
    
    // Initialize the module
    {
        let ctx = test_scenario::ctx(&mut scenario);
        sample_vector::init_for_testing(ctx);
    };
    
    // Take the Users object and test user properties
    test_scenario::next_tx(&mut scenario, @0x1);
    {
        let mut users = test_scenario::take_from_sender<sample_vector::Users>(&scenario);
        
        // Add a user with specific properties
        sample_vector::add_user(&mut users, string::utf8(b"Test User"), 100, string::utf8(b"test@domain.co.uk"));
        
        // Get the user and verify properties (at index 1)
        let (name, age, email) = sample_vector::get_user(&users, 1);
        assert!(name == string::utf8(b"Test User"), 20);
        assert!(age == 100, 21);
        assert!(email == string::utf8(b"test@domain.co.uk"), 22);
        
        test_scenario::return_to_sender(&scenario, users);
    };
    
    test_scenario::end(scenario);
}

#[test]
fun test_say_hi_with_different_names() {
    // Test with various names
    let name1 = string::utf8(b"Alice");
    let result1 = sample_vector::say_hi(name1);
    assert!(result1 == string::utf8(b"Alice"), 23);
    
    let name2 = string::utf8(b"Bob Smith");
    let result2 = sample_vector::say_hi(name2);
    assert!(result2 == string::utf8(b"Bob Smith"), 24);
    
    let name3 = string::utf8(b""); // Empty name
    let result3 = sample_vector::say_hi(name3);
    assert!(result3 == string::utf8(b""), 25);
}

#[test]
#[expected_failure]
fun test_get_user_invalid_index() {
    let mut scenario = test_scenario::begin(@0x1);
    
    // Initialize the module
    {
        let ctx = test_scenario::ctx(&mut scenario);
        sample_vector::init_for_testing(ctx);
    };
    
    // Take the Users object and test invalid index
    test_scenario::next_tx(&mut scenario, @0x1);
    {
        let users = test_scenario::take_from_sender<sample_vector::Users>(&scenario);
        
        // Try to get user at invalid index (should fail)
        // We only have John at index 0, so index 1 doesn't exist
        let (_, _, _) = sample_vector::get_user(&users, 1);
        
        test_scenario::return_to_sender(&scenario, users);
    };
    
    test_scenario::end(scenario);
}

#[test]
#[expected_failure]
fun test_remove_user_invalid_index() {
    let mut scenario = test_scenario::begin(@0x1);
    
    // Initialize the module
    {
        let ctx = test_scenario::ctx(&mut scenario);
        sample_vector::init_for_testing(ctx);
    };
    
    // Take the Users object and test invalid index removal
    test_scenario::next_tx(&mut scenario, @0x1);
    {
        let mut users = test_scenario::take_from_sender<sample_vector::Users>(&scenario);
        
        // Try to remove user at invalid index (should fail)
        // We only have John at index 0, so index 1 doesn't exist
        sample_vector::remove_user(&mut users, 1);
        
        test_scenario::return_to_sender(&scenario, users);
    };
    
    test_scenario::end(scenario);
}

// Legacy tests (keeping for compatibility)
#[test]
fun test_first_sui_package() {
    // pass
}

#[test, expected_failure(abort_code = ::sample_vector::sample_vector_tests::ENotImplemented)]
fun test_first_sui_package_fail() {
    abort ENotImplemented
}