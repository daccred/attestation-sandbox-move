module sas::schema_registry { 
    use sui::{
    vec_map::{Self, VecMap},
    };
    use sas::schema_record::{Self, SchemaRecord};

    const ESchemaNotFound: u64 = 0;

    /// ======== OTW ========
    
    public struct SCHEMA_REGISTRY has drop {}

    public struct SchemaRegistry has key, store {
        id: UID,
        schema_records: VecMap<address, SchemaRecord>,
    }

    fun init(_otw: SCHEMA_REGISTRY, ctx: &mut TxContext) {
        let schema_registry = SchemaRegistry {
            id: object::new(ctx),
            schema_records: vec_map::empty(),
        };

        transfer::share_object(schema_registry);
    }

    public fun resitry(
        schema_record: SchemaRecord,
        registry: &mut SchemaRegistry,
        _ctx: &mut TxContext
    ) {
        registry.schema_records.insert(object::id_address(&schema_record), schema_record);
    }

    public fun register_with_schema(
        schema: vector<u8>,
        registry: &mut SchemaRegistry,
        ctx: &mut TxContext
    ) {
        let schema_record = schema_record::new(schema, ctx);

        registry.schema_records.insert(object::id_address(&schema_record), schema_record);
    }

    public fun schema_keys(
        registry: &SchemaRegistry
    ): vector<address> {
        vec_map::keys(&registry.schema_records)
    }

    public fun schema(
        id: address,
        registry: &SchemaRegistry
    ): vector<u8> {
        assert!(registry.schema_records.contains(&id), ESchemaNotFound);
        let schema_record = vec_map::get(&registry.schema_records, &id);
        schema_record::schema(schema_record)
    }

}