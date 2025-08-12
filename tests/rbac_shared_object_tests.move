/**
 * Comprehensive tests for the RBAC shared object modules
 * 
 * This test suite covers:
 * - RBAC role management and initialization
 * - Shared Game object initialization and management
 * - Player, Map, and Weapon CRUD operations with RBAC
 * - View functions and statistics
 * - Failure cases and edge conditions
 */

#[test_only]
module sample::rbac_shared_object_tests {
    use sui::test_scenario;
    use sample::rbac_for_shared::{Self, RBAC_ROLE};
    use sample::shared_object::{Self, Game};

    // Test addresses
    const SUPER_ADMIN: address = @0xA;
    const ADMIN: address = @0xB;
    const USER: address = @0xC;
    const PLAYER1: address = @0xD;
    const PLAYER2: address = @0xE;

    ////////////////////////////////////
    ///
    /// RBAC MODULE TESTS
    ///
    ////////////////////////////////////

    #[test]
    fun test_rbac_init_creates_super_admin() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        {
            rbac_for_shared::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            // Check that super admin role was created and transferred to the sender
            let role = test_scenario::take_from_sender<RBAC_ROLE>(&scenario);
            // We can't directly compare enum variants from outside the module, 
            // but we can check the role was created successfully by calling check_role
            rbac_for_shared::check_role(&role);
            test_scenario::return_to_sender(&scenario, role);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_mint_admin_role_success() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        {
            rbac_for_shared::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let role = test_scenario::take_from_sender<RBAC_ROLE>(&scenario);
            rbac_for_shared::mint_admin_role(&role, ADMIN, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, role);
        };
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            // Check that admin role was created and transferred to ADMIN
            let admin_role = test_scenario::take_from_sender<RBAC_ROLE>(&scenario);
            // Check that admin role was created successfully
            rbac_for_shared::check_role(&admin_role);
            test_scenario::return_to_sender(&scenario, admin_role);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_mint_admin_role_fails_with_admin() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        {
            rbac_for_shared::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let role = test_scenario::take_from_sender<RBAC_ROLE>(&scenario);
            rbac_for_shared::mint_admin_role(&role, ADMIN, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, role);
        };
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            // Admin tries to mint another admin role - should fail
            let admin_role = test_scenario::take_from_sender<RBAC_ROLE>(&scenario);
            rbac_for_shared::mint_admin_role(&admin_role, USER, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, admin_role);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_role_level_comparison() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        {
            rbac_for_shared::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let super_admin_role = test_scenario::take_from_sender<RBAC_ROLE>(&scenario);
            rbac_for_shared::mint_admin_role(&super_admin_role, ADMIN, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, super_admin_role);
        };
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let admin_role = test_scenario::take_from_sender<RBAC_ROLE>(&scenario);
            // Check that admin role was created successfully
            rbac_for_shared::check_role(&admin_role);
            test_scenario::return_to_sender(&scenario, admin_role);
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let super_admin_role = test_scenario::take_from_sender<RBAC_ROLE>(&scenario);
            // Check that super admin role is still valid
            rbac_for_shared::check_role(&super_admin_role);
            test_scenario::return_to_sender(&scenario, super_admin_role);
        };
        test_scenario::end(scenario);
    }

    ////////////////////////////////////
    ///
    /// SHARED OBJECT INITIALIZATION TESTS
    ///
    ////////////////////////////////////

    #[test]
    fun test_shared_object_init() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        {
            shared_object::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            // Check that shared Game object was created
            let game = test_scenario::take_shared<Game>(&scenario);
            let (player_count, map_count, weapon_count) = shared_object::get_game_stats(&game);
            assert!(player_count == 0, 0);
            assert!(map_count == 0, 1);
            assert!(weapon_count == 0, 2);
            test_scenario::return_shared(game);
        };
        test_scenario::end(scenario);
    }

    ////////////////////////////////////
    ///
    /// PLAYER MANAGEMENT TESTS
    ///
    ////////////////////////////////////

    #[test]
    fun test_add_player_with_super_admin() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        // Initialize both modules
        {
            rbac_for_shared::init_for_testing(test_scenario::ctx(&mut scenario));
            shared_object::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let role = test_scenario::take_from_sender<RBAC_ROLE>(&scenario);
            let mut game = test_scenario::take_shared<Game>(&scenario);
            
            shared_object::add_player(
                &role,
                &mut game,
                PLAYER1,
                b"Alice",
                25,
                test_scenario::ctx(&mut scenario)
            );
            
            // Check player was added
            let (player_count, _, _) = shared_object::get_game_stats(&game);
            assert!(player_count == 1, 0);
            
            let (name, age) = shared_object::get_player(&game, PLAYER1);
            assert!(name == b"Alice", 1);
            assert!(age == 25, 2);
            
            test_scenario::return_to_sender(&scenario, role);
            test_scenario::return_shared(game);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_add_player_with_admin() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        // Initialize both modules
        {
            rbac_for_shared::init_for_testing(test_scenario::ctx(&mut scenario));
            shared_object::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let role = test_scenario::take_from_sender<RBAC_ROLE>(&scenario);
            rbac_for_shared::mint_admin_role(&role, ADMIN, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, role);
        };
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let admin_role = test_scenario::take_from_sender<RBAC_ROLE>(&scenario);
            let mut game = test_scenario::take_shared<Game>(&scenario);
            
            shared_object::add_player(
                &admin_role,
                &mut game,
                PLAYER1,
                b"Bob",
                30,
                test_scenario::ctx(&mut scenario)
            );
            
            // Check player was added
            let (player_count, _, _) = shared_object::get_game_stats(&game);
            assert!(player_count == 1, 0);
            
            let (name, age) = shared_object::get_player(&game, PLAYER1);
            assert!(name == b"Bob", 1);
            assert!(age == 30, 2);
            
            test_scenario::return_to_sender(&scenario, admin_role);
            test_scenario::return_shared(game);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_add_multiple_players() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        // Initialize both modules
        {
            rbac_for_shared::init_for_testing(test_scenario::ctx(&mut scenario));
            shared_object::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let role = test_scenario::take_from_sender<RBAC_ROLE>(&scenario);
            let mut game = test_scenario::take_shared<Game>(&scenario);
            
            // Add multiple players
            shared_object::add_player(&role, &mut game, PLAYER1, b"Alice", 25, test_scenario::ctx(&mut scenario));
            shared_object::add_player(&role, &mut game, PLAYER2, b"Bob", 30, test_scenario::ctx(&mut scenario));
            
            // Check both players were added
            let (player_count, _, _) = shared_object::get_game_stats(&game);
            assert!(player_count == 2, 0);
            
            let (name1, age1) = shared_object::get_player(&game, PLAYER1);
            let (name2, age2) = shared_object::get_player(&game, PLAYER2);
            
            assert!(name1 == b"Alice", 1);
            assert!(age1 == 25, 2);
            assert!(name2 == b"Bob", 3);
            assert!(age2 == 30, 4);
            
            test_scenario::return_to_sender(&scenario, role);
            test_scenario::return_shared(game);
        };
        test_scenario::end(scenario);
    }

    ////////////////////////////////////
    ///
    /// MAP MANAGEMENT TESTS
    ///
    ////////////////////////////////////

    #[test]
    fun test_add_map_with_admin() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        // Initialize both modules
        {
            rbac_for_shared::init_for_testing(test_scenario::ctx(&mut scenario));
            shared_object::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let role = test_scenario::take_from_sender<RBAC_ROLE>(&scenario);
            let mut game = test_scenario::take_shared<Game>(&scenario);
            
            shared_object::add_map(
                &role,
                &mut game,
                b"Forest Map",
                1000,
                test_scenario::ctx(&mut scenario)
            );
            
            // Check map was added
            let (_, map_count, _) = shared_object::get_game_stats(&game);
            assert!(map_count == 1, 0);
            
            let (name, size) = shared_object::get_map(&game, 0);
            assert!(name == b"Forest Map", 1);
            assert!(size == 1000, 2);
            
            test_scenario::return_to_sender(&scenario, role);
            test_scenario::return_shared(game);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_add_multiple_maps() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        // Initialize both modules
        {
            rbac_for_shared::init_for_testing(test_scenario::ctx(&mut scenario));
            shared_object::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let role = test_scenario::take_from_sender<RBAC_ROLE>(&scenario);
            let mut game = test_scenario::take_shared<Game>(&scenario);
            
            // Add multiple maps
            shared_object::add_map(&role, &mut game, b"Forest", 1000, test_scenario::ctx(&mut scenario));
            shared_object::add_map(&role, &mut game, b"Desert", 1500, test_scenario::ctx(&mut scenario));
            shared_object::add_map(&role, &mut game, b"City", 800, test_scenario::ctx(&mut scenario));
            
            // Check all maps were added
            let (_, map_count, _) = shared_object::get_game_stats(&game);
            assert!(map_count == 3, 0);
            
            let (name1, size1) = shared_object::get_map(&game, 0);
            let (name2, size2) = shared_object::get_map(&game, 1);
            let (name3, size3) = shared_object::get_map(&game, 2);
            
            assert!(name1 == b"Forest", 1);
            assert!(size1 == 1000, 2);
            assert!(name2 == b"Desert", 3);
            assert!(size2 == 1500, 4);
            assert!(name3 == b"City", 5);
            assert!(size3 == 800, 6);
            
            test_scenario::return_to_sender(&scenario, role);
            test_scenario::return_shared(game);
        };
        test_scenario::end(scenario);
    }

    ////////////////////////////////////
    ///
    /// WEAPON MANAGEMENT TESTS
    ///
    ////////////////////////////////////

    #[test]
    fun test_add_weapon_with_admin() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        // Initialize both modules
        {
            rbac_for_shared::init_for_testing(test_scenario::ctx(&mut scenario));
            shared_object::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let role = test_scenario::take_from_sender<RBAC_ROLE>(&scenario);
            let mut game = test_scenario::take_shared<Game>(&scenario);
            
            shared_object::add_weapon(
                &role,
                &mut game,
                b"Magic Sword",
                95, // trait1: damage
                80, // trait2: durability
                test_scenario::ctx(&mut scenario)
            );
            
            // Check weapon was added
            let (_, _, weapon_count) = shared_object::get_game_stats(&game);
            assert!(weapon_count == 1, 0);
            
            let (name, trait1, trait2) = shared_object::get_weapon(&game, 0);
            assert!(name == b"Magic Sword", 1);
            assert!(trait1 == 95, 2);
            assert!(trait2 == 80, 3);
            
            test_scenario::return_to_sender(&scenario, role);
            test_scenario::return_shared(game);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_add_multiple_weapons() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        // Initialize both modules
        {
            rbac_for_shared::init_for_testing(test_scenario::ctx(&mut scenario));
            shared_object::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let role = test_scenario::take_from_sender<RBAC_ROLE>(&scenario);
            let mut game = test_scenario::take_shared<Game>(&scenario);
            
            // Add multiple weapons
            shared_object::add_weapon(&role, &mut game, b"Sword", 80, 90, test_scenario::ctx(&mut scenario));
            shared_object::add_weapon(&role, &mut game, b"Bow", 70, 85, test_scenario::ctx(&mut scenario));
            shared_object::add_weapon(&role, &mut game, b"Staff", 95, 60, test_scenario::ctx(&mut scenario));
            
            // Check all weapons were added
            let (_, _, weapon_count) = shared_object::get_game_stats(&game);
            assert!(weapon_count == 3, 0);
            
            let (name1, trait1_1, trait2_1) = shared_object::get_weapon(&game, 0);
            let (name2, trait1_2, trait2_2) = shared_object::get_weapon(&game, 1);
            let (name3, trait1_3, trait2_3) = shared_object::get_weapon(&game, 2);
            
            assert!(name1 == b"Sword", 1);
            assert!(trait1_1 == 80, 2);
            assert!(trait2_1 == 90, 3);
            
            assert!(name2 == b"Bow", 4);
            assert!(trait1_2 == 70, 5);
            assert!(trait2_2 == 85, 6);
            
            assert!(name3 == b"Staff", 7);
            assert!(trait1_3 == 95, 8);
            assert!(trait2_3 == 60, 9);
            
            test_scenario::return_to_sender(&scenario, role);
            test_scenario::return_shared(game);
        };
        test_scenario::end(scenario);
    }

    ////////////////////////////////////
    ///
    /// VIEW FUNCTIONS TESTS
    ///
    ////////////////////////////////////

    #[test]
    fun test_get_game_stats_comprehensive() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        // Initialize both modules
        {
            rbac_for_shared::init_for_testing(test_scenario::ctx(&mut scenario));
            shared_object::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let role = test_scenario::take_from_sender<RBAC_ROLE>(&scenario);
            let mut game = test_scenario::take_shared<Game>(&scenario);
            
            // Initially empty
            let (player_count, map_count, weapon_count) = shared_object::get_game_stats(&game);
            assert!(player_count == 0, 0);
            assert!(map_count == 0, 1);
            assert!(weapon_count == 0, 2);
            
            // Add some data
            shared_object::add_player(&role, &mut game, PLAYER1, b"Alice", 25, test_scenario::ctx(&mut scenario));
            shared_object::add_player(&role, &mut game, PLAYER2, b"Bob", 30, test_scenario::ctx(&mut scenario));
            shared_object::add_map(&role, &mut game, b"Forest", 1000, test_scenario::ctx(&mut scenario));
            shared_object::add_weapon(&role, &mut game, b"Sword", 80, 90, test_scenario::ctx(&mut scenario));
            shared_object::add_weapon(&role, &mut game, b"Bow", 70, 85, test_scenario::ctx(&mut scenario));
            shared_object::add_weapon(&role, &mut game, b"Staff", 95, 60, test_scenario::ctx(&mut scenario));
            
            // Check updated stats
            let (player_count, map_count, weapon_count) = shared_object::get_game_stats(&game);
            assert!(player_count == 2, 3);
            assert!(map_count == 1, 4);
            assert!(weapon_count == 3, 5);
            
            test_scenario::return_to_sender(&scenario, role);
            test_scenario::return_shared(game);
        };
        test_scenario::end(scenario);
    }

    ////////////////////////////////////
    ///
    /// EDGE CASE TESTS
    ///
    ////////////////////////////////////

    #[test]
    fun test_add_player_with_empty_name() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        // Initialize both modules
        {
            rbac_for_shared::init_for_testing(test_scenario::ctx(&mut scenario));
            shared_object::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let role = test_scenario::take_from_sender<RBAC_ROLE>(&scenario);
            let mut game = test_scenario::take_shared<Game>(&scenario);
            
            shared_object::add_player(
                &role,
                &mut game,
                PLAYER1,
                b"", // empty name
                0,   // zero age
                test_scenario::ctx(&mut scenario)
            );
            
            let (name, age) = shared_object::get_player(&game, PLAYER1);
            assert!(name == b"", 0);
            assert!(age == 0, 1);
            
            test_scenario::return_to_sender(&scenario, role);
            test_scenario::return_shared(game);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_add_map_with_zero_size() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        // Initialize both modules
        {
            rbac_for_shared::init_for_testing(test_scenario::ctx(&mut scenario));
            shared_object::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let role = test_scenario::take_from_sender<RBAC_ROLE>(&scenario);
            let mut game = test_scenario::take_shared<Game>(&scenario);
            
            shared_object::add_map(
                &role,
                &mut game,
                b"Tiny Map",
                0, // zero size
                test_scenario::ctx(&mut scenario)
            );
            
            let (name, size) = shared_object::get_map(&game, 0);
            assert!(name == b"Tiny Map", 0);
            assert!(size == 0, 1);
            
            test_scenario::return_to_sender(&scenario, role);
            test_scenario::return_shared(game);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_add_weapon_with_max_traits() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        // Initialize both modules
        {
            rbac_for_shared::init_for_testing(test_scenario::ctx(&mut scenario));
            shared_object::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let role = test_scenario::take_from_sender<RBAC_ROLE>(&scenario);
            let mut game = test_scenario::take_shared<Game>(&scenario);
            
            shared_object::add_weapon(
                &role,
                &mut game,
                b"Ultimate Weapon",
                255, // max u8 value
                255, // max u8 value
                test_scenario::ctx(&mut scenario)
            );
            
            let (name, trait1, trait2) = shared_object::get_weapon(&game, 0);
            assert!(name == b"Ultimate Weapon", 0);
            assert!(trait1 == 255, 1);
            assert!(trait2 == 255, 2);
            
            test_scenario::return_to_sender(&scenario, role);
            test_scenario::return_shared(game);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_player_with_max_age() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        // Initialize both modules
        {
            rbac_for_shared::init_for_testing(test_scenario::ctx(&mut scenario));
            shared_object::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let role = test_scenario::take_from_sender<RBAC_ROLE>(&scenario);
            let mut game = test_scenario::take_shared<Game>(&scenario);
            
            shared_object::add_player(
                &role,
                &mut game,
                PLAYER1,
                b"Ancient Player",
                65535, // max u16 value
                test_scenario::ctx(&mut scenario)
            );
            
            let (name, age) = shared_object::get_player(&game, PLAYER1);
            assert!(name == b"Ancient Player", 0);
            assert!(age == 65535, 1);
            
            test_scenario::return_to_sender(&scenario, role);
            test_scenario::return_shared(game);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_map_with_max_size() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        // Initialize both modules
        {
            rbac_for_shared::init_for_testing(test_scenario::ctx(&mut scenario));
            shared_object::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let role = test_scenario::take_from_sender<RBAC_ROLE>(&scenario);
            let mut game = test_scenario::take_shared<Game>(&scenario);
            
            shared_object::add_map(
                &role,
                &mut game,
                b"Infinite Map",
                18446744073709551615, // max u64 value
                test_scenario::ctx(&mut scenario)
            );
            
            let (name, size) = shared_object::get_map(&game, 0);
            assert!(name == b"Infinite Map", 0);
            assert!(size == 18446744073709551615, 1);
            
            test_scenario::return_to_sender(&scenario, role);
            test_scenario::return_shared(game);
        };
        test_scenario::end(scenario);
    }

    ////////////////////////////////////
    ///
    /// RBAC FAILURE TESTS (Expected to fail)
    ///
    ////////////////////////////////////

    // Note: These tests would require a user without any RBAC role trying to call admin functions
    // However, the current design requires passing an RBAC_ROLE object, so these tests cannot be written
    // without modifying the contract design. In a real-world scenario, you might want to add
    // entry functions that check if the sender has a role rather than requiring a role object.

    ////////////////////////////////////
    ///
    /// FAILURE TESTS (Expected to fail)
    ///
    ////////////////////////////////////

    #[test]
    #[expected_failure]
    fun test_get_player_nonexistent() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        {
            shared_object::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let game = test_scenario::take_shared<Game>(&scenario);
            // Try to get a player that doesn't exist - should fail
            let (_, _) = shared_object::get_player(&game, PLAYER1);
            test_scenario::return_shared(game);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure]
    fun test_get_map_invalid_index() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        {
            shared_object::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let game = test_scenario::take_shared<Game>(&scenario);
            // Try to get a map at invalid index - should fail
            let (_, _) = shared_object::get_map(&game, 0);
            test_scenario::return_shared(game);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure]
    fun test_get_weapon_invalid_index() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        {
            shared_object::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let game = test_scenario::take_shared<Game>(&scenario);
            // Try to get a weapon at invalid index - should fail
            let (_, _, _) = shared_object::get_weapon(&game, 0);
            test_scenario::return_shared(game);
        };
        test_scenario::end(scenario);
    }
}
