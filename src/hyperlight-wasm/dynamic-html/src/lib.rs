use std::io::Cursor;
use minijinja::{Environment, context};
use chrono::Local;
use rand::Rng;
use serde::Deserialize;
use std::fs;

#[derive(Deserialize)]
struct DynamicHtmlInput {
    url: Option<String>,
    username: Option<String>,
    random_len: Option<usize>,
}

const MAX_TEMPLATE_SIZE: usize = 1 * 1024;
const MAX_HTML_SIZE: usize = 100 * 1024 * 1024;

fn download(url: &str, out_buf: &mut [u8]) -> usize {
    // Use fs::read to load the file/URL. The wasip1.rs WASI handler will
    // intercept paths starting with "http" and download them via HostOpenUrl.
    let data = match fs::read(url) {
        Ok(data) => data,
        Err(e) => {
            eprintln!("Failed to download template: {}", e);
            return 0;
        }
    };

    // Check if the data fits in the output buffer
    if data.len() > out_buf.len() {
        eprintln!("Template data exceeds max buffer size!");
        return 0;
    }

    // Copy data into the output buffer
    out_buf[..data.len()].copy_from_slice(&data);
    data.len()
}

fn render(template_data: &[u8], username: &str, random_numbers: &[u32], out_buf: &mut [u8]) -> usize {
    let template_str = std::str::from_utf8(template_data).unwrap_or("");

    let mut env = Environment::new();
    if env.add_template("tpl", template_str).is_err() {
        eprintln!("Failed to parse template!");
        return 0;
    }
    let tmpl = env.get_template("tpl").unwrap();

    let cur_time = Local::now().format("%Y-%m-%d %H:%M:%S").to_string();

    let mut cursor = Cursor::new(out_buf);

    let res = tmpl.render_captured_to(context! {
        username => username,
        cur_time => cur_time,
        random_numbers => random_numbers,
    }, &mut cursor);

    match res {
        Ok(_) => cursor.position() as usize,
        Err(_) => 0
    }
}

fn render_html(url: &str, username: &str, random_len: usize) -> u32 {
    let mut random_numbers = vec![0u32; random_len];
    let mut rng = rand::thread_rng();
    for n in random_numbers.iter_mut() {
        *n = rng.gen_range(0..1_000);
    }

    let mut template_buf = vec![0u8; MAX_TEMPLATE_SIZE];
    let template_size = download(url, &mut template_buf);

    if template_size == 0 {
        eprintln!("Failed to download template.");
        return 0;
    }

    let mut html_buf = vec![0u8; MAX_HTML_SIZE];
    let html_size = render(
        &template_buf[..template_size],
        username,
        &random_numbers,
        &mut html_buf
    );

    if html_size == 0 {
        eprintln!("Failed to render HTML.");
        return 0;
    }

    html_size as u32
}

#[no_mangle]
pub extern "C" fn run(input_json_ptr: *const u8) -> i32 {
    if input_json_ptr.is_null() {
        return -10;
    }

    let input_json = unsafe {
        std::ffi::CStr::from_ptr(input_json_ptr as *const std::os::raw::c_char)
            .to_str()
            .unwrap_or("")
    };

    let input: DynamicHtmlInput = match serde_json::from_str(input_json) {
        Ok(val) => val,
        Err(_) => return -1,
    };

    let url = input.url.as_deref().unwrap_or("http://127.0.0.1:8000/template.html");
    let username = input.username.as_deref().unwrap_or("username");
    let random_len = input.random_len.unwrap_or(1_000_000);

    let html_size = render_html(url, username, random_len);

    if html_size > 0 {
        html_size as i32
    } else {
        -2
    }
}
