/// Token Sale example

module sample::atoken {
    use sui::coin::{Self, TreasuryCap, Coin};
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};

    public struct ATOKEN has drop {}

    public struct Sale has key {
        id: UID,
        cap: TreasuryCap<ATOKEN>,
        price: u64,
        start_ms: u64,
        end_ms: u64,
        sui_balance: Balance<SUI>
    }

    public struct SaleBuyEvent has copy, drop {
        buyer: address,
        sui_spent: u64,
        tokens_bought: u64
    }

    // Initialize the module and token
    fun init(
        witness: ATOKEN,
        ctx: &mut TxContext
    ) {
        let (treasury_cap, metadata) = coin::create_currency(
            witness,
            6,                // decimals
            b"A TOKEN",       // name
            b"",              // symbol
            b"",              // description
            option::none(),   // icon_url
            ctx
        );

        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
    }

    // Creates the token sale, only callable by deployer as checking TreasuryCap
    public fun create_sale(
        cap: TreasuryCap<ATOKEN>,
        price: u64,
        start_ms: u64,
        end_ms: u64,
        ctx: &mut TxContext
    ) {
        let sale = Sale {
            id: object::new(ctx),
            cap,
            price,
            start_ms,
            end_ms,
            sui_balance: balance::zero()
        };

        transfer::share_object(sale);
    }

    /// Buy coins from presale (using sui payment, amount in)
    #[allow(lint(self_transfer))]
    public fun buy_coins(sale: &mut Sale, payment: Coin<SUI>, ctx: &mut TxContext) {
        let tokens_bought = sale.price * coin::value(&payment);

        let minted_coins = coin::mint(&mut sale.cap, tokens_bought, ctx);
        transfer::public_transfer(minted_coins, ctx.sender());

        sui::event::emit(SaleBuyEvent {
            buyer: ctx.sender(),
            sui_spent: coin::value(&payment),
            tokens_bought
        });

        coin::put(&mut sale.sui_balance, payment);
    }

}