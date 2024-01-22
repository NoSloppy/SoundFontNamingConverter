package com.example.soundfontconverter;

import java.io.File;
import java.io.IOException;

import javax.sound.sampled.*;

public class AudioConverter {

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
            
            // Write converted stream to a temporary file
            File tempOutputFile = new File(inputFile.getAbsolutePath() + ".tmp");
            AudioSystem.write(convertedStream, AudioFileFormat.Type.WAVE, tempOutputFile);
            convertedStream.close();
            originalStream.close();

            // Replace original file with converted file
            boolean deleteSuccessful = inputFile.delete();
            boolean renameSuccessful = tempOutputFile.renameTo(inputFile);

            if (!deleteSuccessful || !renameSuccessful) {
                throw new IOException("Failed to replace original file with converted file.");
            }

            // Clean up: Delete the temporary file if it still exists
            if (tempOutputFile.exists()) {
                if (!tempOutputFile.delete()) {
                    throw new IOException("Failed to delete temporary file: " + tempOutputFile.getAbsolutePath());
                }
            }
            
            return true;
        }

        originalStream.close();
        return false;
    }
}
