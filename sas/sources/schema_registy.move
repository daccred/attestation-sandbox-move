module sas::schema_registry { 
    use sui::{
    vec_map::{Self, VecMap},
    };
    use sas::schema_record::{SchemaRecord};

    /// ======== Errors ========

    const ESchemaNotFound: u64 = 0;

    /// ======== OTW ========
    
    public struct SCHEMA_REGISTRY has drop {}

    /// ======== Structs ========

    public struct Status has copy, store {
        is_revoked: bool,
        timestamp: u64,
    }

    public struct SchemaRegistry has key, store {
        id: UID,
        schema_records: VecMap<address, Status>,
    }


    /// ========== Init Function ==========
    
    fun init(_otw: SCHEMA_REGISTRY, ctx: &mut TxContext) {
        let schema_registry = SchemaRegistry {
            id: object::new(ctx),
            schema_records: vec_map::empty(),
        };

        transfer::share_object(schema_registry);
    }

    /// ========== Public-Mutating Functions ==========
    
    public fun registry(
        schema_record: &SchemaRecord,
        registry: &mut SchemaRegistry,
        _ctx: &mut TxContext
    ) {
        registry.schema_records.insert(object::id_address(schema_record), Status {
            is_revoked: false,
            timestamp: 0,
        });
    }

    /// ========== Public-View Functions ==========
    
    public fun schema_keys(
        registry: &SchemaRegistry
    ): vector<address> {
        vec_map::keys(&registry.schema_records)
    }

    public fun status(
        id: address,
        registry: &SchemaRegistry
    ): Status {
        assert!(registry.schema_records.contains(&id), ESchemaNotFound);
        *vec_map::get(&registry.schema_records, &id)
    }

}