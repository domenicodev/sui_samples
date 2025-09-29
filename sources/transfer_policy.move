/**
 * Simple Transfer Policy Implementation for Sui
 * 
 * This module demonstrates 3 basic transfer policy rules:
 * 1. Witness Rule - requires a specific witness type to authorize transfer
 * 2. Fee Rule - requires payment of SUI to transfer
 * 3. Time Rule - only allows transfers after a certain time (using Clock)
 * 
 * Key Concepts:
 * - T: Generic type for the object being transferred (like our ExampleNFT)
 * - W: Generic type for witness authorization (like AdminWitness)
 * - TransferPolicy: Rules that control how objects can be transferred
 * - TransferRequest: A "hot potato" that must be resolved to complete transfer
 */

module sample::transfer_policy_simple {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};
    use sui::package::{Self};
    use sui::vec_set::{Self};
    use std::type_name::{Self};
    use std::option::{Option};
    use sui::transfer_policy::{
        Self as policy,
        TransferPolicy,
        TransferPolicyCap,
        TransferRequest
    };

    // Error codes
    const EInsufficientAmount: u64 = 0;
    const ETooSoon: u64 = 1;
    const ERuleNotSet: u64 = 2;

    // ==================== EXAMPLE NFT TYPE ====================
    
    /// One-time witness for ExampleNFT (needed for package publishing)
    public struct TRANSFER_POLICY_SIMPLE has drop {}
    
    /// Simple NFT that we'll create transfer policies for
    /// T in our policies will refer to this type
    public struct ExampleNFT has key, store {
        id: UID,
        name: std::string::String,
    }

    /// Initialize the module - creates transfer policy and shares it
    fun init(otw: TRANSFER_POLICY_SIMPLE, ctx: &mut TxContext) {
        // Create publisher capability
        let publisher = package::claim(otw, ctx);
        
        // Create transfer policy for ExampleNFT
        let (policy, cap) = policy::new<ExampleNFT>(&publisher, ctx);
        
        // Share the policy so everyone can use it
        transfer::public_share_object(policy);
        
        // Transfer the cap to the deployer so they can modify rules
        transfer::public_transfer(cap, tx_context::sender(ctx));
        
        // Burn the publisher since we don't need it anymore
        package::burn_publisher(publisher);
    }

    // ==================== RULE 1: WITNESS RULE ====================
    
    /// Witness Rule - requires a specific witness type W to authorize transfer
    /// 
    /// W is a generic type parameter that represents the witness type needed.
    /// For example, if W = AdminWitness, then only someone with an AdminWitness
    /// can authorize the transfer.
    public struct WitnessRule<phantom W> has drop {}

    /// Empty config for witness rule
    public struct WitnessConfig has store, drop {}

    /// Add witness rule to policy
    /// T = type being transferred, W = witness type required
    public fun add_witness_rule<T, W>(
        policy: &mut TransferPolicy<T>,
        cap: &TransferPolicyCap<T>
    ) {
        policy::add_rule(WitnessRule<W> {}, policy, cap, WitnessConfig {});
    }

    /// Satisfy witness rule by providing the witness
    /// The witness W is consumed (dropped) to prove authorization
    public fun confirm_witness<T, W: drop>(
        _witness: W, // This witness is consumed to prove we have it
        policy: &TransferPolicy<T>,
        request: &mut TransferRequest<T>
    ) {
        assert!(policy::has_rule<T, WitnessRule<W>>(policy), ERuleNotSet);
        policy::add_receipt(WitnessRule<W> {}, request);
    }

    // ==================== RULE 2: FEE RULE ====================
    
    /// Fee Rule - requires payment of SUI to transfer
    public struct FeeRule has drop {}

    /// Config stores the required fee amount
    public struct FeeConfig has store, drop {
        fee_amount: u64, // Amount in MIST (smallest SUI unit)
    }

    /// Add fee rule to policy
    public fun add_fee_rule<T>(
        policy: &mut TransferPolicy<T>,
        cap: &TransferPolicyCap<T>,
        fee_amount: u64
    ) {
        policy::add_rule(FeeRule {}, policy, cap, FeeConfig { fee_amount });
    }

    /// Pay the fee to satisfy the rule
    public fun pay_fee<T>(
        policy: &mut TransferPolicy<T>,
        request: &mut TransferRequest<T>,
        payment: Coin<SUI>
    ) {
        let config: &FeeConfig = policy::get_rule(FeeRule {}, policy);
        assert!(coin::value(&payment) >= config.fee_amount, EInsufficientAmount);
        
        // Add payment to policy balance and mark rule satisfied
        policy::add_to_balance(FeeRule {}, policy, payment);
        policy::add_receipt(FeeRule {}, request);
    }

    /// Withdraw accumulated fees from the policy
    /// Only the policy owner (holder of TransferPolicyCap) can withdraw
    /// If amount is None, withdraws all available balance
    public fun withdraw_fees<T>(
        policy: &mut TransferPolicy<T>,
        cap: &TransferPolicyCap<T>,
        amount: Option<u64>,
        ctx: &mut TxContext
    ): Coin<SUI> {
        policy::withdraw(policy, cap, amount, ctx)
    }

    // ==================== RULE 3: TIME RULE ====================
    
    /// Time Rule - only allows transfers after a certain time
    public struct TimeRule has drop {}

    /// Config stores when transfers are allowed
    public struct TimeConfig has store, drop {
        start_time: u64, // Unix timestamp in milliseconds
    }

    /// Add time rule to policy
    public fun add_time_rule<T>(
        policy: &mut TransferPolicy<T>,
        cap: &TransferPolicyCap<T>,
        start_time: u64
    ) {
        policy::add_rule(TimeRule {}, policy, cap, TimeConfig { start_time });
    }

    /// Check that enough time has passed using Clock
    public fun confirm_time<T>(
        policy: &TransferPolicy<T>,
        request: &mut TransferRequest<T>,
        clock: &Clock
    ) {
        let config: &TimeConfig = policy::get_rule(TimeRule {}, policy);
        let current_time = clock::timestamp_ms(clock);
        
        assert!(current_time >= config.start_time, ETooSoon);
        policy::add_receipt(TimeRule {}, request);
    }

    // ==================== EXAMPLE WITNESS TYPES ====================
    
    /// Example witness for admin authorization
    public struct AdminWitness has drop {}

    /// Example witness for user authorization  
    public struct UserWitness has drop {}

    // ==================== TRANSFER ENFORCEMENT FUNCTIONS ====================
    
    /// Complete a transfer by checking all policy rules are satisfied
    /// This is the main function that enforces the transfer policy
    public fun complete_transfer<T>(
        policy: &TransferPolicy<T>,
        request: TransferRequest<T>
    ) {
        // This will check that all rules have been satisfied (all receipts collected)
        // and consume the TransferRequest hot potato
        policy::confirm_request(policy, request);
    }

    // ==================== MOCK FUNCTIONS (FOR TESTING) ====================
    
    /// MOCK: Fake witness confirmation that doesn't add receipt
    /// This will cause confirm_request() to fail because no receipt is added
    public fun fake_confirm_witness<T, W: drop>(
        _witness: W, // Consume the witness but don't add receipt
        _policy: &TransferPolicy<T>,
        _request: &mut TransferRequest<T>
    ) {
        // This function intentionally does NOT call policy::add_receipt()
        // The witness is consumed but no receipt is added to the request
        // This should cause confirm_request() to fail later
    }
    
    /// MOCK: Fake fee payment that doesn't add receipt
    /// Takes the payment but doesn't add receipt - should cause failure
    public fun fake_pay_fee<T>(
        policy: &mut TransferPolicy<T>,
        _request: &mut TransferRequest<T>,
        payment: Coin<SUI>
    ) {
        let config: &FeeConfig = policy::get_rule(FeeRule {}, policy);
        assert!(coin::value(&payment) >= config.fee_amount, EInsufficientAmount);
        
        // Take the payment but DON'T add receipt
        policy::add_to_balance(FeeRule {}, policy, payment);
        // Missing: policy::add_receipt(FeeRule {}, request);
    }
    
    /// MOCK: Fake time confirmation that doesn't add receipt
    public fun fake_confirm_time<T>(
        policy: &TransferPolicy<T>,
        _request: &mut TransferRequest<T>,
        clock: &Clock
    ) {
        let config: &TimeConfig = policy::get_rule(TimeRule {}, policy);
        let current_time = clock::timestamp_ms(clock);
        
        // Check time requirement but DON'T add receipt
        assert!(current_time >= config.start_time, ETooSoon);
        // Missing: policy::add_receipt(TimeRule {}, request);
    }

    // Note: We don't need receipt checking functions because:
    // 1. The receipts field is private to sui::transfer_policy module
    // 2. confirm_request() automatically checks all required receipts
    // 3. If any rule is not satisfied, confirm_request() will abort the transaction
    // 
    // The proper flow is:
    // 1. Add rules to policy (add_witness_rule, add_fee_rule, etc.)
    // 2. Satisfy rules by calling rule functions (confirm_witness, pay_fee, etc.) 
    // 3. Call confirm_request() - it will verify all receipts internally

    /// Create a transfer request (normally done by marketplace/kiosk)
    /// This starts the transfer process and creates the "hot potato"
    public fun create_transfer_request<T>(
        item_id: ID,
        paid_amount: u64,
        from_kiosk_id: ID
    ): TransferRequest<T> {
        policy::new_request<T>(item_id, paid_amount, from_kiosk_id)
    }

    /// Example: Complete transfer with witness authorization
    /// This shows how to use the policy in a real scenario
    public fun transfer_with_witness<T, W: drop>(
        policy: &TransferPolicy<T>,
        witness: W,
        item_id: ID,
        paid_amount: u64,
        from_kiosk_id: ID
    ) {
        // Create transfer request
        let mut request = create_transfer_request<T>(item_id, paid_amount, from_kiosk_id);
        
        // Satisfy witness rule
        confirm_witness(witness, policy, &mut request);
        
        // Complete the transfer (this will check all rules are satisfied)
        complete_transfer(policy, request);
    }

    /// Example: Complete transfer with fee payment
    public fun transfer_with_fee<T>(
        policy: &mut TransferPolicy<T>,
        payment: Coin<SUI>,
        item_id: ID,
        paid_amount: u64,
        from_kiosk_id: ID
    ) {
        // Create transfer request
        let mut request = create_transfer_request<T>(item_id, paid_amount, from_kiosk_id);
        
        // Pay the fee
        pay_fee(policy, &mut request, payment);
        
        // Complete the transfer
        complete_transfer(policy, request);
    }

    /// Example: Complete transfer with time check
    public fun transfer_with_time_check<T>(
        policy: &TransferPolicy<T>,
        clock: &Clock,
        item_id: ID,
        paid_amount: u64,
        from_kiosk_id: ID
    ) {
        // Create transfer request
        let mut request = create_transfer_request<T>(item_id, paid_amount, from_kiosk_id);
        
        // Check time requirement
        confirm_time(policy, &mut request, clock);
        
        // Complete the transfer
        complete_transfer(policy, request);
    }

    /// Example: Complete transfer with ALL rules (witness + fee + time)
    public fun transfer_with_all_rules<T, W: drop>(
        policy: &mut TransferPolicy<T>,
        witness: W,
        payment: Coin<SUI>,
        clock: &Clock,
        item_id: ID,
        paid_amount: u64,
        from_kiosk_id: ID
    ) {
        // Create transfer request
        let mut request = create_transfer_request<T>(item_id, paid_amount, from_kiosk_id);
        
        // Satisfy all rules
        confirm_witness(witness, policy, &mut request);  // Witness rule
        pay_fee(policy, &mut request, payment);          // Fee rule
        confirm_time(policy, &mut request, clock);       // Time rule
        
        // Complete the transfer - confirm_request will automatically verify
        // that all required receipts are present (matching the policy rules)
        // If any rule is not satisfied, confirm_request will abort the transaction
        complete_transfer(policy, request);
    }

    // ==================== UTILITY FUNCTIONS ====================
    
    /// Create an example NFT
    public fun create_nft(name: std::string::String, ctx: &mut TxContext): ExampleNFT {
        ExampleNFT {
            id: object::new(ctx),
            name,
        }
    }

    /// Create admin witness
    public fun create_admin_witness(): AdminWitness {
        AdminWitness {}
    }

    /// Create user witness
    public fun create_user_witness(): UserWitness {
        UserWitness {}
    }

    /// Get NFT name
    public fun nft_name(nft: &ExampleNFT): &std::string::String {
        &nft.name
    }

    // ==================== TEST HELPERS ====================
    
    #[test_only]
    public fun create_nft_for_testing(ctx: &mut TxContext): ExampleNFT {
        create_nft(std::string::utf8(b"Test NFT"), ctx)
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(TRANSFER_POLICY_SIMPLE {}, ctx);
    }

    #[test_only]
    public fun create_witness_for_testing(): TRANSFER_POLICY_SIMPLE {
        TRANSFER_POLICY_SIMPLE {}
    }

    #[test_only]
    public fun destroy_admin_witness_for_testing(witness: AdminWitness) {
        let AdminWitness {} = witness;
    }

    #[test_only]
    public fun destroy_user_witness_for_testing(witness: UserWitness) {
        let UserWitness {} = witness;
    }
}
