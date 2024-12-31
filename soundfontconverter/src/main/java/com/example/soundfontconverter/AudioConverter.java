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
import java.io.ByteArrayInputStream;
import java.util.Arrays;

public class AudioConverter {
    private static final Logger logger = LoggerFactory.getLogger(AudioConverter.class);

    public static boolean convertToWavIfNeeded(File inputFile, boolean applyHighPass) throws UnsupportedAudioFileException, IOException {
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

        // Apply high-pass filter regardless of whether conversion was needed
        if (applyHighPass) {
            boolean highPassSuccess = applyHighPassFilter(outputFile);
            if (!highPassSuccess) {
                logger.error("High-pass filter failed for file: " + outputFile.getName());
            } else {
                logger.info("High-pass filter applied successfully to file: " + outputFile.getName());
            }
        }
        // Apply fade-in/out (fixed 40 samples)
        applyFadeInOut(outputFile);

        return !outputFile.equals(inputFile);  // Return true if the file was converted
    }

    private static void applyFadeInOut(File file) {
        try {
            // Read audio file
            AudioInputStream audioStream = AudioSystem.getAudioInputStream(file);
            AudioFormat format = audioStream.getFormat();

            // Read all bytes from the audio file
            byte[] audioBytes = audioStream.readAllBytes();
            int[] samples = bytesToSamples(audioBytes, format);

            // Define fade duration in samples (40 samples)
            int fadeSamples = 40; 
            int totalSamples = samples.length;

            // Ensure the audio is long enough for fade
            if (totalSamples < 2 * fadeSamples) {
                logger.warn("File is too short for fade-in/out: " + file.getName());
                return; // Skip fade if the audio is too short
            }

            // Get target amplitudes for fade-in and fade-out
            double targetFadeInAmplitude = samples[fadeSamples];
            double targetFadeOutAmplitude = samples[totalSamples - fadeSamples - 1];

            // Create fade-in and fade-out curves dynamically
            double[] fadeInCurve = new double[fadeSamples];
            double[] fadeOutCurve = new double[fadeSamples];
            for (int i = 0; i < fadeSamples; i++) {
                fadeInCurve[i] = (0.5 * (1 - Math.cos(Math.PI * i / fadeSamples)));
                fadeOutCurve[i] = (0.5 * (1 - Math.cos(Math.PI * i / fadeSamples)));
            }

            // Apply fade-in
            for (int i = 0; i < fadeSamples; i++) {
                samples[i] = (int) (samples[i] * fadeInCurve[i]);
            }

            // Apply fade-out
            for (int i = 0; i < fadeSamples; i++) {
                int index = totalSamples - fadeSamples + i;
                samples[index] = (int) (samples[index] * fadeOutCurve[fadeSamples - 1 - i]);
            }

            // Convert modified samples back to byte array
            byte[] fadedAudioBytes = samplesToBytes(samples, format);

            // Create an audio stream with the faded bytes
            ByteArrayInputStream bais = new ByteArrayInputStream(fadedAudioBytes);
            AudioInputStream fadedAudioStream = new AudioInputStream(bais, format, samples.length);

            // Write the faded audio back to the original file
            AudioSystem.write(fadedAudioStream, AudioFileFormat.Type.WAVE, file);

            // Close streams
            audioStream.close();
            fadedAudioStream.close();
        } catch (Exception e) {
            logger.error("Error applying fade-in/out to file: " + file.getName(), e);
        }
    }

    private static int[] bytesToSamples(byte[] byteData, AudioFormat format) {
        int sampleSizeInBytes = format.getSampleSizeInBits() / 8;
        int[] samples = new int[byteData.length / sampleSizeInBytes];
        int sampleIndex = 0;

        for (int i = 0; i < byteData.length; i += sampleSizeInBytes) {
            int sample = 0;
            for (int j = 0; j < sampleSizeInBytes; j++) {
                int shift = j * 8; // Little endian
                sample += (byteData[i + j] & 0xFF) << shift;
            }
            // Convert to signed
            if (sampleSizeInBytes == 2) { // 16-bit
                sample = (short) sample;
            }
            samples[sampleIndex++] = sample;
        }
        return samples;
    }

    private static byte[] samplesToBytes(int[] samples, AudioFormat format) {
        int sampleSizeInBytes = format.getSampleSizeInBits() / 8;
        byte[] byteData = new byte[samples.length * sampleSizeInBytes];
        int byteIndex = 0;

        for (int sample : samples) {
            for (int j = 0; j < sampleSizeInBytes; j++) {
                int shift = j * 8; // Little endian
                byteData[byteIndex++] = (byte) ((sample >> shift) & 0xFF);
            }
        }
        return byteData;
    }

    private static void reverseArray(double[] array) {
        int left = 0;
        int right = array.length - 1;
        while (left < right) {
            double temp = array[left];
            array[left] = array[right];
            array[right] = temp;
            left++;
            right--;
        }
    }

    private static boolean applyHighPassFilter(File inputFile) {
    try {
        // Define a temporary file for the processed output
        File tempFile = File.createTempFile("highpass_", ".wav");
        tempFile.deleteOnExit(); // Ensure the temp file is deleted when the program exits

        // Read the original file for RMS calculation
        AudioInputStream originalAudioStream = AudioSystem.getAudioInputStream(inputFile);
        AudioFormat originalFormat = originalAudioStream.getFormat();
        byte[] originalAudioBytes = originalAudioStream.readAllBytes();
        int[] originalSamples = bytesToSamples(originalAudioBytes, originalFormat);
        double originalRMS = calculateRMS(originalSamples);

        // Temporary padded file to avoid edge spikes
        File paddedFile = File.createTempFile("padded_", ".wav");
        paddedFile.deleteOnExit();

        // Add 500ms padding at the beginning and end of the file
        String padCommand = String.format(
            "sox \"%s\" \"%s\" pad 0.5 0.5", // Add 500ms pad
            inputFile.getAbsolutePath(),
            paddedFile.getAbsolutePath()
        );

        // Execute padding command
        ProcessBuilder padProcessBuilder = new ProcessBuilder("bash", "-c", padCommand);
        padProcessBuilder.redirectErrorStream(true);
        Process padProcess = padProcessBuilder.start();
        padProcess.waitFor();

        // Apply high-pass filter to the padded file
        String highPassCommand = String.format(
            "sox \"%s\" \"%s\" sinc -n 2048 100", // High-pass filtering
            paddedFile.getAbsolutePath(),
            tempFile.getAbsolutePath()
        );

        // Execute high-pass filter command
        ProcessBuilder highPassProcessBuilder = new ProcessBuilder("bash", "-c", highPassCommand);
        highPassProcessBuilder.redirectErrorStream(true);
        Process highPassProcess = highPassProcessBuilder.start();
        highPassProcess.waitFor();

        if (highPassProcess.exitValue() != 0) {
            logger.error("High-pass filter failed with exit code: " + highPassProcess.exitValue());
            return false;
        }

        // Trim padding from the processed file
        String trimCommand = String.format(
            "sox \"%s\" \"%s\" trim 0.5 -0.5", // Remove 500ms padding
            tempFile.getAbsolutePath(),
            inputFile.getAbsolutePath()
        );

        // Execute trimming command
        ProcessBuilder trimProcessBuilder = new ProcessBuilder("bash", "-c", trimCommand);
        trimProcessBuilder.redirectErrorStream(true);
        Process trimProcess = trimProcessBuilder.start();
        trimProcess.waitFor();

        if (trimProcess.exitValue() != 0) {
            logger.error("Trimming failed with exit code: " + trimProcess.exitValue());
            return false;
        }

        // Read the processed file for RMS calculation
        AudioInputStream processedAudioStream = AudioSystem.getAudioInputStream(inputFile);
        byte[] processedAudioBytes = processedAudioStream.readAllBytes();
        int[] processedSamples = bytesToSamples(processedAudioBytes, originalFormat);
        double processedRMS = calculateRMS(processedSamples);

        // Adjust volume to match the original RMS
        if (processedRMS > 0) { // Avoid divide by zero
            double gainFactor = (originalRMS / processedRMS) * Math.pow(10, -3.0 / 20.0); // Reduce by 3 dB
            for (int i = 0; i < processedSamples.length; i++) {
                processedSamples[i] = (int) Math.min(
                    processedSamples[i] * gainFactor,
                    Short.MAX_VALUE
                ); // Ensure samples don't exceed max value
            }

            // Convert adjusted samples back to byte array
            byte[] adjustedAudioBytes = samplesToBytes(processedSamples, originalFormat);

            // Write the adjusted audio back to the original file
            ByteArrayInputStream bais = new ByteArrayInputStream(adjustedAudioBytes);
            AudioInputStream adjustedAudioStream = new AudioInputStream(bais, originalFormat, processedSamples.length);
            AudioSystem.write(adjustedAudioStream, AudioFileFormat.Type.WAVE, inputFile);

            adjustedAudioStream.close();
        }

        processedAudioStream.close();
        originalAudioStream.close();
        return true;

    } catch (Exception e) {
        logger.error("Error while applying high-pass filter: " + e.getMessage(), e);
        return false;
    }
}

// Utility method to calculate RMS
private static double calculateRMS(int[] samples) {
    double sum = 0;
    for (int sample : samples) {
        sum += sample * sample;
    }
    return Math.sqrt(sum / samples.length);
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
