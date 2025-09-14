#[cfg(test)]
mod integration_tests {
    use snforge_std_deprecated::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address};
    use starknet::ContractAddress;
    use contract::zkAnonChat::IzkAnonChatDispatcher;
    use contract::zkAnonChat::IzkAnonChatDispatcherTrait;

    #[test]
    fn test_deployment_and_admin() {
        let declared = declare("zkAnonChat").unwrap();
        let contract_class = declared.contract_class();

        let admin: ContractAddress = starknet::contract_address_const::<0x1>();
        let admin_felt: felt252 = admin.into();
        let mut _calldata: Array<felt252> = array![admin_felt];

        let (contract_address, _) = contract_class.deploy(@_calldata).unwrap();

        let dispatcher = IzkAnonChatDispatcher { contract_address };

        assert(!dispatcher.has_message_been_posted(), 'No msg posted init');

        start_cheat_caller_address(contract_address, admin);
        let _new_root: felt252 = 123456;
        dispatcher.set_merkle_root(_new_root);
    }

    #[test]
    #[should_panic(expected: ('Only admin can call this', ))]
    fn test_non_admin_cannot_set_root() {
        let declared = declare("zkAnonChat").unwrap();
        let contract_class = declared.contract_class();

        let admin: ContractAddress = starknet::contract_address_const::<0x1>();
        let admin_felt: felt252 = admin.into();
        let mut _calldata: Array<felt252> = array![admin_felt];

        let (contract_address, _) = contract_class.deploy(@_calldata).unwrap();

        let dispatcher = IzkAnonChatDispatcher { contract_address };

        let non_admin: ContractAddress = starknet::contract_address_const::<0x2>();
        start_cheat_caller_address(contract_address, non_admin);

        dispatcher.set_merkle_root(999);
    }

    #[test]
    fn test_post_message_and_getters() {
        let declared = declare("zkAnonChat").unwrap();
        let contract_class = declared.contract_class();

        let admin: ContractAddress = starknet::contract_address_const::<0x1>();
        let admin_felt: felt252 = admin.into();
        let mut _calldata: Array<felt252> = array![admin_felt];

        let (contract_address, _) = contract_class.deploy(@_calldata).unwrap();

        let dispatcher = IzkAnonChatDispatcher { contract_address };

        let _proof: Array<felt252> = array![1, 2, 3];
        dispatcher.post_anonymous_message(_proof);

        assert(dispatcher.has_message_been_posted(), 'Msg posted');
        assert(dispatcher.get_latest_message() == 0x48656c6c6f205a4b21, 'Wrong msg');
    }
}