/**
 * Multihop file containing separate modules with recursive calling pattern
 * 
 * This is a very simple example on how to manipulate objects across multiple modules
 * and eventually transfer to another user. The flow is:
 * multihop -> set_name -> set_surname -> set_address -> transfer
 * 
 * Each module calls the next one in the chain, demonstrating cross-module communication
 * and object manipulation. The object gets modified at each step before being transferred
 * to the final recipient.
 *
 */

// Types module, separated from the others (deployed under another address/package) for deeper complexity
// Contains the MyObject struct and the functions to create and modify it
module hop::types {
    use sui::object::UID;
    use std::string::String;
    use sui::transfer;

    /// MyObject represents an object that can be processed through multiple steps
    /// It contains personal information that can be updated through different modules
    public struct MyObject has key {
        id: UID,
        name: String,
        surname: String,
        address: String,
    }

    /// Creates a new MyObject with empty fields
    public fun new_my_object(ctx: &mut sui::tx_context::TxContext): MyObject {
        MyObject {
            id: sui::object::new(ctx),
            name: std::string::utf8(b""),
            surname: std::string::utf8(b""),
            address: std::string::utf8(b""),
        }
    }

    /// Getter functions for accessing object fields
    public fun get_name(obj: &MyObject): String {
        obj.name
    }

    public fun get_surname(obj: &MyObject): String {
        obj.surname
    }

    public fun get_address(obj: &MyObject): String {
        obj.address
    }

    /// Public setter functions for cross-package access
    public fun set_name_internal(obj: &mut MyObject, name: String) {
        obj.name = name;
    }

    public fun set_surname_internal(obj: &mut MyObject, surname: String) {
        obj.surname = surname;
    }

    public fun set_address_internal(obj: &mut MyObject, address: String) {
        obj.address = address;
    }

    public fun handle_transfer(obj: MyObject, recipient: address) {
        transfer::transfer(obj, recipient);
    }

    #[test_only]
    public fun new_my_object_for_testing(ctx: &mut sui::tx_context::TxContext): MyObject {
        new_my_object(ctx)
    }
}

// Multihop module, contains the entry point for the multihop process
module sample::multihop {
    use hop::types::{Self, MyObject};

    /// This is what starts the chain - entry point for the multihop process
    public entry fun start_multihop_chain(obj: MyObject, name: vector<u8>, recipient: address) {
        // Start the recursive chain by calling set_name module
        sample::set_name::set_name(obj, name, recipient);
    }

    /// Alternative entry that creates a new object and starts the chain
    public entry fun create_and_start_chain(name: vector<u8>, recipient: address, ctx: &mut sui::tx_context::TxContext) {
        let obj = types::new_my_object(ctx);
        // This starts the chain with the newly created object
        start_multihop_chain(obj, name, recipient);
    }
}

// Set name module, contains the function to set the name field
module sample::set_name {
    use hop::types::{Self, MyObject};
    use std::string;
    use sample::set_surname;

    /// Second step in the chain: Sets the name field and continues the recursive chain
    public entry fun set_name(obj: MyObject, name: vector<u8>, recipient: address) {
        let mut obj = obj;
        let name_string = string::utf8(name);
        types::set_name_internal(&mut obj, name_string);
        
        // Recursively call set_surname module
        set_surname::set_surname(obj, b"Doe", recipient);
    }

    /// Public function version for internal calls
    public fun set_name_internal(mut obj: MyObject, name: vector<u8>, recipient: address) {
        let name_string = string::utf8(name);
        types::set_name_internal(&mut obj, name_string);
        
        // Recursively call set_surname module
        set_surname::set_surname(obj, b"Doe", recipient);
    }

    /// Entry function to create a new object and start the chain
    public entry fun create_and_process(name: vector<u8>, recipient: address, ctx: &mut sui::tx_context::TxContext) {
        let obj = types::new_my_object(ctx);
        set_name(obj, name, recipient);
    }
}

// Set surname module, contains the function to set the surname field
module sample::set_surname {
    use hop::types::{Self, MyObject};
    use std::string;
    use sample::set_address;

    /// Third step in the chain: Sets the surname field and calls set_address
    public fun set_surname(mut obj: MyObject, surname: vector<u8>, recipient: address) {
        let surname_string = string::utf8(surname);
        types::set_surname_internal(&mut obj, surname_string);
        
        // Recursively call set_address module
        set_address::set_address(obj, b"Boulevard, 1", recipient);
    }

    /// Entry function version
    public entry fun set_surname_entry(obj: MyObject, surname: vector<u8>, recipient: address) {
        set_surname(obj, surname, recipient);
    }
}

// Set address module, contains the function to set the address field
module sample::set_address {
    use hop::types::{Self, MyObject};
    use std::string;

    /// Final step in the chain: Sets the address field and transfers the object
    public fun set_address(mut obj: MyObject, address: vector<u8>, recipient: address) {
        let address_string = string::utf8(address);
        types::set_address_internal(&mut obj, address_string);
        
        // Final step: transfer the object
        types::handle_transfer(obj, recipient);
    }

    /// Entry function version
    public entry fun set_address_entry(obj: MyObject, address: vector<u8>, recipient: address) {
        set_address(obj, address, recipient);
    }
}
