module aegis::aegis_id {
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
        verified: bool,
        expires: u64,
    }

    const TWITTER_EXP: u64 = 15_552_000; // 6 Months
    const E_NO_PROFILE: u64 = 1;
    const E_TWITTER_EXISTS: u64 = 2;
    const E_INVALID_VERIFIER: u64 = 3;


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
            verified: true,
            expires: timestamp::now_seconds() + TWITTER_EXP,
        });
    }

    #[view]
    public fun has_twitter(addr: address): bool acquires Profile {
        assert!(exists<Profile>(addr), error::not_found(E_NO_PROFILE));
        exists<Twitter>(borrow_global<Profile>(addr).res_addr)
    }

    #[view]
    public fun twitter_expiry(addr: address): u64 acquires Profile, Twitter {
        assert!(exists<Profile>(addr), error::not_found(E_NO_PROFILE));
        let res_addr = borrow_global<Profile>(addr).res_addr;
        assert!(exists<Twitter>(res_addr), error::not_found(E_TWITTER_EXISTS));
        borrow_global<Twitter>(res_addr).expires
    }
}