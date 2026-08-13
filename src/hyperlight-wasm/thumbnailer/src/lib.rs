use image::imageops::FilterType;
use serde::Deserialize;
use std::ffi::CStr;
use std::fs;
use std::io::{Cursor};

#[derive(Deserialize)]
struct ThumbnailerInput {
    url: Option<String>,
    target_width: Option<u32>,
    target_height: Option<u32>,
    file_size: Option<usize>,
}

fn resize(in_data: &[u8], w: u32, h: u32) -> Vec<u8> {
    let img = match image::load_from_memory(in_data) {
        Ok(i) => i,
        Err(e) => {
            eprintln!("Failed to decode image: {}", e);
            return Vec::new();
        }
    };

    let resized = img.resize(w, h, FilterType::Lanczos3);

    let mut out_buf = Vec::new();
    match resized.write_to(&mut Cursor::new(&mut out_buf), image::ImageFormat::Jpeg) {
        Ok(_) => out_buf,
        Err(e) => {
            eprintln!("Failed to encode JPEG: {}", e);
            Vec::new()
        }
    }
}

fn run_thumbnailer(input: &ThumbnailerInput) -> i32 {
    let url = input.url.as_deref().unwrap_or("http://127.0.0.1:8000/snap.png");
    let target_width = input.target_width.unwrap_or(200);
    let target_height = input.target_height.unwrap_or(200);
    let _file_size = input.file_size.unwrap_or(1 * 1024 * 1024);

    let img_data = fs::read(url).unwrap_or_default();
    if img_data.is_empty() {
        eprintln!("Failed to download image.");
        return -1;
    }

    let resized_data = resize(&img_data, target_width, target_height);
    if resized_data.is_empty() {
        eprintln!("Failed to resize image.");
        return -1;
    }

/*     if let Ok(mut f) = std::fs::File::create("__write__!/tmp/thumbnail_hlw.jpg") {
        let _ = std::io::Write::write_all(&mut f, &resized_data);
        let _ = f.flush();
    } */
    resized_data.len() as i32
}

#[no_mangle]
pub extern "C" fn run(input_json: *const i8) -> i32 {

    let input_str = unsafe {
        match CStr::from_ptr(input_json).to_str() {
            Ok(s) => s,
            Err(_) => return 1,
        }
    };

    let input: ThumbnailerInput = match serde_json::from_str(input_str) {
        Ok(i) => i,
        Err(_) => return 1,
    };

    let result = run_thumbnailer(&input);
    if result == -1 {
        return 2;
    }

    //println!("{}", result);
    result 
}
