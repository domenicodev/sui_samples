#[test_only]
module sample::display_tests;

use sample::display;
use std::string;
use sui::test_scenario;
use sui::test_utils;

const ADMIN: address = @0xAD;

#[test]
fun test_mint_hero() {
    let mut scenario = test_scenario::begin(ADMIN);
    let otw = test_utils::create_one_time_witness<display::DISPLAY>();
    display::init_for_testing(otw, scenario.ctx());
    test_scenario::next_tx(&mut scenario, ADMIN);
    {
        let ctx = test_scenario::ctx(&mut scenario);

        // Mint a hero
        let hero = display::mint(
            string::utf8(b"Alice"),
            25,
            string::utf8(b"alice@example.com"),
            ctx,
        );

        // Transfer to clean up
        transfer::public_transfer(hero, ADMIN);
    };

    test_scenario::end(scenario);
}

#[test]
fun test_mint_multiple_heroes() {
    let mut scenario = test_scenario::begin(ADMIN);
    let otw = test_utils::create_one_time_witness<display::DISPLAY>();
    display::init_for_testing(otw, scenario.ctx());

    test_scenario::next_tx(&mut scenario, ADMIN);
    {
        let ctx = test_scenario::ctx(&mut scenario);

        // Mint multiple heroes
        let hero1 = display::mint(
            string::utf8(b"Bob"),
            30,
            string::utf8(b"bob@test.com"),
            ctx,
        );

        let hero2 = display::mint(
            string::utf8(b"Charlie"),
            35,
            string::utf8(b"charlie@example.org"),
            ctx,
        );

        // Transfer to clean up
        transfer::public_transfer(hero1, ADMIN);
        transfer::public_transfer(hero2, ADMIN);
    };

    test_scenario::end(scenario);
}

#[test]
fun test_display_operations() {
    let mut scenario = test_scenario::begin(ADMIN);
    
    // Initialize display in first transaction
    {
        let otw = test_utils::create_one_time_witness<display::DISPLAY>();
        display::init_for_testing(otw, scenario.ctx());
    };

    test_scenario::next_tx(&mut scenario, ADMIN);
    {
        // Take the display object that was transferred to ADMIN
        let mut display_obj = test_scenario::take_from_sender<sui::display::Display<display::Hero>>(&scenario);

        // Test remove operation
        display::remove(&mut display_obj, string::utf8(b"age"));

        // Test edit operation (note: current implementation only removes)
        display::edit(&mut display_obj, string::utf8(b"name"), string::utf8(b"New Name"));

        // Return display object
        test_scenario::return_to_sender(&scenario, display_obj);
    };

    test_scenario::end(scenario);
}
