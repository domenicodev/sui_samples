/**
Shared object example(a Game) in Sui Move featuring RBAC to restrict access to edit it.
*/

/// RBAC
module sample::rbac_for_shared {
    /// Enum of Role Levels
    /// We explicitly use the abilities:
    /// - store: To store ROLE_LEVEL inside RBAC_ROLE
    /// - drop: To destroy this object(virtual) when used in functions that do not consume(transfer or destroy) the holding object(RBAC_ROLE)
    /// - copy: To use the object in memory for comparison(==, <=, ...)
    public enum ROLE_LEVEL has copy, drop, store {
        ADMIN,
        SUPER_ADMIN,
    }

    public struct RBAC_ROLE has key {
        id: sui::object::UID,
        level: ROLE_LEVEL,
    }

    fun init(ctx: &mut sui::tx_context::TxContext) {
        mint_role_internal(sui::tx_context::sender(ctx), ROLE_LEVEL::SUPER_ADMIN, ctx)
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut sui::tx_context::TxContext) {
        init(ctx)
    }

    /// Check(witness) if sender or intermediaries/callers calling this function have at least a role
    public fun check_role(_: &RBAC_ROLE) {}

    /// Get role level of given role
    public fun get_role_level(cur_role: &RBAC_ROLE): ROLE_LEVEL {
        cur_role.level
    }

    /// Mint a new role (internal)
    public fun mint_role_internal(to: address, role_level: ROLE_LEVEL, ctx: &mut TxContext) {
        let role = RBAC_ROLE {
            id: object::new(ctx),
            level: role_level,
        };
        sui::transfer::transfer(role, to)
    }

    /// Mint a new role (internal)
    public fun mint_admin_role(cur_role: &RBAC_ROLE, to: address, ctx: &mut TxContext) {
        assert!(cur_role.level == ROLE_LEVEL::SUPER_ADMIN, 1);
        mint_role_internal(to, ROLE_LEVEL::ADMIN, ctx)
    }
}

/// Shared Object (e.g. a Game)
module sample::shared_object {
    use sample::rbac_for_shared;
    use sui::table::{Self, Table};

    public struct Player has copy, store {
        name: vector<u8>,
        age: u16,
    }

    public struct Map has copy, store {
        name: vector<u8>,
        size: u64,
    }

    public struct Weapon has copy, store {
        name: vector<u8>,
        trait1: u8,
        trait2: u8,
    }

    // Shared Object
    public struct Game has key {
        id: sui::object::UID,
        players: Table<address, Player>,
        maps: vector<Map>,
        weapons: vector<Weapon>,
    }

    fun init(ctx: &mut TxContext) {
        let game = Game {
            id: object::new(ctx),
            players: table::new(ctx),
            maps: vector::empty(),
            weapons: vector::empty(),
        };

        sui::transfer::share_object(game);
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx)
    }

    /// === MUTATIONS / EDIT FUNCTIONS ===

    /// Add a new player to the game (RBAC admin only)
    public fun add_player(
        _: &rbac_for_shared::RBAC_ROLE,
        game: &mut Game,
        player_address: address,
        name: vector<u8>,
        age: u16,
    ) {
        let player = Player {
            name,
            age,
        };

        table::add(&mut game.players, player_address, player);
    }

    /// Add a new map to the game (RBAC admin only)
    public fun add_map(
        _: &rbac_for_shared::RBAC_ROLE,
        game: &mut Game,
        name: vector<u8>,
        size: u64,
    ) {
        let map = Map {
            name,
            size,
        };

        vector::push_back(&mut game.maps, map);
    }

    /// Add a new weapon to the game (RBAC admin only)
    public fun add_weapon(
        _: &rbac_for_shared::RBAC_ROLE,
        game: &mut Game,
        name: vector<u8>,
        trait1: u8,
        trait2: u8,
    ) {
        let weapon = Weapon {
            name,
            trait1,
            trait2,
        };

        vector::push_back(&mut game.weapons, weapon);
    }

    /// === VIEW FUNCTIONS ===

    /// Get game statistics (player count, map count, weapon count)
    public fun get_game_stats(game: &Game): (u64, u64, u64) {
        (table::length(&game.players), vector::length(&game.maps), vector::length(&game.weapons))
    }

    /// Get player details by address
    public fun get_player(game: &Game, player_address: address): (vector<u8>, u16) {
        let player = table::borrow(&game.players, player_address);
        (player.name, player.age)
    }

    /// Get map details by index
    public fun get_map(game: &Game, map_id: u64): (vector<u8>, u64) {
        let map = vector::borrow(&game.maps, map_id);
        (map.name, map.size)
    }

    /// Get weapon details by index
    public fun get_weapon(game: &Game, weapon_id: u64): (vector<u8>, u8, u8) {
        let weapon = vector::borrow(&game.weapons, weapon_id);
        (weapon.name, weapon.trait1, weapon.trait2)
    }
}
