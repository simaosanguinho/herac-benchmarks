use petgraph::algo::min_spanning_tree;
use petgraph::data::Element;
use petgraph::graph::UnGraph;
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

#[allow(dead_code)]
#[derive(Deserialize)]
struct MstInput {
    size: Option<JsonUsize>,
    m: Option<JsonUsize>,
}


fn mst(edges: &[u32], out_edges: &mut [u32], num_nodes: usize) -> u32 {
    let mut graph = UnGraph::<(), ()>::with_capacity(num_nodes, edges.len() / 2);
    let mut nodes = Vec::with_capacity(num_nodes);

    for _ in 0..num_nodes {
        nodes.push(graph.add_node(()));
    }

    for chunk in edges.chunks_exact(2) {
        let u = chunk[0] as usize;
        let v = chunk[1] as usize;
        graph.add_edge(nodes[u], nodes[v], ());
    }

    let mst_result = min_spanning_tree(&graph);
    let mut mst_edge_count = 0;

    for element in mst_result {
        if let Element::Edge { source, target, .. } = element {
            // Write pairs (source, target) into the flat output array.
            if (mst_edge_count * 2) + 1 < out_edges.len() {
                out_edges[mst_edge_count * 2] = source as u32;
                out_edges[mst_edge_count * 2 + 1] = target as u32;
                mst_edge_count += 1;
            }
        }
    }

    mst_edge_count as u32
}

pub fn run_mst_impl(size: usize, m: usize) -> u32 {
    // Creating the Barabási-Albert graph.
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

    // MST execution.
    // A spanning tree on N nodes will have exactly N-1 edges.
    let max_mst_edges = size - 1;
    let mut mst_edges_out = vec![0u32; max_mst_edges * 2];

    let edges_in_tree = mst(&edges, &mut mst_edges_out, size);

    if edges_in_tree != max_mst_edges as u32 {
        eprintln!(
            "MST failed or incomplete! Expected {}, got {}",
            max_mst_edges, edges_in_tree
        );
    }

    edges_in_tree
}

#[no_mangle]
pub extern "C" fn run(input_json: *const i8) -> i32 {
    let input_str = unsafe {
        match CStr::from_ptr(input_json).to_str() {
            Ok(s) => s,
            Err(_) => return -1,
        }
    };

    let input: MstInput = match serde_json::from_str(input_str) {
        Ok(input) => input,
        Err(_) => return -1,
    };

    let size = input.size.and_then(JsonUsize::into_usize).unwrap_or(100_000);
    let m = input.m.and_then(JsonUsize::into_usize).unwrap_or(10);

    run_mst_impl(size, m) as i32
}
