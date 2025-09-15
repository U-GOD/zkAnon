// contract/src/lib.cairo
#[starknet::contract]
mod zkAnonChat {
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    // Storage structure - where all contract data is stored on-chain
    #[storage]
    struct Storage {
        merkle_root: felt252,          // Root hash of the Merkle tree for group membership
        latest_message: felt252,       // The most recently posted anonymous message
        message_posted: bool,          // Flag indicating if any message has been posted
        admin: ContractAddress         // Address of the contract administrator
    }

    // Public interface - functions that can be called externally
    #[starknet::interface]
    trait IzkAnonChat<TContractState> {
        fn set_merkle_root(ref self: TContractState, new_root: felt252);
        fn post_anonymous_message(ref self: TContractState, proof: Array<felt252>, message: felt252);
        fn get_latest_message(self: @TContractState) -> felt252;
        fn has_message_been_posted(self: @TContractState) -> bool;
        fn get_merkle_root(self: @TContractState) -> felt252;
    }

    // Constructor - called once during contract deployment
    #[constructor]
    fn constructor(ref self: ContractState, admin: ContractAddress) {
        self.admin.write(admin);  // Set the initial admin address
    }

    // Main contract implementation
    #[abi(embed_v0)]
    impl zkAnonChatImpl of IzkAnonChat<ContractState> {
        // ADMIN: Set the Merkle root (only callable by admin)
        fn set_merkle_root(ref self: ContractState, new_root: felt252) {
            self.assert_admin();  // Security check
            self.merkle_root.write(new_root);  // Update the root
        }

        // USER: Post an anonymous message with a ZK proof
        fn post_anonymous_message(ref self: ContractState, proof: Array<felt252>, message: felt252) {
            assert(proof.len() > 0, 'Proof must be provided');  // TODO: Replace with real ZK verification
            self.latest_message.write(message);  // Store the user's message
            self.message_posted.write(true);     // Mark as posted
        }

        // READ: Get the latest posted message
        fn get_latest_message(self: @ContractState) -> felt252 {
            self.latest_message.read()
        }

        // READ: Check if any message has been posted
        fn has_message_been_posted(self: @ContractState) -> bool {
            self.message_posted.read()
        }

        // READ: Get the current Merkle root
        fn get_merkle_root(self: @ContractState) -> felt252 {
            self.merkle_root.read()
        }
    }

    // Internal functions for security and access control
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        // Security check: Verify caller is the admin
        fn assert_admin(ref self: ContractState) {
            let caller = get_caller_address();
            assert(caller == self.admin.read(), 'Only admin can call this');
        }
    }
}