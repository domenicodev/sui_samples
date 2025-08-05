/**
Super simple module to demonstrate the basics of Sui Move. (Vector handling, ...)

Shows the main concepts of Sui Move for Vectors and basic objects,
and useful to catch the main differences between Sui Move and other Move implementations.

Some relevant differences between Sui Move and Aptos Move that can be seen in this module:
- Objects have an identifier (UID)
- "move_to" is replaced by "transfer"
- transaction context is passed as a parameter to the functions (solana-like), and not borrowed from the global state
- only one signer is accessible from a transaction, via the transaction context(tx_context::sender(ctx)), cross-callers access is not possible
- to transfer, borrow, edit objects, the objects reference must be passed as a parameter to the functions
*/

module sample_vector::sample_vector {
    use std::string::{Self, String};

    /// User struct represents individual user data
    /// Abilities explained:
    /// - `store`: allows this struct to be stored inside other structs and in global storage(in this case, in the Users struct)
    /// - `copy`: allows the struct to be copied (duplicated) when needed
    /// - `drop`: allows the struct to be automatically destroyed when it goes out of scope
    /// These abilities make User a simple data container that can be easily manipulated
    public struct User has store, copy, drop {
        name: String,
        age: u64,
        email: String
    }

    /// Users struct acts as a container/registry for multiple User objects
    /// Abilities explained:
    /// - `key`: makes this struct a Sui object that can be owned, transferred, and stored on-chain
    ///   Only structs with `key` ability can be transferred between addresses
    /// - The `id` field is required for all objects with `key` ability
    /// 
    /// What this module can do with Users struct:
    /// - Create new Users objects and transfer them to addresses
    /// - Add, remove, and query User records within the Users container
    /// - Since it has `key`, it persists on the blockchain and can be owned by accounts
    public struct Users has key {
        id: sui::object::UID,
        users: vector<User>
    }

    /// The init function runs exactly once when this module is first published
    /// It's used to set up initial state and objects for the module
    fun init(ctx: &mut sui::tx_context::TxContext) {
        // Create an empty vector to hold User structs
        let mut new_users = vector::empty();

        // Add an initial user to demonstrate the functionality
        // string::utf8(b"...") converts byte literals to UTF-8 strings
        vector::push_back(&mut new_users, User {
            name: string::utf8(b"John"),
            age: 20,
            email: string::utf8(b"john@example.com")
        });

        // Create a new Users object and transfer it to the module publisher
        // sui::object::new(ctx) creates a unique ID for this object
        // sui::tx_context::sender(ctx) gets the address that published this module
        sui::transfer::transfer(Users { id: sui::object::new(ctx), users: new_users }, sui::tx_context::sender(ctx));
    }

    public fun add_user(usersRef: &mut Users, name: String, age: u64, email: String) {
        vector::push_back(&mut usersRef.users, User { name, age, email });
    }

    /// Retrieves user information at the specified index
    /// Note: We use the unpack syntax to get the fields of the User struct, which is a tuple of (String, u64, String)
    /// This is because the User struct fields could never be accessed even if returning the User struct with "copy" ability,
    /// so if we tried accessing get_user(usersRef, index).'field', it would throw an error.
    /// The copy ability is only used to allow the struct to be copied when needed, not to allow the fields to be accessed.
    public fun get_user(usersRef: &Users, index: u64): (String, u64, String) {
        let user = vector::borrow(&usersRef.users, index);
        (user.name, user.age, user.email)
    }

    public fun remove_user(usersRef: &mut Users, index: u64) {
        vector::remove(&mut usersRef.users, index);
    }

    public fun say_hi(name: String): String {
        name
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut sui::tx_context::TxContext) {
        init(ctx);
    }

}
