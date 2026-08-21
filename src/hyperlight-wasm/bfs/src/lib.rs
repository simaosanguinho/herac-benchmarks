use rand::Rng;
use serde::Deserialize;
use std::collections::VecDeque;
use std::ffi::CStr;

#[derive(Deserialize)]
#[serde(untagged)]
enum JsonUsize {
    Number(usize),
    String(String),
}

impl JsonUsize {
    fn into_usize(self) -> Option<usize> {
        match self {
            JsonUsize::Number(value) => Some(value),
            JsonUsize::String(value) => value.parse().ok(),
        }
    }
}

#[derive(Deserialize)]
struct BfsInput {
    size: Option<JsonUsize>,
    m: Option<JsonUsize>,
}


pub fn run_bfs_impl(size: usize, m: usize) -> i32 {

    // --- 1. Efficient Graph Storage ---
    // Total edges: size * m. Each edge is stored twice (undirected).
    // Using a flat Vec instead of Vec<Vec<u32>>
    let mut adj = vec![u32::MAX; size * m * 2]; 
    let mut counts = vec![0usize; size];
    let mut repeated_nodes = Vec::with_capacity(size * m * 2);

    let add_edge = |u: usize, v: usize, adj: &mut [u32], counts: &mut [usize]| {
        adj[u * m * 2 + counts[u]] = v as u32;
        counts[u] += 1;
        adj[v * m * 2 + counts[v]] = u as u32;
        counts[v] += 1;
    };

    // Initial clique
    for i in 0..m {
        for j in i + 1..m {
            add_edge(i, j, &mut adj, &mut counts);
            repeated_nodes.push(i as u32);
            repeated_nodes.push(j as u32);
        }
    }

    // Preferential attachment
    let mut rng = rand::thread_rng();
    let mut targets = Vec::with_capacity(m);
    for i in m..size {
        targets.clear();
        while targets.len() < m {
            let target = repeated_nodes[rng.gen_range(0..repeated_nodes.len())];
            if !targets.contains(&target) { targets.push(target); }
        }
        for &target in &targets {
            add_edge(i, target as usize, &mut adj, &mut counts);
            repeated_nodes.push(i as u32);
            repeated_nodes.push(target);
        }
    }

    // CRITICAL: Free the generation data before BFS
    drop(repeated_nodes);
    drop(counts);

    // --- 2. BFS Execution ---
    // Use 1 bit per node instead of 1 byte
    let mut visited = vec![0u64; (size / 64) + 1]; 
    let mut bfs_order = Vec::with_capacity(size);
    let mut queue = VecDeque::with_capacity(1024);

    // Helper to check/set bitset
    let is_visited = |v: usize, v_map: &[u64]| (v_map[v / 64] & (1 << (v % 64))) != 0;
    let set_visited = |v: usize, v_map: &mut [u64]| v_map[v / 64] |= 1 << (v % 64);

    set_visited(0, &mut visited);
    queue.push_back(0u32);

    while let Some(curr) = queue.pop_front() {
        bfs_order.push(curr);
        let start_idx = (curr as usize) * m * 2;
        for i in 0..(m * 2) {
            let neighbor = adj[start_idx + i];
            if neighbor == u32::MAX { break; } // End of neighbors for this node
            
            if !is_visited(neighbor as usize, &visited) {
                set_visited(neighbor as usize, &mut visited);
                queue.push_back(neighbor);
            }
        }
    }

    // --- 3. Host Interaction ---
/*     let total_visited = bfs_order.len();
    
    // use the Rust std io
    let c_str = unsafe { CString::from_raw(output_path_ptr as *mut i8) };
    let output_path = match c_str.into_string() {
        Ok(s) => s,
        Err(_) => return -1,
    };

    match std::fs::File::create(std::path::Path::new(&output_path)) {
        Ok(mut file) => {
            if let Err(_) = file.write_all(total_visited.to_string().as_bytes()) {
                return -1;
            }
        }
        Err(_) => return -1,
    } */
    let total_visited = bfs_order.len();
    total_visited as i32
}

#[no_mangle]
pub extern "C" fn run(input_json: *const i8) -> i32 {
    let input_str = unsafe {
        match CStr::from_ptr(input_json).to_str() {
            Ok(s) => s,
            Err(_) => return -1,
        }
    };

    let input: BfsInput = match serde_json::from_str(input_str) {
        Ok(input) => input,
        Err(_) => return -1,
    };

    let size = input.size.and_then(JsonUsize::into_usize).unwrap_or(100_000);
    let m = input.m.and_then(JsonUsize::into_usize).unwrap_or(10);

    run_bfs_impl(size, m)
}
