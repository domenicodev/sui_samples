/**
Super Access Control Module implementation in SUI Move.

Showcases how to implement a pseudo Access Control using objects (and not tables).

Ideally, for a production-ready Access Control Module, you should use a shared object tracking the roles of the users.

*/

module sample::sample_access_control {

    public struct SAC_ROLE has key {
        id: UID,
        level: u64 // 1: admin, 2: super admin
    }

    fun init(ctx: &mut TxContext) {
        let admin_cap = SAC_ROLE {
            id: object::new(ctx),
            level: 2
        };
        transfer::transfer(admin_cap, tx_context::sender(ctx));
    }

    fun give_role(ctx: &mut TxContext, to: address, level: u64) {
        let role = SAC_ROLE {
            id: object::new(ctx),
            level: level
        };
        transfer::transfer(role, to);
    }

    // Revoke the SAC role by deleting the object
    fun revoke_sac(role: SAC_ROLE) {
        let SAC_ROLE { id, level: _ } = role;
        id.delete()
    }

    // Check if the role has the required level, using reference as paramenter since we need a mutable(read) reference only
    fun has_role(role: &SAC_ROLE, level: u64): bool {
        role.level >= level
    }

    // Give the admin role to "to" address if the current user role is super admin, using reference as paramenter since we need a mutable(read) reference only
    public fun give_admin_role(to: address, current_role: &SAC_ROLE, ctx: &mut TxContext) {
        // check if the current role is super admin
        assert!(has_role(current_role, 2), 1);
        give_role(ctx, to, 1);
    }

    // Change the super admin to the new super admin if the current user role is super admin.
    // We pass current_role as object since we need to delete it.
    // We use reference &current_role in has_role since we need to read it (mutable reference).
    public fun change_super_admin(new_super_admin: address, current_role: &mut SAC_ROLE, ctx: &mut TxContext) {
        // check if the current role is super admin
        assert!(has_role(current_role, 2), 1);

        // revoke_sac(current_role);
        give_role(ctx, new_super_admin, 2);
    }

    // Transfer the current user role to a new user and upgrade its role
    // We pass current_role as mut because we have to transfer and edit it.
    // We use reference &current_role in has_role since we need to read it (mutable reference).
    public fun transfer_and_upgrade_role(new_user: address, mut current_role: SAC_ROLE) {
        // check if the current role is super admin
        assert!(has_role(&current_role, 2), 1);

        // upgrade the role
        current_role.level = current_role.level + 1;

        // transfer the role to the new user
        transfer::transfer(current_role, new_user);
    }

    // Allow user to renounce its own role (admin only, super admin can't be renounced its own role, should transfer it instead)
    public fun renounce_role(current_role: SAC_ROLE) {
        // check if the current role is admin
        assert!(&current_role.level == 1, 1);
        revoke_sac(current_role);
    }

    // Public getter function to access the role level
    public fun get_role_level(role: &SAC_ROLE): u64 {
        role.level
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}
