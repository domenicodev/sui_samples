module sample::display;

use std::string::{Self, String};
use sui::display::{Self, Display};
use sui::package;

public struct DISPLAY has drop {}

public struct Hero has key, store {
    id: UID,
    name: String,
    age: u64,
    email: String,
}

fun init(otw: DISPLAY,ctx: &mut TxContext) {
    let keys = vector[b"name".to_string(), b"age".to_string(), b"email".to_string()];

    let values = vector[b"{name}".to_string(), b"{age}".to_string(), b"{email}".to_string()];
    let publisher = package::claim(otw, ctx);
    let mut display = display::new_with_fields<Hero>(&publisher, keys, values, ctx);

    // broadcast display
    display.update_version();

    transfer::public_transfer(publisher, ctx.sender()); // publisher cap
    transfer::public_transfer(display, ctx.sender()); // display cap (to edit display)
}

public fun mint(name: String, age: u64, email: String, ctx: &mut TxContext): Hero {
    Hero {
        id: object::new(ctx),
        name,
        age,
        email,
    }
}

public fun remove(self: &mut Display<Hero>, key: String) {
    display::remove(self, key);
}

public fun edit(self: &mut Display<Hero>, key: String, value: String) {
    display::remove(self, key);
}

#[test_only]
public fun init_for_testing(otw: DISPLAY, ctx: &mut TxContext) {
    init(otw, ctx);
}
