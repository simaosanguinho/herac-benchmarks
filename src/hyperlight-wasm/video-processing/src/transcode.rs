use std::ffi::{CStr, CString};
use std::os::raw::{c_int, c_uint, c_void};
use std::ptr;

use ffmpeg_wasi::avcodec as ac;
use ffmpeg_wasi::avformat as af;
use ffmpeg_wasi::avutil as au;
use ffmpeg_wasi::swscale as sw;

const PIX_YUV420P: c_int = 0;
const PIX_RGB24: c_int = 2;
const PIX_PAL8: c_int = 11;
const PIX_RGBA: c_int = 26;

const CODEC_MJPEG: c_uint = 7;
const CODEC_MPEG4: c_uint = 12;
const CODEC_GIF: c_uint = 97;

const AVERROR_EAGAIN: c_int = -6; // -(WASI_EAGAIN=6), not Linux EAGAIN=11
const AVERROR_EOF: c_int = -541478725;
const AV_INPUT_BUFFER_PADDING_SIZE: usize = 64;
const AVFMT_FLAG_CUSTOM_IO: c_int = 128;
const AV_CODEC_FLAG_GLOBAL_HEADER: c_int = 4194304;

const GIF_WIDTH: c_int = 320;
const GIF_FPS: i64 = 10;
const SEGMENT_SECONDS: i64 = 5;
const MAX_GIF_FRAMES: usize = 50;

fn err_str(code: c_int) -> String {
    unsafe {
        let mut buf = [0i8; 256];
        au::av_strerror(code, buf.as_mut_ptr(), buf.len());
        if buf[0] == 0 {
            format!("error {}", code)
        } else {
            CStr::from_ptr(buf.as_ptr()).to_string_lossy().into_owned()
        }
    }
}

// ---------------------------------------------------------------------------
// In-memory AVIO plumbing
// ---------------------------------------------------------------------------

struct MemInput {
    data: *const u8,
    len: usize,
    pos: usize,
}

unsafe extern "C" fn mem_read(opaque: *mut c_void, buf: *mut u8, buf_size: c_int) -> c_int {
    let mi = &mut *(opaque as *mut MemInput);
    let avail = mi.len.saturating_sub(mi.pos);
    let n = avail.min(buf_size as usize);
    if n > 0 {
        ptr::copy_nonoverlapping(mi.data.add(mi.pos), buf, n);
        mi.pos += n;
    }
    n as c_int
}

unsafe extern "C" fn mem_seek(opaque: *mut c_void, offset: i64, whence: c_int) -> i64 {
    const SEEK_SET: i64 = 0;
    const SEEK_CUR: i64 = 1;
    const SEEK_END: i64 = 2;
    const AVSEEK_SIZE: i64 = 0x10000;
    let mi = &mut *(opaque as *mut MemInput);
    match whence as i64 {
        AVSEEK_SIZE => mi.len as i64,
        SEEK_SET => {
            if offset < 0 {
                return -1;
            }
            mi.pos = offset as usize;
            mi.pos as i64
        }
        SEEK_CUR => {
            let np = mi.pos as i64 + offset;
            if np < 0 {
                return -1;
            }
            mi.pos = np as usize;
            mi.pos as i64
        }
        SEEK_END => {
            let np = mi.len as i64 + offset;
            if np < 0 {
                return -1;
            }
            mi.pos = np as usize;
            mi.pos as i64
        }
        _ => -1,
    }
}

struct MemOutput {
    data: Vec<u8>,
    pos: usize,
}

unsafe extern "C" fn mem_write(opaque: *mut c_void, buf: *const u8, buf_size: c_int) -> c_int {
    let out = &mut *(opaque as *mut MemOutput);
    let n = buf_size as usize;
    if out.pos + n > out.data.len() {
        out.data.resize(out.pos + n, 0);
    }
    ptr::copy_nonoverlapping(buf, out.data.as_mut_ptr().add(out.pos), n);
    out.pos += n;
    buf_size
}

unsafe extern "C" fn mem_seek_out(opaque: *mut c_void, offset: i64, whence: c_int) -> i64 {
    const SEEK_SET: i64 = 0;
    const SEEK_CUR: i64 = 1;
    const SEEK_END: i64 = 2;
    const AVSEEK_SIZE: i64 = 0x10000;
    let out = &mut *(opaque as *mut MemOutput);
    match whence as i64 {
        AVSEEK_SIZE => out.data.len() as i64,
        SEEK_SET => {
            if offset < 0 {
                return -1;
            }
            out.pos = offset as usize;
            out.pos as i64
        }
        SEEK_CUR => {
            let np = out.pos as i64 + offset;
            if np < 0 {
                return -1;
            }
            out.pos = np as usize;
            out.pos as i64
        }
        SEEK_END => {
            let np = out.data.len() as i64 + offset;
            if np < 0 {
                return -1;
            }
            out.pos = np as usize;
            out.pos as i64
        }
        _ => -1,
    }
}

unsafe fn open_input(data: &[u8]) -> Result<(Box<MemInput>, *mut u8, *mut af::AVIOContext, *mut af::AVFormatContext), String> {
    let mi = Box::new(MemInput { data: data.as_ptr(), len: data.len(), pos: 0 });
    let opaque = (&*mi as *const MemInput) as *mut c_void;
    let buf = au::av_malloc(65536) as *mut u8;
    if buf.is_null() {
        return Err("av_malloc failed".into());
    }
    let avio = af::avio_alloc_context(buf, 65536, 0, opaque, Some(mem_read), None, Some(mem_seek));
    if avio.is_null() {
        au::av_free(buf as *mut c_void);
        return Err("avio_alloc_context failed".into());
    }
    let mut fc = af::avformat_alloc_context();
    if fc.is_null() {
        return Err("avformat_alloc_context failed".into());
    }
    (*fc).pb = avio;
    (*fc).flags = (*fc).flags | AVFMT_FLAG_CUSTOM_IO;
    let r = af::avformat_open_input(&mut fc, ptr::null(), ptr::null(), ptr::null_mut());
    if r < 0 {
        return Err(format!("avformat_open_input: {}", err_str(r)));
    }
    let r = af::avformat_find_stream_info(fc, ptr::null_mut());
    if r < 0 {
        return Err(format!("avformat_find_stream_info: {}", err_str(r)));
    }
    Ok((mi, buf, avio, fc))
}

unsafe fn open_output(
    out: &mut MemOutput,
    format_name: &str,
    buf_size: c_int,
) -> Result<(*mut af::AVIOContext, *mut u8, *mut af::AVFormatContext), String> {
    let opaque = out as *mut MemOutput as *mut c_void;
    let buf = au::av_malloc(buf_size as usize) as *mut u8;
    if buf.is_null() {
        return Err("av_malloc failed".into());
    }
    let avio =
        af::avio_alloc_context(buf, buf_size, 1, opaque, None, Some(mem_write), Some(mem_seek_out));
    if avio.is_null() {
        au::av_free(buf as *mut c_void);
        return Err("avio_alloc_context(write) failed".into());
    }
    let name = CString::new(format_name).map_err(|_| "bad format name".to_string())?;
    let mut oc: *mut af::AVFormatContext = ptr::null_mut();
    let r = af::avformat_alloc_output_context2(&mut oc, ptr::null(), name.as_ptr(), ptr::null());
    if r < 0 || oc.is_null() {
        return Err("avformat_alloc_output_context2 failed".into());
    }
    (*oc).pb = avio;
    (*oc).flags = (*oc).flags | AVFMT_FLAG_CUSTOM_IO;
    Ok((avio, buf, oc))
}

// ---------------------------------------------------------------------------
// Encoder + muxer sink
// ---------------------------------------------------------------------------

struct Muxer {
    enc: *mut ac::AVCodecContext,
    oc: *mut af::AVFormatContext,
    stream_idx: c_int,
    avio: *mut af::AVIOContext,
    avio_buf: *mut u8,
    pkt: *mut ac::AVPacket,
    out: Box<MemOutput>,
    interleave: bool,
}

impl Muxer {
    unsafe fn write_pkt(&mut self) -> Result<(), String> {
        (*self.pkt).stream_index = self.stream_idx;
        let wr = if self.interleave {
            af::av_interleaved_write_frame(self.oc, self.pkt as *mut af::AVPacket)
        } else {
            af::av_write_frame(self.oc, self.pkt as *mut af::AVPacket)
        };
        if wr < 0 {
            return Err(format!("av_write_frame: {}", err_str(wr)));
        }
        if !self.interleave {
            ac::av_packet_unref(self.pkt);
        }
        Ok(())
    }

    unsafe fn drain(&mut self) -> Result<(), String> {
        loop {
            let r = ac::avcodec_receive_packet(self.enc, self.pkt);
            if r == AVERROR_EAGAIN || r == AVERROR_EOF {
                break;
            }
            if r < 0 {
                return Err(format!("avcodec_receive_packet: {}", err_str(r)));
            }
            self.write_pkt()?;
        }
        Ok(())
    }

    unsafe fn send_frame(&mut self, frame: *const ac::AVFrame) -> Result<(), String> {
        loop {
            let r = ac::avcodec_send_frame(self.enc, frame);
            if r == 0 {
                break;
            }
            if r == AVERROR_EAGAIN {
                self.drain()?;
                continue;
            }
            return Err(format!("avcodec_send_frame: {}", err_str(r)));
        }
        self.drain()
    }

    unsafe fn flush(&mut self) -> Result<(), String> {
        let r = ac::avcodec_send_frame(self.enc, ptr::null());
        if r != 0 && r != AVERROR_EOF && r != AVERROR_EAGAIN {
            return Err(format!("avcodec_send_frame(NULL): {}", err_str(r)));
        }
        self.drain()
    }

    unsafe fn cleanup(&mut self) {
        ac::avcodec_free_context(&mut self.enc);
        af::avformat_free_context(self.oc);
        af::avio_context_free(&mut self.avio);
        if !self.avio_buf.is_null() {
            au::av_free(self.avio_buf as *mut c_void);
        }
        ac::av_packet_free(&mut self.pkt);
    }

    unsafe fn finish(mut self) -> Result<Vec<u8>, String> {
        self.flush()?;
        let r = af::av_write_trailer(self.oc);
        if r < 0 {
            return Err(format!("av_write_trailer: {}", err_str(r)));
        }
        af::avio_flush(self.avio);
        self.cleanup();
        let mut out = *self.out;
        out.data.truncate(out.pos);
        Ok(out.data)
    }
}

unsafe fn setup_mpeg4_muxer(vw: c_int, vh: c_int, fps: i64) -> Result<Muxer, String> {
    let codec = ac::avcodec_find_encoder(CODEC_MPEG4);
    if codec.is_null() {
        return Err("mpeg4 encoder not found".into());
    }
    let enc = ac::avcodec_alloc_context3(codec);
    if enc.is_null() {
        return Err("avcodec_alloc_context3 failed".into());
    }
    (*enc).width = vw;
    (*enc).height = vh;
    (*enc).time_base = ac::AVRational { num: 1, den: fps as c_int };
    (*enc).framerate = ac::AVRational { num: fps as c_int, den: 1 };
    (*enc).pix_fmt = PIX_YUV420P;
    (*enc).bit_rate = 2_000_000;
    (*enc).gop_size = 12;
    (*enc).max_b_frames = 0;
    (*enc).flags = (*enc).flags | AV_CODEC_FLAG_GLOBAL_HEADER;
    let r = ac::avcodec_open2(enc, codec, ptr::null_mut());
    if r < 0 {
        return Err(format!("avcodec_open2(mpeg4): {}", err_str(r)));
    }

    let mut out = Box::new(MemOutput { data: Vec::new(), pos: 0 });
    let (avio, avio_buf, oc) = open_output(&mut out, "mp4", 65536)?;
    let st = af::avformat_new_stream(oc, ptr::null());
    if st.is_null() {
        return Err("avformat_new_stream failed".into());
    }
    (*st).time_base = af::AVRational { num: 1, den: fps as c_int };
    let r = ac::avcodec_parameters_from_context((*st).codecpar as *mut ac::AVCodecParameters, enc);
    if r < 0 {
        return Err(format!("avcodec_parameters_from_context: {}", err_str(r)));
    }
    let r = af::avformat_write_header(oc, ptr::null_mut());
    if r < 0 {
        return Err(format!("avformat_write_header(mp4): {}", err_str(r)));
    }
    Ok(Muxer {
        enc,
        oc,
        stream_idx: (*st).index,
        avio,
        avio_buf,
        pkt: ac::av_packet_alloc(),
        out,
        interleave: true,
    })
}

unsafe fn setup_gif_muxer(gw: c_int, gh: c_int, palette: &[[u8; 4]]) -> Result<Muxer, String> {
    let codec = ac::avcodec_find_encoder(CODEC_GIF);
    if codec.is_null() {
        return Err("gif encoder not found".into());
    }
    let enc = ac::avcodec_alloc_context3(codec);
    if enc.is_null() {
        return Err("avcodec_alloc_context3 failed".into());
    }
    (*enc).width = gw;
    (*enc).height = gh;
    (*enc).time_base = ac::AVRational { num: 1, den: GIF_FPS as c_int };
    (*enc).framerate = ac::AVRational { num: GIF_FPS as c_int, den: 1 };
    (*enc).pix_fmt = PIX_PAL8;
    let r = ac::avcodec_open2(enc, codec, ptr::null_mut());
    if r < 0 {
        return Err(format!("avcodec_open2(gif): {}", err_str(r)));
    }

    let mut out = Box::new(MemOutput { data: Vec::new(), pos: 0 });
    let (avio, avio_buf, oc) = open_output(&mut out, "gif", 65536)?;
    let st = af::avformat_new_stream(oc, ptr::null());
    if st.is_null() {
        return Err("avformat_new_stream failed".into());
    }
    (*st).time_base = af::AVRational { num: 1, den: GIF_FPS as c_int };
    let r = ac::avcodec_parameters_from_context((*st).codecpar as *mut ac::AVCodecParameters, enc);
    if r < 0 {
        return Err(format!("avcodec_parameters_from_context: {}", err_str(r)));
    }
    let ext = au::av_malloc(1024) as *mut u8;
    if ext.is_null() {
        return Err("av_malloc failed".into());
    }
    for (i, p) in palette.iter().enumerate() {
        let o = i * 4;
        *ext.add(o) = p[0];
        *ext.add(o + 1) = p[1];
        *ext.add(o + 2) = p[2];
        *ext.add(o + 3) = p[3];
    }
    (*(*st).codecpar).extradata = ext;
    (*(*st).codecpar).extradata_size = 1024;
    let r = af::avformat_write_header(oc, ptr::null_mut());
    if r < 0 {
        return Err(format!("avformat_write_header(gif): {}", err_str(r)));
    }
    Ok(Muxer {
        enc,
        oc,
        stream_idx: (*st).index,
        avio,
        avio_buf,
        pkt: ac::av_packet_alloc(),
        out,
        interleave: false,
    })
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

unsafe fn setup_decoder(fc: *mut af::AVFormatContext) -> Result<(*mut af::AVStream, *mut ac::AVCodecContext, c_int), String> {
    let mut decoder: *const af::AVCodec = ptr::null();
    let idx = af::av_find_best_stream(fc, af::AVMediaType_AVMEDIA_TYPE_VIDEO, -1, -1, &mut decoder, 0);
    if idx < 0 {
        return Err(format!("no video stream: {}", err_str(idx)));
    }
    let codec = decoder as *const ac::AVCodec;
    if codec.is_null() {
        return Err("no decoder found".into());
    }
    let st = *(*fc).streams.offset(idx as isize);
    let dec = ac::avcodec_alloc_context3(codec);
    if dec.is_null() {
        return Err("avcodec_alloc_context3 failed".into());
    }
    let r = ac::avcodec_parameters_to_context(dec, (*st).codecpar as *const ac::AVCodecParameters);
    if r < 0 {
        return Err(format!("avcodec_parameters_to_context: {}", err_str(r)));
    }
    let r = ac::avcodec_open2(dec, codec, ptr::null_mut());
    if r < 0 {
        return Err(format!("avcodec_open2(decoder): {}", err_str(r)));
    }
    Ok((st, dec, idx))
}

unsafe fn alloc_frame(w: c_int, h: c_int, fmt: c_int) -> Result<*mut ac::AVFrame, String> {
    let mut f = ac::av_frame_alloc();
    if f.is_null() {
        return Err("av_frame_alloc failed".into());
    }
    (*f).width = w;
    (*f).height = h;
    (*f).format = fmt;
    let r = ac::av_frame_get_buffer(f, 1);
    if r < 0 {
        ac::av_frame_free(&mut f);
        return Err(format!("av_frame_get_buffer: {}", err_str(r)));
    }
    Ok(f)
}

unsafe fn decode_jpeg_rgba(jpeg: &[u8]) -> Result<(Vec<u8>, c_int, c_int), String> {
    let codec = ac::avcodec_find_decoder(CODEC_MJPEG);
    if codec.is_null() {
        return Err("mjpeg decoder not found".into());
    }
    let mut ctx = ac::avcodec_alloc_context3(codec);
    if ctx.is_null() {
        return Err("avcodec_alloc_context3 failed".into());
    }
    let r = ac::avcodec_open2(ctx, codec, ptr::null_mut());
    if r < 0 {
        return Err(format!("avcodec_open2(mjpeg): {}", err_str(r)));
    }
    let padded = au::av_mallocz(jpeg.len() + AV_INPUT_BUFFER_PADDING_SIZE) as *mut u8;
    if padded.is_null() {
        return Err("av_mallocz failed".into());
    }
    ptr::copy_nonoverlapping(jpeg.as_ptr(), padded, jpeg.len());
    let mut pkt = ac::av_packet_alloc();
    (*pkt).data = padded;
    (*pkt).size = jpeg.len() as c_int;
    let mut frame = ac::av_frame_alloc();
    if frame.is_null() {
        return Err("av_frame_alloc failed".into());
    }
    let sr = ac::avcodec_send_packet(ctx, pkt);
    if sr < 0 {
        return Err(format!("send_packet(mjpeg): {}", err_str(sr)));
    }
    let rr = ac::avcodec_receive_frame(ctx, frame);
    if rr < 0 {
        return Err(format!("receive_frame(mjpeg): {}", err_str(rr)));
    }
    let w = (*frame).width;
    let h = (*frame).height;
    if w <= 0 || h <= 0 {
        return Err("bad watermark dims".into());
    }
    let sws_c = sw::sws_getContext(
        w,
        h,
        (*frame).format,
        w,
        h,
        PIX_RGBA,
        sw::SWS_BILINEAR as c_int,
        ptr::null_mut(),
        ptr::null_mut(),
        ptr::null(),
    );
    if sws_c.is_null() {
        return Err("sws_getContext(wm) failed".into());
    }
    let mut rgba = ac::av_frame_alloc();
    (*rgba).width = w;
    (*rgba).height = h;
    (*rgba).format = PIX_RGBA;
    let fr = ac::av_frame_get_buffer(rgba, 1);
    if fr < 0 {
        return Err(format!("av_frame_get_buffer(wm): {}", err_str(fr)));
    }
    sw::sws_scale(
        sws_c,
        (*frame).data.as_ptr() as *const *const u8,
        (*frame).linesize.as_ptr(),
        0,
        h,
        (*rgba).data.as_ptr() as *const *mut u8,
        (*rgba).linesize.as_ptr(),
    );
    let ls = (*rgba).linesize[0] as usize;
    let mut vec = vec![0u8; (w as usize) * (h as usize) * 4];
    for y in 0..h as usize {
        ptr::copy_nonoverlapping((*rgba).data[0].add(y * ls), vec.as_mut_ptr().add(y * (w as usize) * 4), (w as usize) * 4);
    }
    sw::sws_freeContext(sws_c);
    ac::av_frame_free(&mut frame);
    ac::av_frame_free(&mut rgba);
    ac::av_packet_free(&mut pkt);
    au::av_free(padded as *mut c_void);
    ac::avcodec_free_context(&mut ctx);
    Ok((vec, w, h))
}

unsafe fn blend_into_frame(
    dst: *mut u8,
    ls: c_int,
    dw: usize,
    dh: usize,
    wm: &[u8],
    wmw: usize,
    wmh: usize,
) {
    if wmw == 0 || wmh == 0 {
        return;
    }
    let ox = dw.saturating_sub(wmw) / 2;
    let oy = dh.saturating_sub(wmh) / 2;
    let ls = ls as usize;
    for y in 0..wmh {
        let dy = oy + y;
        if dy >= dh {
            break;
        }
        let row = dst.add(dy * ls);
        for x in 0..wmw {
            let dx = ox + x;
            if dx >= dw {
                break;
            }
            let si = (y * wmw + x) * 4;
            let di = dx * 4;
            let a = wm[si + 3] as u32;
            if a == 0 {
                continue;
            }
            let ia = 255 - a;
            let b = row.add(di);
            let cr = ((wm[si] as u32 * a + *b as u32 * ia) / 255) as u8;
            let cg = ((wm[si + 1] as u32 * a + *b.add(1) as u32 * ia) / 255) as u8;
            let cb = ((wm[si + 2] as u32 * a + *b.add(2) as u32 * ia) / 255) as u8;
            *b = cr;
            *b.add(1) = cg;
            *b.add(2) = cb;
        }
    }
}

// ---------------------------------------------------------------------------
// GIF palette
// ---------------------------------------------------------------------------

fn build_palette(frames: &[Vec<u8>]) -> Vec<[u8; 4]> {
    let mut hist = [0u32; 32768];
    for f in frames {
        for px in f.chunks_exact(3) {
            let r = (px[0] >> 3) as usize;
            let g = (px[1] >> 3) as usize;
            let b = (px[2] >> 3) as usize;
            hist[(r << 10) | (g << 5) | b] += 1;
        }
    }
    let buckets: Vec<usize> = (0..32768).filter(|&i| hist[i] > 0).collect();
    let mut boxes: Vec<Vec<usize>> = vec![buckets];
    let target = 256;
    while boxes.len() < target {
        let mut best: Option<(usize, Vec<usize>, usize)> = None;
        let mut best_score: u32 = 0;
        for (bi, bx) in boxes.iter().enumerate() {
            if bx.len() < 2 {
                continue;
            }
            let mut min_r = 31u8;
            let mut max_r = 0u8;
            let mut min_g = 31u8;
            let mut max_g = 0u8;
            let mut min_b = 31u8;
            let mut max_b = 0u8;
            let mut total: u32 = 0;
            for &bb in bx {
                let r = (bb >> 10) as u8;
                let g = ((bb >> 5) & 31) as u8;
                let bl = (bb & 31) as u8;
                min_r = min_r.min(r);
                max_r = max_r.max(r);
                min_g = min_g.min(g);
                max_g = max_g.max(g);
                min_b = min_b.min(bl);
                max_b = max_b.max(bl);
                total += hist[bb];
            }
            let rr = max_r - min_r;
            let gg = max_g - min_g;
            let bb = max_b - min_b;
            let (axis, range) = if rr >= gg && rr >= bb {
                (0, rr)
            } else if gg >= bb {
                (1, gg)
            } else {
                (2, bb)
            };
            if range == 0 {
                continue;
            }
            let mut order = bx.clone();
            order.sort_by_key(|&v| match axis {
                0 => v >> 10,
                1 => (v >> 5) & 31,
                _ => v & 31,
            });
            let half = total / 2;
            let mut acc: u32 = 0;
            let mut pos = 0usize;
            for (i, &v) in order.iter().enumerate() {
                acc += hist[v];
                if acc >= half && i + 1 < order.len() {
                    pos = i + 1;
                    break;
                }
            }
            if pos == 0 || pos >= order.len() {
                continue;
            }
            let score = (range as u32) * 1000 + total.min(1000);
            if best.is_none() || score > best_score {
                best_score = score;
                best = Some((bi, order, pos));
            }
        }
        let Some((bi, order, pos)) = best else { break };
        let (a, b) = order.split_at(pos);
        boxes.remove(bi);
        boxes.push(a.to_vec());
        boxes.push(b.to_vec());
    }
    let mut palette: Vec<[u8; 4]> = Vec::with_capacity(target);
    for bx in &boxes {
        let mut sr = 0u64;
        let mut sg = 0u64;
        let mut sb = 0u64;
        let mut c = 0u64;
        for &v in bx {
            let n = hist[v] as u64;
            sr += ((v >> 10) as u64) * n;
            sg += (((v >> 5) & 31) as u64) * n;
            sb += ((v & 31) as u64) * n;
            c += n;
        }
        let inv = if c > 0 { c } else { 1 };
        let r = ((sr * 255 / inv / 31).min(255)) as u8;
        let g = ((sg * 255 / inv / 31).min(255)) as u8;
        let b = ((sb * 255 / inv / 31).min(255)) as u8;
        palette.push([r, g, b, 255]);
    }
    while palette.len() < target {
        palette.push([0, 0, 0, 255]);
    }
    palette
}

fn build_lookup(palette: &[[u8; 4]]) -> Vec<u8> {
    let mut cube = vec![0u8; 32768];
    for i in 0..32768usize {
        let r = ((i >> 10) << 3) as u8;
        let g = (((i >> 5) & 31) << 3) as u8;
        let b = ((i & 31) << 3) as u8;
        let mut best = 0usize;
        let mut bd = u32::MAX;
        for (pi, p) in palette.iter().enumerate() {
            let dr = r as i32 - p[0] as i32;
            let dg = g as i32 - p[1] as i32;
            let db = b as i32 - p[2] as i32;
            let d = (dr * dr + dg * dg + db * db) as u32;
            if d < bd {
                bd = d;
                best = pi;
            }
        }
        cube[i] = best as u8;
    }
    cube
}

fn quantize(f: &[u8], w: usize, h: usize, cube: &[u8]) -> Vec<u8> {
    let mut out = vec![0u8; w * h];
    for (i, px) in f.chunks_exact(3).enumerate() {
        let idx = (((px[0] >> 3) as usize) << 10) | (((px[1] >> 3) as usize) << 5) | ((px[2] >> 3) as usize);
        out[i] = cube[idx];
    }
    out
}

unsafe fn fill_pal8(frame: *mut ac::AVFrame, indices: &[u8], palette: &[[u8; 4]]) {
    let w = (*frame).width as usize;
    let h = (*frame).height as usize;
    let ls = (*frame).linesize[0] as usize;
    let d0 = (*frame).data[0];
    for y in 0..h {
        ptr::copy_nonoverlapping(indices.as_ptr().add(y * w), d0.add(y * ls), w);
    }
    let d1 = (*frame).data[1];
    for (i, p) in palette.iter().enumerate() {
        let o = i * 4;
        *d1.add(o) = p[0];
        *d1.add(o + 1) = p[1];
        *d1.add(o + 2) = p[2];
        *d1.add(o + 3) = p[3];
    }
}

// ---------------------------------------------------------------------------
// Main entry
// ---------------------------------------------------------------------------

pub fn process(video: &[u8], watermark: &[u8]) -> Result<(Vec<u8>, Vec<u8>), String> {
    unsafe {
        let (input, ibuf, mut iavio, mut ifc) = open_input(video)?;
        let result = process_inner(ifc, watermark);
        af::avformat_close_input(&mut ifc);
        af::avio_context_free(&mut iavio);
        if !ibuf.is_null() {
            au::av_free(ibuf as *mut c_void);
        }
        drop(input);
        result
    }
}

unsafe fn process_inner(ifc: *mut af::AVFormatContext, watermark: &[u8]) -> Result<(Vec<u8>, Vec<u8>), String> {
    let (vstream, mut dec_ctx, stream_idx) = setup_decoder(ifc)?;

    let fps = {
        let avf = (*vstream).avg_frame_rate;
        if avf.num > 0 && avf.den > 0 {
            ((avf.num as i64) + (avf.den as i64) / 2) / (avf.den as i64)
        } else {
            25
        }
    };
    let total_frames = (fps * SEGMENT_SECONDS).max(1);
    let decim = if fps >= GIF_FPS { (fps + GIF_FPS - 1) / GIF_FPS } else { 1 };

    let vw = (*dec_ctx).width;
    let vh = (*dec_ctx).height;
    if vw <= 0 || vh <= 0 {
        return Err("bad video dimensions".into());
    }
    let gw = GIF_WIDTH;
    let gh = (((vh * gw) / vw) / 2) * 2;
    if gh <= 0 {
        return Err("bad scaled dimensions".into());
    }

    //eprintln!("transcode: {}x{} @ {}fps, 5s -> {} gif frames", vw, vh, fps, (total_frames / decim).min(MAX_GIF_FRAMES as i64));

    let (wm_vec, wmw, wmh) = decode_jpeg_rgba(watermark)?;
    // eprintln!("transcode: watermark {}x{}", wmw, wmh);

    let mut mpeg4 = setup_mpeg4_muxer(vw, vh, fps)?;

    let mut sws_v2r: *mut sw::SwsContext = ptr::null_mut();
    let mut sws_r2y: *mut sw::SwsContext = ptr::null_mut();
    let mut sws_gif: *mut sw::SwsContext = ptr::null_mut();
    let mut rgba_f: *mut ac::AVFrame = ptr::null_mut();
    let mut gif_f: *mut ac::AVFrame = ptr::null_mut();
    let mut gif_frames: Vec<Vec<u8>> = Vec::new();

    let mut pkt = af::av_packet_alloc();
    if pkt.is_null() {
        return Err("av_packet_alloc failed".into());
    }
    let mut dec_frame = ac::av_frame_alloc();
    if dec_frame.is_null() {
        return Err("av_frame_alloc failed".into());
    }

    let mut frame_idx: i64 = 0;
    let mut done = false;
    while !done {
        let r = af::av_read_frame(ifc, pkt);
        if r < 0 {
            break;
        }
        if (*pkt).stream_index != stream_idx {
            af::av_packet_unref(pkt);
            continue;
        }
        let sr = ac::avcodec_send_packet(dec_ctx, pkt as *const ac::AVPacket);
        af::av_packet_unref(pkt);
        if sr < 0 {
            return Err(format!("avcodec_send_packet: {}", err_str(sr)));
        }
        loop {
            let fr = ac::avcodec_receive_frame(dec_ctx, dec_frame);
            if fr == AVERROR_EAGAIN || fr == AVERROR_EOF {
                break;
            }
            if fr < 0 {
                return Err(format!("avcodec_receive_frame: {}", err_str(fr)));
            }
            if frame_idx < total_frames {
                if sws_v2r.is_null() {
                    let fmt = (*dec_frame).format;
                    sws_v2r = sw::sws_getContext(vw, vh, fmt, vw, vh, PIX_RGBA, sw::SWS_BILINEAR as c_int, ptr::null_mut(), ptr::null_mut(), ptr::null());
                    sws_r2y = sw::sws_getContext(vw, vh, PIX_RGBA, vw, vh, PIX_YUV420P, sw::SWS_BILINEAR as c_int, ptr::null_mut(), ptr::null_mut(), ptr::null());
                    sws_gif = sw::sws_getContext(vw, vh, fmt, gw, gh, PIX_RGB24, sw::SWS_LANCZOS as c_int, ptr::null_mut(), ptr::null_mut(), ptr::null());
                    if sws_v2r.is_null() || sws_r2y.is_null() || sws_gif.is_null() {
                        return Err("sws_getContext failed".into());
                    }
                    rgba_f = alloc_frame(vw, vh, PIX_RGBA)?;
                    gif_f = alloc_frame(gw, gh, PIX_RGB24)?;
                }

                if frame_idx % decim == 0 && gif_frames.len() < MAX_GIF_FRAMES {
                    sw::sws_scale(
                        sws_gif,
                        (*dec_frame).data.as_ptr() as *const *const u8,
                        (*dec_frame).linesize.as_ptr(),
                        0,
                        vh,
                        (*gif_f).data.as_ptr() as *const *mut u8,
                        (*gif_f).linesize.as_ptr(),
                    );
                    let gls = (*gif_f).linesize[0] as usize;
                    let mut gv = vec![0u8; (gw as usize) * (gh as usize) * 3];
                    for y in 0..gh as usize {
                        ptr::copy_nonoverlapping((*gif_f).data[0].add(y * gls), gv.as_mut_ptr().add(y * (gw as usize) * 3), (gw as usize) * 3);
                    }
                    gif_frames.push(gv);
                }

                sw::sws_scale(
                    sws_v2r,
                    (*dec_frame).data.as_ptr() as *const *const u8,
                    (*dec_frame).linesize.as_ptr(),
                    0,
                    vh,
                    (*rgba_f).data.as_ptr() as *const *mut u8,
                    (*rgba_f).linesize.as_ptr(),
                );
                blend_into_frame((*rgba_f).data[0], (*rgba_f).linesize[0], vw as usize, vh as usize, &wm_vec, wmw as usize, wmh as usize);

                let mut ef = alloc_frame(vw, vh, PIX_YUV420P)?;
                sw::sws_scale(
                    sws_r2y,
                    (*rgba_f).data.as_ptr() as *const *const u8,
                    (*rgba_f).linesize.as_ptr(),
                    0,
                    vh,
                    (*ef).data.as_ptr() as *const *mut u8,
                    (*ef).linesize.as_ptr(),
                );
                (*ef).pts = frame_idx;
                mpeg4.send_frame(ef)?;
                ac::av_frame_free(&mut ef);

                frame_idx += 1;
            }
            ac::av_frame_unref(dec_frame);
            if frame_idx >= total_frames {
                done = true;
                break;
            }
        }
    }

    eprintln!("transcode: decoded/processed {} frames", frame_idx);

    let mp4_bytes = mpeg4.finish()?;

    if gif_frames.is_empty() {
        return Err("no gif frames collected".into());
    }
    let palette = build_palette(&gif_frames);
    let cube = build_lookup(&palette);
    let mut gif_muxer = setup_gif_muxer(gw, gh, &palette)?;
    for (i, f) in gif_frames.iter().enumerate() {
        let mut pf = alloc_frame(gw, gh, PIX_PAL8)?;
        let indices = quantize(f, gw as usize, gh as usize, &cube);
        fill_pal8(pf, &indices, &palette);
        (*pf).pts = i as i64;
        gif_muxer.send_frame(pf)?;
        ac::av_frame_free(&mut pf);
    }
    let gif_bytes = gif_muxer.finish()?;

    // cleanup
    if !sws_v2r.is_null() {
        sw::sws_freeContext(sws_v2r);
    }
    if !sws_r2y.is_null() {
        sw::sws_freeContext(sws_r2y);
    }
    if !sws_gif.is_null() {
        sw::sws_freeContext(sws_gif);
    }
    if !rgba_f.is_null() {
        ac::av_frame_free(&mut rgba_f);
    }
    if !gif_f.is_null() {
        ac::av_frame_free(&mut gif_f);
    }
    ac::avcodec_free_context(&mut dec_ctx);
    ac::av_frame_free(&mut dec_frame);
    af::av_packet_free(&mut pkt);

    Ok((gif_bytes, mp4_bytes))
}
