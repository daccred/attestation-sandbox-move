module sas::schema_registry { 
    use sui::{
    vec_map::{Self, VecMap},
    };

    /// ======== Errors ========

    const ESchemaNotFound: u64 = 0;
    const ESchmaAlreadyExist: u64 = 1;

    /// ======== OTW ========
    
    public struct SCHEMA_REGISTRY has drop {}

    /// ======== Structs ========

    public struct SchemaRegistry has key, store {
        id: UID,
        schema_records: VecMap<address, address>, // SchemaRecord -> Creattor
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
        self: &mut SchemaRegistry,
        schema_record: address,
        ctx: &mut TxContext
    ) {
        assert!(!self.is_exist(schema_record), ESchmaAlreadyExist);
        self.schema_records.insert(schema_record, ctx.sender());
    }

    /// ========== Public-View Functions ==========
    
    public fun is_exist(
        self: &SchemaRegistry,
        schema_record: address
    ): bool {
        self.schema_records.contains(&schema_record)
    }
    
    public fun schema_keys(
        registry: &SchemaRegistry
    ): vector<address> {
        vec_map::keys(&registry.schema_records)
    }

    public fun creator(
        id: address,
        registry: &SchemaRegistry
    ): address {
        assert!(registry.schema_records.contains(&id), ESchemaNotFound);
        *vec_map::get(&registry.schema_records, &id)
    }

    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        init(SCHEMA_REGISTRY {}, ctx);
    }

}