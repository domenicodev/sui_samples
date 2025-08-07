/**
 * Tests for the multihop modules with recursive calling pattern
 */

#[test_only]
module sample::multihop_tests {
    use sui::test_scenario;
    use std::string;
    use hop::types::{Self, MyObject};
    use sample::multihop;
    use sample::set_name;
    use sample::set_surname;
    use sample::set_address;

    const ADMIN: address = @0xAD;
    const JOHN: address = @0xC1;
    const RECIPIENT: address = @0xABC;

    #[test]
    fun test_create_my_object() {
        let mut scenario = test_scenario::begin(ADMIN);
        let ctx = test_scenario::ctx(&mut scenario);
        
        let obj = types::new_my_object_for_testing(ctx);
        
        // Check initial values are empty
        assert!(types::get_name(&obj) == string::utf8(b""), 0);
        assert!(types::get_surname(&obj) == string::utf8(b""), 1);
        assert!(types::get_address(&obj) == string::utf8(b""), 2);
        
        // Clean up
        types::handle_transfer(obj, ADMIN);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_multihop_chain() {
        let mut scenario = test_scenario::begin(ADMIN);
        let ctx = test_scenario::ctx(&mut scenario);
        
        let obj = types::new_my_object_for_testing(ctx);
        
        // Start the chain using the multihop module - this is what starts the chain
        multihop::start_multihop_chain(obj, b"John", JOHN);
        
        test_scenario::next_tx(&mut scenario, JOHN);
        
        // Check that the object was transferred to JOHN after the full chain
        assert!(test_scenario::has_most_recent_for_address<MyObject>(JOHN), 0);
        
        let obj = test_scenario::take_from_address<MyObject>(&scenario, JOHN);
        
        // Check all fields were set correctly by the recursive chain
        assert!(types::get_name(&obj) == string::utf8(b"John"), 1);
        assert!(types::get_surname(&obj) == string::utf8(b"Doe"), 2);
        assert!(types::get_address(&obj) == string::utf8(b"Boulevard, 1"), 3);
        
        // Clean up
        test_scenario::return_to_address(JOHN, obj);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_create_and_start_chain() {
        let mut scenario = test_scenario::begin(ADMIN);
        
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            // This is what starts the chain with a new object
            multihop::create_and_start_chain(b"NewObject", JOHN, ctx);
        };
        
        test_scenario::next_tx(&mut scenario, JOHN);
        
        // Check that the object was created and transferred to JOHN
        assert!(test_scenario::has_most_recent_for_address<MyObject>(JOHN), 0);
        
        let obj = test_scenario::take_from_address<MyObject>(&scenario, JOHN);
        
        // Check all fields were set correctly by the recursive chain
        assert!(types::get_name(&obj) == string::utf8(b"NewObject"), 1);
        assert!(types::get_surname(&obj) == string::utf8(b"Doe"), 2);
        assert!(types::get_address(&obj) == string::utf8(b"Boulevard, 1"), 3);
        
        // Clean up
        test_scenario::return_to_address(JOHN, obj);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_name_directly() {
        let mut scenario = test_scenario::begin(ADMIN);
        let ctx = test_scenario::ctx(&mut scenario);
        
        let obj = types::new_my_object_for_testing(ctx);
        
        // Start the chain by calling set_name directly (skipping multihop)
        set_name::set_name(obj, b"DirectName", JOHN);
        
        test_scenario::next_tx(&mut scenario, JOHN);
        
        // Check that the object was transferred to JOHN after the full chain
        assert!(test_scenario::has_most_recent_for_address<MyObject>(JOHN), 0);
        
        let obj = test_scenario::take_from_address<MyObject>(&scenario, JOHN);
        
        // Check all fields were set correctly by the recursive chain
        assert!(types::get_name(&obj) == string::utf8(b"DirectName"), 1);
        assert!(types::get_surname(&obj) == string::utf8(b"Doe"), 2);
        assert!(types::get_address(&obj) == string::utf8(b"Boulevard, 1"), 3);
        
        // Clean up
        test_scenario::return_to_address(JOHN, obj);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_surname_directly() {
        let mut scenario = test_scenario::begin(ADMIN);
        let ctx = test_scenario::ctx(&mut scenario);
        
        let obj = types::new_my_object_for_testing(ctx);
        
        // Start from set_surname (skipping multihop and set_name)
        set_surname::set_surname_entry(obj, b"DirectSurname", RECIPIENT);
        
        test_scenario::next_tx(&mut scenario, RECIPIENT);
        
        // Check that the object was transferred to RECIPIENT
        assert!(test_scenario::has_most_recent_for_address<MyObject>(RECIPIENT), 0);
        
        let obj = test_scenario::take_from_address<MyObject>(&scenario, RECIPIENT);
        
        // Check fields - name should be empty, surname and address should be set
        assert!(types::get_name(&obj) == string::utf8(b""), 1);
        assert!(types::get_surname(&obj) == string::utf8(b"DirectSurname"), 2);
        assert!(types::get_address(&obj) == string::utf8(b"Boulevard, 1"), 3);
        
        // Clean up
        test_scenario::return_to_address(RECIPIENT, obj);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_address_directly() {
        let mut scenario = test_scenario::begin(ADMIN);
        let ctx = test_scenario::ctx(&mut scenario);
        
        let obj = types::new_my_object_for_testing(ctx);
        
        // Start from set_address (skipping all other steps)
        set_address::set_address_entry(obj, b"DirectAddress", RECIPIENT);
        
        test_scenario::next_tx(&mut scenario, RECIPIENT);
        
        // Check that the object was transferred to RECIPIENT
        assert!(test_scenario::has_most_recent_for_address<MyObject>(RECIPIENT), 0);
        
        let obj = test_scenario::take_from_address<MyObject>(&scenario, RECIPIENT);
        
        // Check fields - only address should be set
        assert!(types::get_name(&obj) == string::utf8(b""), 1);
        assert!(types::get_surname(&obj) == string::utf8(b""), 2);
        assert!(types::get_address(&obj) == string::utf8(b"DirectAddress"), 3);
        
        // Clean up
        test_scenario::return_to_address(RECIPIENT, obj);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_multiple_objects() {
        let mut scenario = test_scenario::begin(ADMIN);
        let ctx = test_scenario::ctx(&mut scenario);
        
        // Create and process multiple objects
        let obj1 = types::new_my_object_for_testing(ctx);
        let obj2 = types::new_my_object_for_testing(ctx);
        
        multihop::start_multihop_chain(obj1, b"FirstObject", JOHN);
        multihop::start_multihop_chain(obj2, b"SecondObject", RECIPIENT);
        
        test_scenario::next_tx(&mut scenario, JOHN);
        test_scenario::next_tx(&mut scenario, RECIPIENT);
        
        // Check both objects were processed correctly
        assert!(test_scenario::has_most_recent_for_address<MyObject>(JOHN), 0);
        assert!(test_scenario::has_most_recent_for_address<MyObject>(RECIPIENT), 1);
        
        let obj1 = test_scenario::take_from_address<MyObject>(&scenario, JOHN);
        let obj2 = test_scenario::take_from_address<MyObject>(&scenario, RECIPIENT);
        
        // Check first object
        assert!(types::get_name(&obj1) == string::utf8(b"FirstObject"), 2);
        assert!(types::get_surname(&obj1) == string::utf8(b"Doe"), 3);
        assert!(types::get_address(&obj1) == string::utf8(b"Boulevard, 1"), 4);
        
        // Check second object
        assert!(types::get_name(&obj2) == string::utf8(b"SecondObject"), 5);
        assert!(types::get_surname(&obj2) == string::utf8(b"Doe"), 6);
        assert!(types::get_address(&obj2) == string::utf8(b"Boulevard, 1"), 7);
        
        // Clean up
        test_scenario::return_to_address(JOHN, obj1);
        test_scenario::return_to_address(RECIPIENT, obj2);
        test_scenario::end(scenario);
    }
}