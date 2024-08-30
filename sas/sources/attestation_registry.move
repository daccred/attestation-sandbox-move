module sas::attestation_registry {
    use sui::{
        table::{Self, Table},
        versioned::{Self, Versioned},
        vec_set::{Self, VecSet},
    };
    use sas::constants;

    // === Errors ===
    const EAttestationNotFound: u64 = 0;
    const EVersionNotEnabled: u64 = 1;

    // === OTW ===
    public struct ATTESTATION_REGISTRY has drop {}

    // === Structs ===
    public struct Status has copy, store {
        is_revoked: bool,
        timestamp: u64,
    }

    public struct AttestationRegistry has key, store {
        id: UID,
        inner: Versioned,
    }

    public struct RegistryInner has store {
        allowed_versions: VecSet<u64>,
        /// attestation -> status
        attestations_status: Table<address, Status>,
    }

    // === Init Function ===
    fun init(_otw: ATTESTATION_REGISTRY, ctx: &mut TxContext) {
        let registry_inner = RegistryInner {
            allowed_versions: vec_set::singleton(constants::current_version()),
            attestations_status: table::new<address, Status>(ctx),
        };
        let attestation_registry = AttestationRegistry {
            id: object::new(ctx),
            inner: versioned::create(
                constants::current_version(),
                registry_inner,
                ctx,
            ),
        };

        transfer::share_object(attestation_registry);
    }

    // === Public-Mutating Functions ===
    public fun registry(self: &mut AttestationRegistry, attestation: address) {
        let inner = self.load_inner_mut();
        assert!(!inner.attestations_status.contains(attestation), EAttestationNotFound);
        table::add(&mut inner.attestations_status, attestation, Status {
            is_revoked: false,
            timestamp: 0,
        });
    }

    // === Public-Package Functions ===
    public(package) fun load_inner_mut(self: &mut AttestationRegistry): &mut RegistryInner {
        let inner: &mut RegistryInner = versioned::load_value_mut(&mut self.inner);
        let package_version = constants::current_version();
        assert!(
            inner.allowed_versions.contains(&package_version),
            EVersionNotEnabled,
        );
        inner
    }

    public(package) fun load_inner(self: &AttestationRegistry): &RegistryInner {
        let inner: &RegistryInner = versioned::load_value(&self.inner);
        let package_version = constants::current_version();
        assert!(
            inner.allowed_versions.contains(&package_version),
            EVersionNotEnabled,
        );
        inner
    }


    // === Public-View Functions ===
    public fun is_exist(self: &AttestationRegistry, attestation: address): bool {
        let self = self.load_inner();
        table::contains(&self.attestations_status, attestation)
    }
    
    public fun attestations(self: &AttestationRegistry): &Table<address, Status> {
        let self = self.load_inner();
        &self.attestations_status
    }

    public fun status(self: &AttestationRegistry, attestation: address): &Status {
        let self = self.load_inner();
        assert!(self.attestations_status.contains(attestation), EAttestationNotFound);
        table::borrow(&self.attestations_status, attestation)
    }

    public fun is_revoked(self: &AttestationRegistry, attestation: address): bool {
        let self = self.load_inner();
        assert!(self.attestations_status.contains(attestation), EAttestationNotFound);
        let status = table::borrow(&self.attestations_status, attestation);
        status.is_revoked
    }
 
    // === Test Functions ===
    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        init(ATTESTATION_REGISTRY {}, ctx);
    }

}