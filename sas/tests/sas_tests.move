#[test_only]
module sas::sas_tests {
    use std::string;
    use sui::{
        test_scenario::{Self},
        clock::{Self}
    };
    use sas::sas::{Self, Attestation};
    use sas::schema::{Self, SchemaRecord, ResolverBuilder};
    use sas::schema_registry::{Self, SchemaRegistry};
    use sas::attestation_registry::{Self, AttestationRegistry};

    use fun string::utf8 as vector.utf8;

    const ENotImplemented: u64 = 0;

    public struct Witness has drop {}

    #[test]
    fun test_attest() {
        let admin: address = @0x1;
        let user: address = @0x2;

        let schema: vector<u8> = b"name: string, age: u64";
        let data: vector<u8> = b"alice, 100";
        let name: vector<u8> = b"Profile";
        let description: vector<u8> = b"Profile of a user";
        let url: vector<u8> = b"https://example.com";

        let mut scenario = test_scenario::begin(admin);
        {
            schema_registry::test_init(test_scenario::ctx(&mut scenario));
            attestation_registry::test_init(test_scenario::ctx(&mut scenario));
        };

        test_scenario::next_tx(&mut scenario, admin);
        {   
            let mut schema_registry = test_scenario::take_shared<SchemaRegistry>(&scenario);
            let mut attestation_registry = test_scenario::take_shared<AttestationRegistry>(&scenario);

            let schema_record = schema::new(&mut schema_registry, schema, false, test_scenario::ctx(&mut scenario));
            let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
            sas::attest(
                &schema_record,
                &mut attestation_registry,
                @0x0,
                user,
                0,
                data,
                name,
                description,
                url,
                &clock,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared<SchemaRegistry>(schema_registry);
            test_scenario::return_shared<AttestationRegistry>(attestation_registry);
            transfer::public_transfer(schema_record, user);
            clock::share_for_testing(clock);
        };

        test_scenario::next_tx(&mut scenario, user);
        {
            let schema_record = test_scenario::take_from_sender<SchemaRecord>(&scenario);
            let attestation = test_scenario::take_from_sender<Attestation>(&scenario);
            assert!(sas::schema(&attestation) == schema_record.addy());

            test_scenario::return_to_sender<SchemaRecord>(&scenario, schema_record);
            test_scenario::return_to_sender<Attestation>(&scenario, attestation);
        };

        test_scenario::end(scenario);
    }

    #[test]
    fun test_attest_with_resolver() {
        let admin: address = @0x1;
        let user: address = @0x2;

        let schema: vector<u8> = b"name: string, age: u64";
        let data: vector<u8> = b"alice, 100";
        let name: vector<u8> = b"Profile";
        let description: vector<u8> = b"Profile of a user";
        let url: vector<u8> = b"https://example.com";

        let mut scenario = test_scenario::begin(admin);
        {
            schema_registry::test_init(test_scenario::ctx(&mut scenario));
            attestation_registry::test_init(test_scenario::ctx(&mut scenario));
        };

        test_scenario::next_tx(&mut scenario, admin);
        {
            let mut schema_registry = test_scenario::take_shared<SchemaRegistry>(&scenario);
            let mut attestation_registry = test_scenario::take_shared<AttestationRegistry>(&scenario);
            
            let (mut schema_record, mut resolver_builder) = schema::new_with_resolver(&mut schema_registry, schema, false, test_scenario::ctx(&mut scenario));

            add_rule(&mut resolver_builder, schema::start_attest_name());

            schema_record.add_resolver(resolver_builder);

            let mut start_request = schema_record.start_attest();
            start_request.approve(Witness {});

            let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
            sas::attest_with_resolver(
                &schema_record,
                &mut attestation_registry,
                @0x0,
                user,
                0,
                data,
                name,
                description,
                url,
                &clock,
                start_request,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared<SchemaRegistry>(schema_registry);
            test_scenario::return_shared<AttestationRegistry>(attestation_registry);

            transfer::public_transfer(schema_record, user);
            clock::share_for_testing(clock);
        };

        test_scenario::next_tx(&mut scenario, user);
        {
            let schema_record = test_scenario::take_from_sender<SchemaRecord>(&scenario);
            let attestation = test_scenario::take_from_sender<Attestation>(&scenario);
            assert!(sas::schema(&attestation) == schema_record.addy());

            test_scenario::return_to_sender<SchemaRecord>(&scenario, schema_record);
            test_scenario::return_to_sender<Attestation>(&scenario, attestation);
        };

        test_scenario::end(scenario);
    }

    fun add_rule(resolver_builder: &mut ResolverBuilder, name: vector<u8>) {
        resolver_builder.add_rule(name.utf8(), Witness {});
    }

    #[test, expected_failure(abort_code = ::sas::sas_tests::ENotImplemented)]
    fun test_sas_fail() {
        abort ENotImplemented
    }
}
