package com.file_hasing;

import javax.xml.bind.DatatypeConverter;
import java.io.InputStream;
import java.net.URL;
import java.security.MessageDigest;

public class Workload {

    private static final int BUF_SIZE = 65536; // Read stuff in 64kb chunks.

    public static class Result {
        private final String sha1;
        private final String md5;

        public Result(String sha1, String md5) {
            this.sha1 = sha1;
            this.md5 = md5;
        }

        public String getSha1() {
            return sha1;
        }

        public String getMd5() {
            return md5;
        }
    }

    public static Result fileHash(String url) {
        try {
            byte[] buffer = new byte[BUF_SIZE];
            InputStream stream = new URL(url).openStream();
            int bytesRead = 0;
            MessageDigest sha1 = MessageDigest.getInstance("SHA1");
            MessageDigest md5 = MessageDigest.getInstance("MD5");
            while (bytesRead != -1) {
                bytesRead = stream.read(buffer);
                sha1.update(buffer);
                md5.update(buffer);
            }
            stream.close();
            return new Result(DatatypeConverter.printHexBinary(sha1.digest()), DatatypeConverter.printHexBinary(md5.digest()));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }
}


