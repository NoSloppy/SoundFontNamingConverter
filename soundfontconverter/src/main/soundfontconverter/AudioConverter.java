package com.example.soundfontconverter;

import java.io.File;
import java.io.IOException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.sound.sampled.*;

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
            File convertedOutputFile = new File(inputFile.getAbsolutePath().replaceAll("\\.mp3$|\\.mp4$", ".wav"));

            // Delete existing output file if it exists
            if (convertedOutputFile.exists() && !convertedOutputFile.delete()) {
                logger.error("Failed to delete existing output file: " + convertedOutputFile.getName());
            }

            // Copy temporary file to final output location
            try {
                java.nio.file.Files.copy(tempFile.toPath(), convertedOutputFile.toPath(), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
                tempFile.delete();
            } catch (IOException e) {
                logger.error("Failed to copy temporary file to final output file: " + e.getMessage());
                throw e;
            }

            // Delete the original .mp3 file if applicable
            if (inputFile.getName().endsWith(".mp3") || inputFile.getName().endsWith(".mp4")) {
                inputFile.delete();
            }
            return true;
        }

        // Close the original stream if no conversion is needed
        originalStream.close();
        return false;
    }
}