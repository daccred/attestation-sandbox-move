
/// Module: sas
module sas::sas {
    use sui::tx_context::{sender};
    use sui::url::{Self, Url};
    use sui::event::{emit};
    use sui::clock::{Self, Clock};
    use std::string;

    use sas::schema_record::{Self, SchemaRecord, Request};

    /// ========= Errors =========
    const EExpired: u64 = 0;

    /// ========= Events  =========
    public struct Attest has copy, drop {
        id: address,
        schema: address,
        ref_schema: address,
        attester: address,
        time: u64,
        expireation_time: u64,
        data: vector<u8>,
        name: string::String,
        description: string::String,
        url: Url,
    }

    public struct AttestWithResolver has copy, drop {
        id: address,
        schema: address,
        ref_schema: address,
        attester: address,
        time: u64,
        expireation_time: u64,
        data: vector<u8>,
        name: string::String,
        description: string::String,
        url: Url,
    }

    /// ========= Structs =========
    public struct Attesttation has key {
        id: UID,
        schema: address,
        ref_schema: address,
        attester: address,
        time: u64,
        expireation_time: u64,
        data: vector<u8>,
        name: string::String,
        description: string::String,
        url: Url,
    }

    /// ========= Public Functions =========
    public fun attest(
        schema_record: &SchemaRecord,
        ref_schema: &SchemaRecord,
        recipient: address,
        expireation_time: u64,
        data: vector<u8>,
        name: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        time: &Clock,
        ctx: &mut TxContext
    ) {
        let attester = ctx.sender();

        if (expireation_time != 0) {
            assert!(time.timestamp_ms() < expireation_time, EExpired);
        };

        let attestation = Attesttation {
            id: object::new(ctx),
            schema: object::id_address(schema_record),
            time: clock::timestamp_ms(time),
            expireation_time: expireation_time,
            ref_schema: object::id_address(ref_schema),
            attester: attester,
            data: data,
            name: string::utf8(name),
            description: string::utf8(description),
            url: url::new_unsafe_from_bytes(url)
        };

        emit(
            Attest {
                id: object::id_address(&attestation),
                schema: attestation.schema,
                ref_schema: attestation.ref_schema,
                attester: attestation.attester,
                time: attestation.time,
                expireation_time: attestation.expireation_time,
                data: attestation.data,
                name: attestation.name,
                description: attestation.description,
                url: attestation.url
            }
        );

        transfer::transfer(attestation, recipient);
    }

    public fun attest_with_resolver(
        schema_record: &SchemaRecord,
        ref_schema: &SchemaRecord,
        recipient: address,
        expireation_time: u64,
        data: vector<u8>,
        name: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        time: &Clock,
        request: Request,
        ctx: &mut TxContext
    ) {
        let attester = ctx.sender();

        if (expireation_time != 0) {
            assert!(time.timestamp_ms() < expireation_time, EExpired);
        };

        schema_record::finish_attest(schema_record, request);

        let attestation = Attesttation {
            id: object::new(ctx),
            schema: object::id_address(schema_record),
            time: clock::timestamp_ms(time),
            expireation_time: expireation_time,
            ref_schema: object::id_address(ref_schema),
            attester: attester,
            data: data,
            name: string::utf8(name),
            description: string::utf8(description),
            url: url::new_unsafe_from_bytes(url)
        };

        emit(
            AttestWithResolver {
                id: object::id_address(&attestation),
                schema: attestation.schema,
                ref_schema: attestation.ref_schema,
                attester: attestation.attester,
                time: attestation.time,
                expireation_time: attestation.expireation_time,
                data: attestation.data,
                name: attestation.name,
                description: attestation.description,
                url: attestation.url
            }
        );

        transfer::transfer(attestation, recipient);
    }

}
