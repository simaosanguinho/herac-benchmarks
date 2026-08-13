use serde::Deserialize;
use std::ffi::CStr;
use std::fs;
use std::io::Cursor;
use image::imageops::FilterType;
use tract_onnx::prelude::*;

#[derive(Deserialize)]
struct ClassifyInput {
    model_url: Option<String>,
    image_url: Option<String>,
    labels_url: Option<String>,
}


const ERR_INVALID_JSON: u32 = 1;
const ERR_INFER: u32 = 2;


fn infer(model_slice: &[u8], img_slice: &[u8]) -> u32 {
    let mut cursor = Cursor::new(model_slice);

    let model = match tract_onnx::onnx()
        .model_for_read(&mut cursor).unwrap()
        .into_optimized().unwrap()
        .into_runnable()
    {
        Ok(m) => m,
        Err(e) => {
            eprintln!("Model load failed: {:?}", e);
            return 0;
        }
    };

    let img = match image::load_from_memory(img_slice) {
        Ok(i) => i.to_rgb8(),
        Err(_) => return 0,
    };

    let resized = image::imageops::resize(&img, 256, 256, FilterType::Triangle);
    let crop_x = (256 - 224) / 2;
    let crop_y = (256 - 224) / 2;
    let cropped = image::imageops::crop_imm(&resized, crop_x, crop_y, 224, 224).to_image();

    let mut tensor = tract_ndarray::Array4::<f32>::zeros((1, 3, 224, 224));
    let mean = [0.485, 0.456, 0.406];
    let std = [0.229, 0.224, 0.225];

    for (x, y, pixel) in cropped.enumerate_pixels() {
        for c in 0..3 {
            tensor[[0, c, y as usize, x as usize]] = (pixel[c] as f32 / 255.0 - mean[c]) / std[c];
        }
    }

    let tract_tensor = tensor.into_tensor();
    let result = model.run(tvec!(tract_tensor.into())).unwrap();
    let logits = result[0].to_array_view::<f32>().unwrap();

    let mut max_idx = 0;
    let mut max_val = logits[[0, 0]];

    for i in 0..1000 {
        let val = logits[[0, i]];
        if val > max_val {
            max_val = val;
            max_idx = i;
        }
    }

    max_idx as u32
}

fn run_classify(input: &ClassifyInput) -> String {
    let model_url = input.model_url.as_deref().unwrap_or("http://127.0.0.1:8000/resnet50.onnx");
    let image_url = input.image_url.as_deref().unwrap_or("http://127.0.0.1:8000/eagle.jpg");
    let labels_url = input.labels_url.as_deref().unwrap_or("http://127.0.0.1:8000/resnet_labels.txt");
    
    //println!("DEBUG: Starting classification via WASI proxies...");

    // Directly read from the URLs! Your host path_open interceptor triggers 
    // when it catches the "http" prefix and handles the downloading automatically.
    // println!("DEBUG: Requesting model data via host file proxy...");
    let model_data = fs::read(model_url).unwrap_or_default();
    if model_data.is_empty() { 
        println!("DEBUG: Error - Model data streaming returned empty!");
        return String::new(); 
    }

    // println!("DEBUG: Requesting labels via host file proxy...");
    let labels_data = fs::read(labels_url).unwrap_or_default();
    if labels_data.is_empty() { 
        println!("DEBUG: Error - Labels streaming returned empty!");
        return String::new(); 
    }

    // println!("DEBUG: Requesting target image via host file proxy...");
    let img_data = fs::read(image_url).unwrap_or_default();
    if img_data.is_empty() { 
        println!("DEBUG: Error - Image streaming returned empty!");
        return String::new(); 
    }

    // println!("DEBUG: Starting model inference block...");
    let class_idx = infer(&model_data, &img_data);
    
    // Note: If index 0 is returned cleanly, we treat it as valid instead of failing.
    let labels_str = std::str::from_utf8(&labels_data).unwrap_or("");
    let matched_label = labels_str.lines().nth(class_idx as usize).unwrap_or("Unknown").to_string();
    // println!("DEBUG: Successfully matched index {}: {}", class_idx, matched_label);
    
    matched_label
}

#[no_mangle]
pub extern "C" fn run(input_json: *const i8) -> u32 {
    let input_str = unsafe {
        match CStr::from_ptr(input_json).to_str() {
            Ok(s) => s,
            Err(_) => return ERR_INVALID_JSON,
        }
    };

    let input: ClassifyInput = match serde_json::from_str(input_str) {
        Ok(i) => i,
        Err(_) => return ERR_INVALID_JSON,
    };

    let class_name = run_classify(&input);
    println!("Classified image as: {}", class_name);
    if class_name.is_empty() {
        return ERR_INFER;
    }


    // return number of bytes written to output buffer 
    let bytes_written = class_name.len() as u32;
    bytes_written
}