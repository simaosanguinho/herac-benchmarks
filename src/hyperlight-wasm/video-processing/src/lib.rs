use serde::Deserialize;
use std::ffi::CStr;
use std::fs;

mod transcode;

#[derive(Deserialize)]
struct VideoProcessingInput {
    video_url: Option<String>,
    watermark_url: Option<String>,
}

const ERR_INVALID_JSON: u32 = 1;
const ERR_DOWNLOAD: u32 = 2;
const ERR_TRANSCODE: u32 = 3;

fn process_video(video_url: &str, watermark_url: &str) -> u32 {
    let video_data = fs::read(video_url).unwrap_or_default();
    if video_data.is_empty() {
        eprintln!("Failed to download video.");
        return ERR_DOWNLOAD;
    }

    let watermark_data = fs::read(watermark_url).unwrap_or_default();
    if watermark_data.is_empty() {
        eprintln!("Failed to download watermark.");
        return ERR_DOWNLOAD;
    }

    // eprintln!("downloaded video {} bytes, watermark {} bytes", video_data.len(), watermark_data.len());

    let (gif_bytes, mp4_bytes) = match transcode::process(&video_data, &watermark_data) {
        Ok(out) => out,
        Err(e) => {
            eprintln!("Transcode failed: {}", e);
            return ERR_TRANSCODE;
        }
    };

    if fs::write("__write__!/tmp/processed.gif", &gif_bytes).is_err() {
        eprintln!("Failed to write processed.gif.");
        return ERR_TRANSCODE;
    }

    if fs::write("__write__!/tmp/watermarked.mp4", &mp4_bytes).is_err() {
        eprintln!("Failed to write watermarked.mp4.");
        return ERR_TRANSCODE;
    }

    //eprintln!("wrote processed.gif ({} bytes) and watermarked.mp4 ({} bytes)", gif_bytes.len(), mp4_bytes.len());
    0
}

#[no_mangle]
pub extern "C" fn run(input_json: *const i8) -> u32 {
    let input_str = unsafe {
        match CStr::from_ptr(input_json).to_str() {
            Ok(s) => s,
            Err(_) => return ERR_INVALID_JSON,
        }
    };

    let input: VideoProcessingInput = match serde_json::from_str(input_str) {
        Ok(i) => i,
        Err(_) => return ERR_INVALID_JSON,
    };

    let video_url = input.video_url.as_deref().unwrap_or("http://127.0.0.1:8000/video.mp4");
    let watermark_url = input.watermark_url.as_deref().unwrap_or("http://127.0.0.1:8000/watermark.jpg");

    process_video(video_url, watermark_url)
}
