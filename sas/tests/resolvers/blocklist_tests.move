#[test_only]
module sas::blocklist_tests {
    use sui::{
        test_scenario::{Self},
        clock::{Self}
    };
    use sas::sas::{Self, Attesttation};
    use sas::schema_record::{Self, SchemaRecord};
    use sas::blocklist::{Self};

    #[test]
    fun test_blocklist() {
        let alice: address = @0x1;
        let bob: address = @0x2;
        let cathrine: address = @0x3;

        let schema: vector<u8> = b"name: string, age: u64";
        let data: vector<u8> = b"alice, 100";
        let name: vector<u8> = b"Profile";
        let description: vector<u8> = b"Profile of a user";
        let url: vector<u8> = b"https://example.com";

        let mut scenario = test_scenario::begin(alice);
        {

            let (mut schema_record, mut resolver_builder) = schema_record::new_with_resolver(schema, test_scenario::ctx(&mut scenario));
            let resolver_admin = blocklist::add(&schema_record, &mut resolver_builder, test_scenario::ctx(&mut scenario));
            schema_record.add_resolver(resolver_builder);
            
            blocklist::add_user(&resolver_admin, &mut schema_record, cathrine);
            assert!(blocklist::is_blocklisted(&schema_record, cathrine));
            assert!(!blocklist::is_blocklisted(&schema_record, bob));

            let mut request = schema_record.start_attest();
            blocklist::approve(&schema_record, &mut request, test_scenario::ctx(&mut scenario));

            let clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));

            sas::attest_with_resolver(
                &schema_record,
                @0x0,
                bob,
                false,
                0,
                data,
                name,
                description,
                url,
                &clock,
                request,
                test_scenario::ctx(&mut scenario)
            );

            transfer::public_transfer(schema_record, bob);
            transfer::public_transfer(resolver_admin, alice);
            clock::share_for_testing(clock);
        };

        test_scenario::next_tx(&mut scenario, bob);
        {
            let schema_record = test_scenario::take_from_sender<SchemaRecord>(&scenario);
            let attestation = test_scenario::take_from_sender<Attesttation>(&scenario);
            assert!(sas::schema(&attestation) == schema_record.addy());

            test_scenario::return_to_sender<SchemaRecord>(&scenario, schema_record);
            test_scenario::return_to_sender<Attesttation>(&scenario, attestation);
        };

        test_scenario::end(scenario);
    }
}