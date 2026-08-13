use serde::Deserialize;
use std::ffi::CStr;
use std::fs;

#[derive(Deserialize)]
struct UploaderInput {
    download_url: Option<String>,
    upload_url: Option<String>,
    file_size: Option<usize>,
}

const ERR_INVALID_JSON: u32 = 1;
const ERR_DOWNLOAD: u32 = 2;
const ERR_UPLOAD: u32 = 3;
const SUCCESS: u32 = 5;

fn run_uploader(input: &UploaderInput) -> u32 {
    let download_url = input.download_url.as_deref().unwrap_or("http://127.0.0.1:8000/video.mp4");
    let upload_url = input.upload_url.as_deref().unwrap_or("http://127.0.0.1:9696/upload");
    let _file_size = input.file_size.unwrap_or(2 * 1024 * 1024);

    let data = fs::read(download_url).unwrap_or_default();
    if data.is_empty() {
        eprintln!("Failed to download input.");
        return ERR_DOWNLOAD;
    }

    let filename = download_url.split('/').last().unwrap_or("file.bin");
    let upload_path = format!("upload!{}!{}", upload_url, filename);

    match fs::write(&upload_path, &data) {
        Ok(_) => SUCCESS,
        Err(e) => {
            eprintln!("Failed to upload: {}", e);
            ERR_UPLOAD
        }
    }
}

#[no_mangle]
pub extern "C" fn run(input_json: *const i8) -> u32 {
    let input_str = unsafe {
        match CStr::from_ptr(input_json).to_str() {
            Ok(s) => s,
            Err(_) => return ERR_INVALID_JSON,
        }
    };

    let input: UploaderInput = match serde_json::from_str(input_str) {
        Ok(i) => i,
        Err(_) => return ERR_INVALID_JSON,
    };

    let result = run_uploader(&input);
    if result == SUCCESS {
        println!("Success: Upload completed.");
    } else {
        eprintln!("Error: Upload failed with code {}.", result);
    }

    result
}
