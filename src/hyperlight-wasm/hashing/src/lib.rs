use serde::Deserialize;
use sha2::{Digest, Sha256};
use std::ffi::CStr;
use std::fs::File;
use std::io::Read;

#[derive(Deserialize)]
struct HashingInput {
    url: Option<String>,
}

#[no_mangle]
pub extern "C" fn run(input_json: *const i8) -> i32 {
    let input_str = unsafe {
        match CStr::from_ptr(input_json).to_str() {
            Ok(s) => s,
            Err(_) => return -1,
        }
    };

    let input: HashingInput = match serde_json::from_str(input_str) {
        Ok(input) => input,
        Err(_) => return -1,
    };

    let url_str = input.url.as_deref().unwrap_or("http://127.0.0.1:8000/snap.png");

    let mut file = match File::open(url_str) {
        Ok(f) => f,
        Err(_) => return -1,
    };

    let mut image_data = Vec::new();
    if file.read_to_end(&mut image_data).is_err() {
        return -2;
    }

    // 2. Hash the data
    let mut hasher = Sha256::new();
    hasher.update(&image_data);
    let hash_hex = format!("{:x}", hasher.finalize());

    

    hash_hex.len() as i32
}
