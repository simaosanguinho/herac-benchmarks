use serde::Deserialize;
use std::ffi::CStr;

#[derive(Deserialize)]
struct HelloWorldInput {
    name: Option<String>,
}

#[no_mangle]
pub extern "C" fn run(input_json: *const i8) -> i32 {
    let input_str = unsafe {
        match CStr::from_ptr(input_json).to_str() {
            Ok(s) => s,
            Err(_) => return -1,
        }
    };

    let input: HelloWorldInput = match serde_json::from_str(input_str) {
        Ok(input) => input,
        Err(_) => return -1,
    };

    let name = input.name.as_deref().unwrap_or("World");
    println!("Hello {}", name);
    0
}
