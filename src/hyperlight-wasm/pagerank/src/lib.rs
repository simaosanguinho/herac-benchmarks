use rand::Rng;
use serde::Deserialize;
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
struct PagerankInput {
    size: Option<JsonUsize>,
    m: Option<JsonUsize>,
}

// =====================================================
// PageRank Library Module
// =====================================================
pub fn pagerank(edges: &[u32], pr_slice: &mut [f32], iterations: u32) -> u32 {
    let num_nodes = pr_slice.len();

    // Building CSC Format.
    let mut out_degree = vec![0.0f32; num_nodes];
    let mut in_degree = vec![0_usize; num_nodes];

    // Count degrees.
    for chunk in edges.chunks_exact(2) {
        let u = chunk[0] as usize;
        let v = chunk[1] as usize;
        out_degree[u] += 1.0;
        in_degree[v] += 1;
    }

    // Building offsets array for O(1) flat memory lookups.
    let mut offsets = vec![0_usize; num_nodes + 1];
    for i in 0..num_nodes {
        offsets[i + 1] = offsets[i] + in_degree[i];
    }

    // Populating the flattened incoming edges array.
    let mut in_edges_flat = vec![0_u32; edges.len() / 2];
    let mut current_offset = offsets.clone();

    for chunk in edges.chunks_exact(2) {
        let u = chunk[0] as u32;
        let v = chunk[1] as usize;
        let pos = current_offset[v];
        in_edges_flat[pos] = u;
        current_offset[v] += 1;
    }

    // PageRank init.
    for p in pr_slice.iter_mut() {
        *p = 1.0 / (num_nodes as f32);
    }

    let damping = 0.85;
    let mut next_pr = vec![0.0f32; num_nodes];

    // PageRank loop.
    for _ in 0..iterations {
        let base_pr = (1.0 - damping) / (num_nodes as f32);

        for i in 0..num_nodes {
            let mut sum = 0.0;
            let start = offsets[i];
            let end = offsets[i + 1];

            for j in start..end {
                let in_node = in_edges_flat[j] as usize;
                sum += pr_slice[in_node] / out_degree[in_node];
            }
            next_pr[i] = base_pr + damping * sum;
        }
        pr_slice.copy_from_slice(&next_pr);
    }

    1 // Success.
}

pub fn run_pagerank_impl(size: usize, m: usize, iterations: u32) -> i32 {
    // --- 1. Graph Generation: Barabási-Albert Model ---
    let mut edges = Vec::with_capacity(size * m * 2);
    let mut repeated_nodes = Vec::with_capacity(size * m * 2);

    // Initial clique of m nodes.
    for i in 0..m {
        for j in i + 1..m {
            edges.push(i as u32);
            edges.push(j as u32);
            repeated_nodes.push(i as u32);
            repeated_nodes.push(j as u32);
        }
    }

    // Preferential attachment.
    let mut rng = rand::thread_rng();
    let mut targets = Vec::with_capacity(m);
    for i in m..size {
        targets.clear();
        while targets.len() < m {
            let target = repeated_nodes[rng.gen_range(0..repeated_nodes.len())];
            if !targets.contains(&target) {
                targets.push(target);
            }
        }
        for &target in &targets {
            edges.push(i as u32);
            edges.push(target);
            repeated_nodes.push(i as u32);
            repeated_nodes.push(target);
        }
    }

    // --- 2. PageRank Computation ---
    let mut pr_scores = vec![0.0f32; size];

    let success = pagerank(&edges, &mut pr_scores, iterations);

    if success != 1 {
        eprintln!("PageRank computation failed");
        return -1;
    }

    // --- 3. Return oldest score as i32 (float bits) ---
    let oldest_score = pr_scores[0];

    oldest_score.to_bits() as i32
}

#[no_mangle]
pub extern "C" fn run(input_json: *const i8) -> i32 {
    let input_str = unsafe {
        match CStr::from_ptr(input_json).to_str() {
            Ok(s) => s,
            Err(_) => return -1,
        }
    };

    let input: PagerankInput = match serde_json::from_str(input_str) {
        Ok(input) => input,
        Err(_) => return -1,
    };

    let size = input.size.and_then(JsonUsize::into_usize).unwrap_or(100_000);
    let m = input.m.and_then(JsonUsize::into_usize).unwrap_or(10);
    let iterations = 20;

    run_pagerank_impl(size, m, iterations)
}
