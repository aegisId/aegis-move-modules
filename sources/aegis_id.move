module aegis::aegis {
    use std::error;
    use std::signer;
    use std::signer::address_of;
    use aptos_framework::account;
    use aptos_framework::timestamp;

    struct Profile has key {
        primary: address,
        res_addr: address,
        res_cap: account::SignerCapability,
    }

    struct Twitter has key {
        is_verified: bool,
        expires_at: u64,
    }
    struct Telegram has key {
        is_verified: bool
    }

    const TWITTER_EXP: u64 = 15_552_000; // 6 Months
    const E_NO_PROFILE: u64 = 1;
    const E_TWITTER_EXISTS: u64 = 2;
    const E_INVALID_VERIFIER: u64 = 3;
    const E_TELEGRAM_EXISTS: u64 = 4;


    public entry fun create_profile(acc: &signer) {
        let addr = signer::address_of(acc);
        assert!(!exists<Profile>(addr), error::already_exists(E_NO_PROFILE));

        let (res_signer, res_cap) = account::create_resource_account(acc, b"aegis");
        let res_addr = signer::address_of(&res_signer);

        move_to(acc, Profile { primary: addr, res_cap, res_addr });
    }

    public entry fun add_twitter(acc: &signer, verifier: &signer) acquires Profile {
        assert!(address_of(verifier) == @aegis, E_INVALID_VERIFIER);
        let addr = signer::address_of(acc);
        if (!exists<Profile>(addr)) create_profile(acc);
        let profile = borrow_global<Profile>(addr);
        let res_signer = account::create_signer_with_capability(&profile.res_cap);
        assert!(!exists<Twitter>(profile.res_addr), error::already_exists(E_TWITTER_EXISTS));
        move_to(&res_signer, Twitter {
            is_verified: true,
            expires_at: timestamp::now_seconds() + TWITTER_EXP,
        });
    }

    public entry fun add_telegram(acc: &signer, verifier: &signer) acquires Profile {
        assert!(address_of(verifier) == @aegis, E_INVALID_VERIFIER);
        let addr = signer::address_of(acc);
        if (!exists<Profile>(addr)) create_profile(acc);
        let profile = borrow_global<Profile>(addr);
        let res_signer = account::create_signer_with_capability(&profile.res_cap);
        assert!(!exists<Telegram>(profile.res_addr), error::already_exists(E_TELEGRAM_EXISTS));
        move_to(&res_signer, Telegram {
            is_verified: true,
        });
    }

    #[view]
    public fun has_twitter(addr: address): bool acquires Profile {
        if(exists<Profile>(addr)) exists<Twitter>(borrow_global<Profile>(addr).res_addr) else false
    }

    #[view]
    public fun has_telegram(addr: address): bool acquires Profile {
        if(exists<Profile>(addr)) exists<Telegram>(borrow_global<Profile>(addr).res_addr) else false
    }

    #[view]
    public fun twitter_expiry(addr: address): u64 acquires Profile, Twitter {
        assert!(exists<Profile>(addr), error::not_found(E_NO_PROFILE));
        let res_addr = borrow_global<Profile>(addr).res_addr;
        assert!(exists<Twitter>(res_addr), error::not_found(E_TWITTER_EXISTS));
        borrow_global<Twitter>(res_addr).expires_at
    }
}