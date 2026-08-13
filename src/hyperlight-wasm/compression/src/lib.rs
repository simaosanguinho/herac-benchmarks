use serde::Deserialize;
use std::ffi::CStr;
use std::fs;

#[derive(Deserialize)]
struct CompressionInput {
    input_url: Option<String>,
    input_size: Option<usize>,
}

const ERR_INVALID_JSON: u32 = 1;
//const ERR_DOWNLOAD: u32 = 2;
const ERR_COMPRESS: u32 = 3;

fn compress(data: &[u8], out_buf: &mut [u8]) -> usize {
    match zstd::bulk::compress_to_buffer(data, out_buf, 9) {
        Ok(size) => size,
        Err(_) => 0,
    }
}

fn run_compression(input_url: &str, input_size: usize) -> u32 {
    let data = fs::read(input_url).unwrap_or_default();
    if data.is_empty() {
        eprintln!("Failed to download input.");
        return 0;
    }

    let mut compressed_buf = vec![0u8; input_size];
    let compressed_size = compress(&data, &mut compressed_buf);

    if compressed_size == 0 {
        eprintln!("Failed to compress input.");
    }

    compressed_size as u32
}

#[no_mangle]
pub extern "C" fn run(input_json: *const i8) -> u32 {
    let input_str = unsafe {
        match CStr::from_ptr(input_json).to_str() {
            Ok(s) => s,
            Err(_) => return ERR_INVALID_JSON,
        }
    };

    let input: CompressionInput = match serde_json::from_str(input_str) {
        Ok(i) => i,
        Err(_) => return ERR_INVALID_JSON,
    };

    let input_url = input.input_url.as_deref().unwrap_or("http://127.0.0.1:8000/video.mp4");
    let input_size = input.input_size.unwrap_or(2 * 1024 * 1024);

    let compressed_size = run_compression(input_url, input_size);

    if compressed_size == 0 {
        eprintln!("Compression failed");
        return ERR_COMPRESS;
    }

    let output = format!("Success: Compressed input file to {} bytes.", compressed_size);
    println!("{}", output);
    compressed_size
}
