#[test_only]
module sample::sample_access_control_tests {
    use sui::test_scenario;
    use sample::sample_access_control::{Self, SAC_ROLE};

    const SUPER_ADMIN: address = @0xA;
    const ADMIN: address = @0xB;
    const USER: address = @0xC;
    const NEW_SUPER_ADMIN: address = @0xD;

    #[test]
    fun test_init_creates_super_admin() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        {
            sample_access_control::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            // Check that super admin role was created and transferred to the sender
            let role = test_scenario::take_from_sender<SAC_ROLE>(&scenario);
            assert!(sample_access_control::get_role_level(&role) == 2, 0); // Should be super admin level
            test_scenario::return_to_sender(&scenario, role);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_give_admin_role_success() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        {
            sample_access_control::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let role = test_scenario::take_from_sender<SAC_ROLE>(&scenario);
            sample_access_control::give_admin_role(ADMIN, &role, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, role);
        };
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            // Check that admin role was created and transferred to ADMIN
            let admin_role = test_scenario::take_from_sender<SAC_ROLE>(&scenario);
            assert!(sample_access_control::get_role_level(&admin_role) == 1, 0); // Should be admin level
            test_scenario::return_to_sender(&scenario, admin_role);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_give_admin_role_fails_with_non_super_admin() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        {
            sample_access_control::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let role = test_scenario::take_from_sender<SAC_ROLE>(&scenario);
            sample_access_control::give_admin_role(ADMIN, &role, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, role);
        };
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            // Admin tries to give role to USER - should fail
            let admin_role = test_scenario::take_from_sender<SAC_ROLE>(&scenario);
            sample_access_control::give_admin_role(USER, &admin_role, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, admin_role);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_change_super_admin_success() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        {
            sample_access_control::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let mut role = test_scenario::take_from_sender<SAC_ROLE>(&scenario);
            sample_access_control::change_super_admin(NEW_SUPER_ADMIN, &mut role, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, role);
        };
        test_scenario::next_tx(&mut scenario, NEW_SUPER_ADMIN);
        {
            // Check that new super admin role was created and transferred
            let new_role = test_scenario::take_from_sender<SAC_ROLE>(&scenario);
            assert!(sample_access_control::get_role_level(&new_role) == 2, 0); // Should be super admin level
            test_scenario::return_to_sender(&scenario, new_role);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_change_super_admin_fails_with_admin() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        {
            sample_access_control::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let role = test_scenario::take_from_sender<SAC_ROLE>(&scenario);
            sample_access_control::give_admin_role(ADMIN, &role, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, role);
        };
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            // Admin tries to change super admin - should fail
            let mut admin_role = test_scenario::take_from_sender<SAC_ROLE>(&scenario);
            sample_access_control::change_super_admin(USER, &mut admin_role, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, admin_role);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_renounce_admin_role_success() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        {
            sample_access_control::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let role = test_scenario::take_from_sender<SAC_ROLE>(&scenario);
            sample_access_control::give_admin_role(ADMIN, &role, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, role);
        };
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            // Admin renounces their role - should succeed
            let admin_role = test_scenario::take_from_sender<SAC_ROLE>(&scenario);
            sample_access_control::renounce_role(admin_role, test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            // Check that admin no longer has a role
            assert!(!test_scenario::has_most_recent_for_sender<SAC_ROLE>(&scenario), 0);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_transfer_and_upgrade_role() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        {
            sample_access_control::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let role = test_scenario::take_from_sender<SAC_ROLE>(&scenario);
            sample_access_control::transfer_and_upgrade_role(USER, role, test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, USER);
        {
            let user_role = test_scenario::take_from_sender<SAC_ROLE>(&scenario);
            assert!(sample_access_control::get_role_level(&user_role) == 3, 0); // Should be super admin level + 1
            test_scenario::return_to_sender(&scenario, user_role);
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            assert!(!test_scenario::has_most_recent_for_sender<SAC_ROLE>(&scenario), 0);
        };
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_renounce_super_admin_role_fails() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        {
            sample_access_control::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            // Super admin tries to renounce their role - should fail
            let role = test_scenario::take_from_sender<SAC_ROLE>(&scenario);
            sample_access_control::renounce_role(role, test_scenario::ctx(&mut scenario));
        };
        test_scenario::end(scenario);
    }

    // Helper test to verify role levels work correctly
    #[test]
    fun test_role_levels() {
        let mut scenario = test_scenario::begin(SUPER_ADMIN);
        {
            sample_access_control::init_for_testing(test_scenario::ctx(&mut scenario));
        };
        test_scenario::next_tx(&mut scenario, SUPER_ADMIN);
        {
            let super_admin_role = test_scenario::take_from_sender<SAC_ROLE>(&scenario);
            
            // Super admin should be able to give admin role
            sample_access_control::give_admin_role(ADMIN, &super_admin_role, test_scenario::ctx(&mut scenario));
            
            test_scenario::return_to_sender(&scenario, super_admin_role);
        };
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let admin_role = test_scenario::take_from_sender<SAC_ROLE>(&scenario);
            assert!(sample_access_control::get_role_level(&admin_role) == 1, 0); // Admin level
            test_scenario::return_to_sender(&scenario, admin_role);
        };
        test_scenario::end(scenario);
    }
}
