#[starknet::contract]
mod zkAnonChat {
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        merkle_root: felt252,
        latest_message: felt252,
        message_posted: bool,
        admin: ContractAddress
    }

    #[starknet::interface]
    trait IzkAnonChat<TContractState> {
        fn set_merkle_root(ref self: TContractState, new_root: felt252);
        fn post_anonymous_message(ref self: TContractState, proof: Array<felt252>, message: felt252);  // Added message param
        fn get_latest_message(self: @TContractState) -> felt252;
        fn has_message_been_posted(self: @TContractState) -> bool;
        fn get_merkle_root(self: @TContractState) -> felt252;  // New getter
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: ContractAddress) {
        self.admin.write(admin);
    }

    #[abi(embed_v0)]
    impl zkAnonChatImpl of IzkAnonChat<ContractState> {
        fn set_merkle_root(ref self: ContractState, new_root: felt252) {
            self.assert_admin();
            self.merkle_root.write(new_root);
        }

        fn post_anonymous_message(ref self: ContractState, proof: Array<felt252>, message: felt252) {
            assert(proof.len() > 0, 'Proof must be provided');  // Dummy for now
            self.latest_message.write(message);  // Store dynamic message
            self.message_posted.write(true);
        }

        fn get_latest_message(self: @ContractState) -> felt252 {
            self.latest_message.read()
        }

        fn has_message_been_posted(self: @ContractState) -> bool {
            self.message_posted.read()
        }

        fn get_merkle_root(self: @ContractState) -> felt252 {
            self.merkle_root.read()
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn assert_admin(ref self: ContractState) {
            let caller = get_caller_address();
            assert(caller == self.admin.read(), 'Only admin can call this');
        }
    }
}