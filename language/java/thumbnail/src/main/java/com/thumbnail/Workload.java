package com.thumbnail;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.nio.file.Files;

public class Workload {

    private static final String CLIENT_URL = "https://httpbin.org/anything";
    public static final String TMP_IMG = "img-tmp.jpg";

    private static final int WIDTH = 100;
    private static final int HEIGHT = 100;

    private static class SendThread extends Thread {
        private final String command;

        SendThread(String command) {
            this.command = command;
        }

        @Override
        public void run() {
            try {
                ProcessBuilder processBuilder = new ProcessBuilder();
                processBuilder.redirectOutput(ProcessBuilder.Redirect.INHERIT).redirectError(ProcessBuilder.Redirect.INHERIT);
                processBuilder.command(command.split(" "));
                Process process = processBuilder.start();
                process.waitFor();
            } catch (InterruptedException | IOException e) {
                e.printStackTrace();
            }
        }
    }

    private static String buildCommand(String fileName) {
        return String.format("curl --header Content-Type:image/jpeg --data @%s %s", fileName, CLIENT_URL);
    }

    public static String thumbnail(String imgUrl) {
        String output = String.format("img-%d.jpeg", System.currentTimeMillis());
        try {
            InputStream stream = new URL(imgUrl).openStream();

            BufferedImage img = new BufferedImage(WIDTH, HEIGHT, BufferedImage.TYPE_INT_RGB);
            img.createGraphics().drawImage(ImageIO.read(stream).getScaledInstance(WIDTH, HEIGHT, Image.SCALE_SMOOTH), 0, 0, null);
            ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
            ImageIO.write(img, "jpg", byteArrayOutputStream);

            File tempFile = new File(TMP_IMG);
            Files.write(tempFile.toPath(), byteArrayOutputStream.toByteArray());
            tempFile.deleteOnExit();

            SendThread sendThread = new SendThread(buildCommand(tempFile.getName()));
            sendThread.start();
            sendThread.join();

            stream.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return output;
    }
}


