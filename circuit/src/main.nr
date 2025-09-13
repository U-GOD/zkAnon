// circuit/src/main.nr
use dep::std;

fn main(
    // USER'S SECRET INPUTS (they keep these private)
    secret_leaf: Field,        // The user's secret identity
    secret_path: [Field; 3],   // The path through the tree (hashes of siblings)
    secret_index: Field,       // Which position the user is in (0, 1, 2, 3)
    
    // PUBLIC INPUTS (everyone sees these)
    root: pub Field            // The known root of the Merkle tree
) {
    // 1. Start with the user's secret leaf
    let mut current_hash = secret_leaf;
    let mut current_index = secret_index;

    // 2. Walk up the tree level by level
    for i in 0..3 {
        let sibling_hash = secret_path[i];
        
        // Are we the left or right child?
        if (current_index as u32) % 2 == 0 {
            // We're left child: hash(current + sibling)
            // Create a fixed-size array for the hash function
            let input_array: [Field; 2] = [current_hash, sibling_hash];
            current_hash = std::hash::pedersen_hash(input_array);
        } else {
            // We're right child: hash(sibling + current)  
            let input_array: [Field; 2] = [sibling_hash, current_hash];
            current_hash = std::hash::pedersen_hash(input_array);
        }
        
        // Move to next level in the tree
        current_index = current_index / 2;
    }

    // 3. Final check: does our calculated root match the public root?
    assert(current_hash == root);
}