module sas::schema_registry { 
    use sui::{
    vec_map::{Self, VecMap},
    };

    /// ======== Errors ========

    const ESchemaNotFound: u64 = 0;
    const ESchmaAlreadyExist: u64 = 1;
    const EInvalidStartIndex: u64 = 2;

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
        let total = vec_map::size(&self.schema_records);
        assert!(start < total, EInvalidStartIndex);

        let end = std::u64::min(start + limit, total);
        let keys = vec_map::keys(&self.schema_records);
        
        let mut result = vector::empty<address>();
        let mut i = start;
        while (i < end) {
            vector::push_back(&mut result, *vector::borrow(&keys, i));
            i = i + 1;
        };
        
        result
    }


    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        init(SCHEMA_REGISTRY {}, ctx);
    }

}