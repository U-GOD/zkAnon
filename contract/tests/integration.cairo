// contract/tests/test_zkAnon.cairo
#[cfg(test)]
mod integration_tests {
    use snforge_std_deprecated::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address};
    use starknet::ContractAddress;
    use contract::zkAnonChat::IzkAnonChatDispatcher;
    use contract::zkAnonChat::IzkAnonChatDispatcherTrait;

    // Test 1: Basic deployment and admin functionality
    #[test]
    fn test_deployment_and_admin() {
        // Declare and deploy the contract
        let declared = declare("zkAnonChat").unwrap();
        let contract_class = declared.contract_class();

        // Setup admin address and deployment parameters
        let admin: ContractAddress = starknet::contract_address_const::<0x1>();
        let admin_felt: felt252 = admin.into();
        let mut _calldata: Array<felt252> = array![admin_felt];

        // Deploy contract with admin address
        let (contract_address, _) = contract_class.deploy(@_calldata).unwrap();

        // Create dispatcher to interact with the contract
        let dispatcher = IzkAnonChatDispatcher { contract_address };

        // Verify initial state
        assert(!dispatcher.has_message_been_posted(), 'No msg posted init');

        // Test admin functionality
        start_cheat_caller_address(contract_address, admin);  // Impersonate admin
        let _new_root: felt252 = 123456;
        dispatcher.set_merkle_root(_new_root);  // Admin sets root

        // Verify root was set correctly
        assert(dispatcher.get_merkle_root() == _new_root, 'Wrong root');
    }

    // Test 2: Security - non-admin should NOT be able to set root
    #[test]
    #[should_panic(expected: ('Only admin can call this', ))]  // Expect this error
    fn test_non_admin_cannot_set_root() {
        // Deploy contract
        let declared = declare("zkAnonChat").unwrap();
        let contract_class = declared.contract_class();

        let admin: ContractAddress = starknet::contract_address_const::<0x1>();
        let admin_felt: felt252 = admin.into();
        let mut _calldata: Array<felt252> = array![admin_felt];

        let (contract_address, _) = contract_class.deploy(@_calldata).unwrap();
        let dispatcher = IzkAnonChatDispatcher { contract_address };

        // Try to call as non-admin (should fail)
        let non_admin: ContractAddress = starknet::contract_address_const::<0x2>();
        start_cheat_caller_address(contract_address, non_admin);  // Impersonate non-admin
        dispatcher.set_merkle_root(999);  // This should panic
    }

    // Test 3: Message posting functionality
    #[test]
    fn test_post_message_and_getters() {
        // Deploy contract
        let declared = declare("zkAnonChat").unwrap();
        let contract_class = declared.contract_class();

        let admin: ContractAddress = starknet::contract_address_const::<0x1>();
        let admin_felt: felt252 = admin.into();
        let mut _calldata: Array<felt252> = array![admin_felt];

        let (contract_address, _) = contract_class.deploy(@_calldata).unwrap();
        let dispatcher = IzkAnonChatDispatcher { contract_address };

        // Test message posting
        let _proof: Array<felt252> = array![1, 2, 3];  // Dummy proof (currently accepted)
        let test_message: felt252 = 0x74657374206d657373616765;  // "test message" in hex
        dispatcher.post_anonymous_message(_proof, test_message);  // Post message

        // Verify message was stored correctly
        assert(dispatcher.has_message_been_posted(), 'Msg posted');
        assert(dispatcher.get_latest_message() == test_message, 'Wrong msg');
    }
}