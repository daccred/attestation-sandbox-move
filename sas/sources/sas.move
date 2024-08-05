
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
        ref_id: address,
        attester: address,
        revokable: bool,
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
        ref_id: address,
        attester: address,
        revokable: bool,    
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
        ref_id: address,
        attester: address,
        time: u64,
        revokable: bool,
        expireation_time: u64,
        data: vector<u8>,
        name: string::String,
        description: string::String,
        url: Url,
    }


    /// ========= Public-View Funtions =========
    
    public fun schema(self: &Attesttation): address {
        self.schema
    }

    public fun ref_id(self: &Attesttation): address {
        self.ref_id
    }

    public fun attester(self: &Attesttation): address {
        self.attester
    }

    public fun time(self: &Attesttation): u64 {
        self.time
    }

    public fun revokable(self: &Attesttation): bool {
        self.revokable
    }

    public fun expireation_time(self: &Attesttation): u64 {
        self.expireation_time
    }

    public fun data(self: &Attesttation): vector<u8> {
        self.data
    }

    public fun name(self: &Attesttation): string::String {
        self.name
    }

    public fun description(self: &Attesttation): string::String {
        self.description
    }

    public fun url(self: &Attesttation): Url {
        self.url
    }

    /// ========= Public Functions =========
    
    public fun attest(
        schema_record: &SchemaRecord,
        ref_id: address,
        recipient: address,
        revokeable: bool,
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
            revokable: revokeable,
            ref_id: ref_id,
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
                ref_id: attestation.ref_id,
                attester: attestation.attester,
                revokable: attestation.revokable,
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
        ref_id: address,
        recipient: address,
        revokable: bool,
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
            ref_id: ref_id,
            attester: attester,
            revokable: revokable,
            data: data,
            name: string::utf8(name),
            description: string::utf8(description),
            url: url::new_unsafe_from_bytes(url)
        };

        emit(
            AttestWithResolver {
                id: object::id_address(&attestation),
                schema: attestation.schema,
                ref_id: attestation.ref_id,
                attester: attestation.attester,
                revokable: attestation.revokable,
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
