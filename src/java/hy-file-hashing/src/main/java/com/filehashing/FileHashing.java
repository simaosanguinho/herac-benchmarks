package com.filehashing;

import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.math.BigInteger;
import java.util.Map;
import java.util.HashMap;

import org.graalvm.word.UnsignedWord;
import org.graalvm.nativeimage.c.function.CEntryPoint;
import org.graalvm.nativeimage.IsolateThread;
import org.graalvm.nativeimage.c.type.CCharPointer;
import org.graalvm.nativeimage.c.type.CTypeConversion;

import com.oracle.svm.hydra.utils.JsonUtils;

public class FileHashing {
	
	public static byte[] downloadBytes(String url) {
    	try {
    		URLConnection conn = new URL(url).openConnection();
			InputStream is = conn.getInputStream();
			byte[] bytes = is.readAllBytes();
			is.close();
			return bytes;
		} catch (IOException e) {
			e.printStackTrace();
			return null;
		}
    }

    /* For Hydra invocation. */
    public static HashMap<String, Object> main(Map<String, Object> args) {
        HashMap<String, Object> output = new HashMap<>();

        byte[] bytes = downloadBytes((String)args.get("url"));
        try {
			output.put("hash", String.format("%032X", new BigInteger(1, MessageDigest.getInstance("MD5").digest(bytes))));
		} catch (NoSuchAlgorithmException e) {
			output.put("hash", e.getMessage());
			e.printStackTrace();
		}

        return output;
    }

    /* For standalone invocations. */
    public static void main(String[] args) {
    	HashMap<String, Object> output = new HashMap<>();
    	output.put("url", "http://127.0.0.1:8000/snap.png");
        output.put("tmpDir", "/tmp");
    	output = main(output);
    	System.out.println(output);
    }

    /* For c-API invocations. */
    @CEntryPoint(name = "entrypoint")
    public static void main(IsolateThread thread, CCharPointer fin, CCharPointer fout, UnsignedWord foutLen) {
        String input = CTypeConversion.toJavaString(fin);
        Map<String, Object> map = JsonUtils.jsonToMap(input);
        String output = main(map).toString();
        if (foutLen.rawValue() > 0) {
            if (output.length() > (int) foutLen.rawValue()) {
                CTypeConversion.toCString(output.substring(0, (int) foutLen.rawValue() - 1), fout, foutLen);
            } else {
                CTypeConversion.toCString(output, fout, foutLen);
            }
        }
    }
}
