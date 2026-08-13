use serde::{Deserialize, Serialize};
use std::ffi::CStr;
use std::io::Cursor;
use std::fs;

#[derive(Deserialize)]
struct DnaInput {
    url: Option<String>,
}

#[derive(Serialize)]
struct SquiggleOutput {
    x: Vec<f64>,
    y: Vec<f64>,
}

// --- Business Logic: Full squiggle 2D coordinate transform ---
fn squiggle_transform(fasta_data: &[u8], out_buf: &mut [u8]) -> usize {
    let fasta_str = std::str::from_utf8(fasta_data).unwrap_or("");

    let estimated_capacity = fasta_str.len() * 2;
    let mut x_coords = Vec::with_capacity(estimated_capacity);
    let mut y_coords = Vec::with_capacity(estimated_capacity);

    let mut cur_x = 0.0;
    let mut cur_y = 0.0;

    x_coords.push(cur_x);
    y_coords.push(cur_y);

    for line in fasta_str.lines() {
        if line.starts_with('>') { continue; }
        for b in line.bytes() {
            match b {
                b'A' | b'a' => {
                    x_coords.push(cur_x + 0.5); y_coords.push(cur_y + 0.5);
                    cur_x += 1.0;
                    x_coords.push(cur_x);       y_coords.push(cur_y);
                }
                b'C' | b'c' => {
                    x_coords.push(cur_x + 0.5); y_coords.push(cur_y - 0.5);
                    cur_x += 1.0;
                    x_coords.push(cur_x);       y_coords.push(cur_y);
                }
                b'G' | b'g' => {
                    x_coords.push(cur_x + 0.5); y_coords.push(cur_y + 0.5);
                    cur_x += 1.0;               cur_y += 1.0;
                    x_coords.push(cur_x);       y_coords.push(cur_y);
                }
                b'T' | b't' | b'U' | b'u' => {
                    x_coords.push(cur_x + 0.5); y_coords.push(cur_y - 0.5);
                    cur_x += 1.0;               cur_y -= 1.0;
                    x_coords.push(cur_x);       y_coords.push(cur_y);
                }
                _ => {}
            }
        }
    }

    let result = SquiggleOutput { x: x_coords, y: y_coords };
    let mut cursor = Cursor::new(out_buf);
    match serde_json::to_writer(&mut cursor, &result) {
        Ok(_) => cursor.position() as usize,
        Err(_) => 0,
    }
}

const MAX_JSON_SIZE: usize = 158 * 1024 * 1024;

// --- Error codes ---
const ERR_INVALID_JSON_INPUT: u32 = 2;
const ERR_FILE_READ: u32 = 3;
const ERR_TRANSFORM: u32 = 4;

// --- Main Handler ---
#[no_mangle]
pub extern "C" fn run(input_json: *const i8) -> u32 {
    let input_str = unsafe {
        CStr::from_ptr(input_json).to_str().unwrap_or("")
    };

    let input: DnaInput = match serde_json::from_str(input_str) {
        Ok(i) => i,
        Err(_) => return ERR_INVALID_JSON_INPUT,
    };

    let file_path = match input.url {
        Some(path) => path,
        None => return ERR_INVALID_JSON_INPUT,
    };

    let file_data = match fs::read(&file_path) {
        Ok(data) => data,
        Err(_) => return ERR_FILE_READ,
    };

    let mut json_buf = vec![0u8; MAX_JSON_SIZE];
    let bytes_written = squiggle_transform(&file_data, &mut json_buf);

    if bytes_written == 0 {
        return ERR_TRANSFORM;
    }

    bytes_written as u32
}