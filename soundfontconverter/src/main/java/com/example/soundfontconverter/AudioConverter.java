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
            File convertedOutputFile = new File(inputFile.getAbsolutePath().replaceAll("\\.mp3$", ".wav"));
            AudioSystem.write(convertedStream, AudioFileFormat.Type.WAVE, convertedOutputFile);
            if (inputFile.getName().endsWith(".mp3")) inputFile.delete();
            convertedStream.close();
            originalStream.close();
            return true;
        }
        originalStream.close();
        return false;
    }
}
