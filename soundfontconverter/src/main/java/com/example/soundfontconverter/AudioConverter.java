package com.example.soundfontconverter;

import java.io.File;
import java.io.IOException;
import java.nio.file.Paths;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import javax.sound.sampled.*;
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;

public class AudioConverter {
    private static final Logger logger = LoggerFactory.getLogger(AudioConverter.class);

    public static boolean convertToWavIfNeeded(File inputFile) throws UnsupportedAudioFileException, IOException {
        AudioInputStream originalStream = AudioSystem.getAudioInputStream(inputFile);
        AudioFormat originalFormat = originalStream.getFormat();

        // Desired format: 44.1kHz, 16-bit, mono
        AudioFormat targetFormat = new AudioFormat(
                AudioFormat.Encoding.PCM_SIGNED,
                44100,  // Sample Rate
                16,     // Sample Size (bits)
                1,      // Channels (mono)
                2,      // Frame Size
                44100,  // Frame Rate
                false   // Little Endian
        );

        File outputFile = inputFile;  // Default output file is the same as the input

        // Check if conversion is needed
        if (!originalFormat.matches(targetFormat)) {
            AudioInputStream convertedStream = AudioSystem.getAudioInputStream(targetFormat, originalStream);
            logger.info("Audio: Converting " + inputFile.getName() + " to 44.1kHz, 16bit monaural .wav format.");

            // Write converted stream to a temporary file
            File tempFile = File.createTempFile("temp_", ".wav");
            AudioSystem.write(convertedStream, AudioFileFormat.Type.WAVE, tempFile);

            // Ensure streams are closed properly
            convertedStream.close();
            originalStream.close();

            // Define the final output file
            outputFile = new File(inputFile.getAbsolutePath().replaceAll("\\.mp3$|\\.mp4$", ".wav"));

            // Delete existing output file if it exists
            if (outputFile.exists() && !outputFile.delete()) {
                logger.error("Failed to delete existing output file: " + outputFile.getName());
            }

            // Copy temporary file to final output location
            try {
                java.nio.file.Files.copy(tempFile.toPath(), outputFile.toPath(), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
                tempFile.delete();
            } catch (IOException e) {
                logger.error("Failed to copy temporary file to final output file: " + e.getMessage());
                throw e;
            }

            // Delete the original .mp3 or .mp4 file if applicable
            if (inputFile.getName().endsWith(".mp3") || inputFile.getName().endsWith(".mp4")) {
                inputFile.delete();
            }
        } else {
            originalStream.close();  // Close the stream if no conversion is needed
        }

        return !outputFile.equals(inputFile);  // Return true if the file was converted
    }

    // Method to strip metadata and return boolean indicating if metadata was stripped
public static boolean stripMetadataIfPresent(File inputFile) {
    boolean wasMetadataStripped = false;
    
    try {
        if (hasMetadata(inputFile.getAbsolutePath())) {
            stripMetadata(inputFile.getAbsolutePath());
            logger.info("** Metadata removed from: " + inputFile.getName());
            wasMetadataStripped = true;  // Indicate metadata was stripped
        }
    } catch (InterruptedException e) {
        logger.error("Metadata stripping process was interrupted: " + e.getMessage());
        Thread.currentThread().interrupt();  // Restore interrupted status
    } catch (IOException e) {
        logger.error("Error while stripping metadata from: " + inputFile.getName() + ", " + e.getMessage());
    }

    return wasMetadataStripped;  // Return whether metadata was stripped
}


    // Method to check for metadata
    public static boolean hasMetadata(String filePath) throws IOException, InterruptedException {
        ProcessBuilder processBuilder = new ProcessBuilder("ffmpeg", "-i", filePath, "-f", "ffmetadata", "-");
        processBuilder.redirectErrorStream(true);

        Process process = processBuilder.start();
        InputStream is = process.getInputStream();
        BufferedReader reader = new BufferedReader(new InputStreamReader(is));
        String line;

        boolean hasImportantMetadata = false;

        while ((line = reader.readLine()) != null) {
            // Look for relevant metadata fields
            if (line.startsWith("title") || line.startsWith("artist") || line.startsWith("album") ||
                line.startsWith("genre") || line.startsWith("track")) {
                hasImportantMetadata = true;  // Metadata found
                break;  // No need to continue reading
            }
        }
        process.waitFor();

        return hasImportantMetadata;  // If true, the file will be processed; if false, it will be skipped
    }

    // Method to strip metadata
    public static void stripMetadata(String inputFilePath) throws IOException, InterruptedException {
        String tempFilePath = inputFilePath + "_temp.wav";  // Create a temporary file for output
        ProcessBuilder processBuilder = new ProcessBuilder(
            "ffmpeg", "-y", "-loglevel", "error", "-i", inputFilePath, "-map_metadata", "-1", "-c:a", "pcm_s16le", tempFilePath);
        processBuilder.redirectErrorStream(true);

        Process process = processBuilder.start();
        InputStream is = process.getInputStream();
        BufferedReader reader = new BufferedReader(new InputStreamReader(is));
        String line;
        while ((line = reader.readLine()) != null) {
            // Log only ffmpeg important lines (if necessary)
        }

        int exitCode = process.waitFor();
        if (exitCode == 0) {
            java.nio.file.Files.move(Paths.get(tempFilePath), Paths.get(inputFilePath), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
        } else {
            logger.error("ffmpeg failed with exit code: " + exitCode);
        }
    }
}
