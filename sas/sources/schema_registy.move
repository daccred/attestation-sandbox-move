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
        next_id: u64,
        schema_records: VecMap<address, address>, // SchemaRecord -> Creattor
    }


    /// ========== Init Function ==========
    
    fun init(_otw: SCHEMA_REGISTRY, ctx: &mut TxContext) {
        let schema_registry = SchemaRegistry {
            id: object::new(ctx),
            next_id: 1,
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
        self.update_next_id();
    }

    /// ========== Private Functions ==========
    fun update_next_id(self: &mut SchemaRegistry) {
        self.next_id = self.next_id + 1;
    }

    /// ========== Public-View Functions ==========
    
    public fun is_exist(
        self: &SchemaRegistry,
        schema_record: address
    ): bool {
        self.schema_records.contains(&schema_record)
    }
    
    public fun schema_keys(
        self: &SchemaRegistry
    ): vector<address> {
        vec_map::keys(&self.schema_records)
    }

    public fun creator(
        registry: &SchemaRegistry,
        id: address
    ): address {
        assert!(registry.schema_records.contains(&id), ESchemaNotFound);
        *vec_map::get(&registry.schema_records, &id)
    }

    public fun next_id(
        self: &SchemaRegistry
    ): u64 {
        self.next_id
    }

    public fun get_schema_paginated(
        self: &SchemaRegistry,
        start: u64,
        limit: u64
    ): vector<address> {
        let mut start_index = start;
        let end_index = std::u64::min(start + limit, self.next_id);
        let mut keys = self.schema_records.keys();
        let mut result = vector::empty<address>();
        while(start_index < end_index) {
            vector::push_back(&mut result, vector::remove(&mut keys, start_index));
            start_index = start_index + 1;
        };
        result
    }


    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        init(SCHEMA_REGISTRY {}, ctx);
    }

}