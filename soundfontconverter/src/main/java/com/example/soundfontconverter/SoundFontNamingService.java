package com.example.soundfontconverter;

import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Autowired;

import java.io.IOException;
import java.nio.file.*;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.util.stream.Stream;
import java.util.Comparator;
import java.util.stream.Collectors;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Set;
import java.util.HashSet;
import java.util.Arrays;
import java.util.regex.Pattern;
import java.util.regex.Matcher;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.example.soundfontconverter.AudioConverter;
import javax.sound.sampled.UnsupportedAudioFileException;

@Service
public class SoundFontNamingService {

    private final ConversionLogService conversionLogService;
    private static final Logger logger = LoggerFactory.getLogger(SoundFontConverterController.class);

    @Autowired
    public SoundFontNamingService(ConversionLogService conversionLogService) {
        this.conversionLogService = conversionLogService;
    }

    enum BoardType {
        CFX,
        GH3,
        PROFFIE,
        VERSO,
        XENO3;

        public static String getKey(BoardType source, BoardType target) {
            return source.name() + "_TO_" + target.name();
        }
    }
    private StringBuilder logStringBuilder = new StringBuilder();
    private boolean is_chained_ = false;  // For logging purposes. is_chained_ means double conversions.
    private String realTargetBoard = "PROFFIE";
    private boolean second_loop_ = false;  // Second conversions are second_loop_.
    private String zipTargetDir = "";
    private String originalSourceBoard = "";
    private String originalSourceDirName = "";
    private static final String DEFAULTS_PATH = "./inis";
    private static final Map<String, String> CFX_TO_PROFFIE = new HashMap<>();
    private static final Map<String, String> CFX_TO_VERSO = new HashMap<>();
    private static final Map<String, String> GH3_TO_PROFFIE = new HashMap<>();
    private static final Map<String, String> PROFFIE_TO_CFX = new HashMap<>();
    private static final Map<String, String> PROFFIE_TO_GH3 = new HashMap<>();
    private static final Map<String, String> PROFFIE_TO_VERSO = new HashMap<>();
    private static final Map<String, String> PROFFIE_TO_XENO3 = new HashMap<>();
    private static final Map<String, String> VERSO_TO_CFX = new HashMap<>();
    private static final Map<String, String> VERSO_TO_PROFFIE = new HashMap<>();
    private static final Map<String, String> XENO3_TO_PROFFIE = new HashMap<>();
    // Map to store original filenames
    private Map<String, String> originalFilenames = new HashMap<>();  //... additional board mappings can be added here

    // Central mapping repository
    private static final Map<String, Map<String, String>> soundMappings = new HashMap<>();
    private static final Map<String, Integer> soundCounter = new HashMap<>();

    static {
        initializeMappings();
    }

    private static void loadMappingsFromCSV(String csvFilePath, Map<String, String> mapping) {
        try (BufferedReader reader = new BufferedReader(new FileReader(csvFilePath))) {
            String line;
            while ((line = reader.readLine()) != null) {
                String[] parts = line.split(",");
                if (parts.length >= 2) {
                    mapping.put(parts[0], parts[1]);
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private static void safeLoadMappingsFromCSV(String csvFilePath, Map<String, String> mapping) {
        File f = new File(csvFilePath);
        if(f.exists() && !f.isDirectory()) { 
            loadMappingsFromCSV(csvFilePath, mapping);
        }
    }

    private static void initializeMappings() {
        safeLoadMappingsFromCSV("./CSV/CFX_TO_PROFFIE.csv", CFX_TO_PROFFIE);
        // safeLoadMappingsFromCSV("./CSV/CFX_TO_VERSO.csv", CFX_TO_VERSO);
        // safeLoadMappingsFromCSV("./CSV/GH3_TO_PROFFIE.csv", GH3_TO_PROFFIE);
        safeLoadMappingsFromCSV("./CSV/PROFFIE_TO_CFX.csv", PROFFIE_TO_CFX);
        // safeLoadMappingsFromCSV("./CSV/PROFFIE_TO_GH3.csv", PROFFIE_TO_CFX);
        safeLoadMappingsFromCSV("./CSV/PROFFIE_TO_VERSO.csv", PROFFIE_TO_VERSO);
        safeLoadMappingsFromCSV("./CSV/PROFFIE_TO_XENO3.csv", PROFFIE_TO_XENO3);
        // safeLoadMappingsFromCSV("./CSV/VERSO_TO_PROFFIE.csv", VERSO_TO_PROFFIE);
        safeLoadMappingsFromCSV("./CSV/XENO3_TO_PROFFIE.csv", XENO3_TO_PROFFIE);
    // ... and so on for other mappings ...

        soundMappings.put(BoardType.getKey(BoardType.CFX, BoardType.PROFFIE), CFX_TO_PROFFIE);
        // soundMappings.put(BoardType.getKey(BoardType.CFX, BoardType.VERSO), CFX_TO_VERSO);
        soundMappings.put(BoardType.getKey(BoardType.PROFFIE, BoardType.CFX), PROFFIE_TO_CFX);
        soundMappings.put(BoardType.getKey(BoardType.PROFFIE, BoardType.GH3), PROFFIE_TO_CFX);
        soundMappings.put(BoardType.getKey(BoardType.PROFFIE, BoardType.VERSO), PROFFIE_TO_VERSO);
        soundMappings.put(BoardType.getKey(BoardType.PROFFIE, BoardType.XENO3), PROFFIE_TO_XENO3);
        soundMappings.put(BoardType.getKey(BoardType.GH3, BoardType.PROFFIE), CFX_TO_PROFFIE);
        // soundMappings.put(BoardType.getKey(BoardType.VERSO, BoardType.CFX), VERSO_TO_CFX);
        soundMappings.put(BoardType.getKey(BoardType.VERSO, BoardType.PROFFIE), VERSO_TO_PROFFIE);
        soundMappings.put(BoardType.getKey(BoardType.XENO3, BoardType.PROFFIE), XENO3_TO_PROFFIE);

      // Reverse Mapping fist so actual mappings will override

        // CFX to Proffie mapping
        for (Map.Entry<String, String> entry : PROFFIE_TO_CFX.entrySet()) {
            CFX_TO_PROFFIE.putIfAbsent(entry.getValue(), entry.getKey());
        }
        // for (Map.Entry<String, String> entry : VERSO_TO_CFX.entrySet()) {
        //     CFX_TO_VERSO.putIfAbsent(entry.getValue(), entry.getKey());
        // }
        // Verso to Proffie mapping
        for (Map.Entry<String, String> entry : PROFFIE_TO_VERSO.entrySet()) {
            VERSO_TO_PROFFIE.putIfAbsent(entry.getValue(), entry.getKey());
        }
        // Xeno3 to Proffie mapping
        for (Map.Entry<String, String> entry : PROFFIE_TO_XENO3.entrySet()) {
            XENO3_TO_PROFFIE.putIfAbsent(entry.getValue(), entry.getKey());
        }
    }

    private static void ensureDirectoryExists(Path dirPath) {
        try {
            if (!Files.exists(dirPath)) {
                Files.createDirectories(dirPath);
                logger.info("** Creating directory: " + dirPath);
            }
        } catch (IOException ex) {
            ex.printStackTrace();
        }
    }

    private static void copyFile(Path sourcePath, Path targetPath) {
        try {
            Files.copy(sourcePath, targetPath, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException ex) {
            System.err.println("Error copying file from " + sourcePath + " to " + targetPath);
            ex.printStackTrace();
        }
    }

    private void log(String sessionId, String message) {
        logger.info(message);
        if (is_chained_ && !second_loop_) {
            return;
        } else {
            logStringBuilder.append(message + "\n");
            conversionLogService.sendLogToEmitter(sessionId, message);
        }
    }

    private int extractNumber(String fileName) {
        Pattern pattern = Pattern.compile("\\((\\d+)\\)\\.wav$");
        Matcher matcher = pattern.matcher(fileName);
        if (matcher.find()) {
            return Integer.parseInt(matcher.group(1));
        }

        String numberStr = fileName.replaceAll("[^\\d]", "");
        return numberStr.isEmpty() ? 1 : Integer.parseInt(numberStr);
    }

    private void convertSounds(String sessionId, BoardType srcBoardType, BoardType tgtBoardType, String tempDirName, boolean optimizeCheckbox, String sourceDirName) throws IOException {
        soundCounter.clear();
        String key = BoardType.getKey(srcBoardType, tgtBoardType);
        String effectiveSourceDirName = (is_chained_ && second_loop_) ? originalSourceDirName : sourceDirName;

        logger.info("--------------------------------------------------\n");

        if (is_chained_) {  // means neither source nor target boards are PROFFIE
            if (!second_loop_) {
                logger.info("** First step: Converting " + sourceDirName + " from " + srcBoardType + " to " + tgtBoardType);
                logger.info("** Second step: Converting from " + tgtBoardType + " to " + sourceDirName + "_" + realTargetBoard);
                logger.info("** Last step: Zipping " + sourceDirName + "_" + realTargetBoard + " into CONVERTED_to_" + realTargetBoard + ".zip\n");
            }
        } else {
            logger.info("** First step: Converting " + sourceDirName + " from " + srcBoardType + " to " + tgtBoardType);
            logger.info("** Last step: Zipping " + sourceDirName + "_" + tgtBoardType + " into CONVERTED_to_" + tgtBoardType + ".zip\n");
        }

        // Include a special case for GH3 output directory naming
        String shortTargetDir = "Converted_to_" + tgtBoardType + "/" + 
                                   (tgtBoardType == BoardType.GH3 ? "sound1 - " : "") + 
                                   sourceDirName;
        Path targetDirPath = Paths.get(tempDirName, shortTargetDir);
        Path extrasDirPath = targetDirPath.resolve("extras");
        Path tracksDirPath = targetDirPath.resolve("tracks");

        // Prepare Log file
        ensureDirectoryExists(targetDirPath);
        SimpleDateFormat sdf = new SimpleDateFormat("MMM dd, yyyy");
        String currentDate = sdf.format(new Date());

        if (!is_chained_) {
            logger.info( "------------------------------------------------\n");
            conversionLogService.sendLogToEmitter(sessionId, "---------------------------------------------------------------------\n");
            logStringBuilder.append( "------------------------------------------------\n");
            log(sessionId, "Converted with SoundFont Naming Converter 3.1.0");
            log(sessionId, "Brian Conner a.k.a NoSloppy");
            log(sessionId, currentDate);
            log(sessionId, "\n");
            log(sessionId, "Converting: " + sourceDirName + " from " + srcBoardType + " to " + tgtBoardType);
            if (tgtBoardType == BoardType.PROFFIE) log(sessionId, "Optimized for Fat32 performance: " + (optimizeCheckbox ? "Yes" : "No"));
            log(sessionId, "\n");
        } else if (!second_loop_) {
            logger.info( "------------------------------------------------\n");
            logger.info( "Converted with SoundFont Naming Converter 3.1.0");
            logger.info( "Brian Conner a.k.a NoSloppy");
            logger.info( currentDate);
            logger.info( "\n");
            logger.info( "Converting: " + sourceDirName + " from " + srcBoardType + " to " + tgtBoardType);
            if (tgtBoardType == BoardType.PROFFIE) logger.info( "Optimized for Fat32 performance: " + (optimizeCheckbox ? "Yes" : "No"));
            logger.info( "\n");
        } else {
            conversionLogService.sendLogToEmitter(sessionId, "---------------------------------------------------------------------\n");
            conversionLogService.sendLogToEmitter(sessionId, "Converted with SoundFont Naming Converter 3.1.0");
            conversionLogService.sendLogToEmitter(sessionId, "Brian Conner a.k.a NoSloppy");
            conversionLogService.sendLogToEmitter(sessionId, currentDate);
            conversionLogService.sendLogToEmitter(sessionId, "\n");
            conversionLogService.sendLogToEmitter(sessionId, "Converting: " + effectiveSourceDirName + " from " + originalSourceBoard + " to " + tgtBoardType);
            logger.info( "Converting: " + sourceDirName + " from " + srcBoardType + " to " + tgtBoardType);
            if (tgtBoardType == BoardType.PROFFIE) conversionLogService.sendLogToEmitter(sessionId, "Optimized for Fat32 performance: " + (optimizeCheckbox ? "Yes" : "No"));
            conversionLogService.sendLogToEmitter(sessionId, "\n");

            logStringBuilder.append( "------------------------------------------------\n");
            logStringBuilder.append( "Converted with SoundFont Naming Converter 3.1.0\n");
            logStringBuilder.append( "Brian Conner a.k.a NoSloppy\n");
            logStringBuilder.append( currentDate + "\n\n");
            logStringBuilder.append( "Converting: " + effectiveSourceDirName + " from " + originalSourceBoard + " to " + tgtBoardType + "\n");
            if (tgtBoardType == BoardType.PROFFIE) logStringBuilder.append( "Optimized for Fat32 performance: " + (optimizeCheckbox ? "Yes" : "No") + "\n\n");
        }

        // If it's Proffie to Proffie, skip the mapping
        Map<String, String> mapping;
        if (srcBoardType == BoardType.PROFFIE && tgtBoardType == BoardType.PROFFIE) {
            mapping = null;
        } else {
            if (!soundMappings.containsKey(key)) {
                logger.info("** Conversion from " + srcBoardType + " to " + tgtBoardType + " is not supported.");
                return;
            }
            mapping = soundMappings.get(key);
        }

        Path fullPath;
        if (is_chained_ && second_loop_) {
            // In the second loop, adjust the path to point to the converted files
            fullPath = Paths.get(tempDirName, "Converted_to_PROFFIE", sourceDirName);
        } else {
            // In the first loop, or non-chained conversions
            fullPath = Paths.get(tempDirName, sourceDirName);
        }

        // Check if source has directories named something like "Bonus Files" or "extra"
        boolean hasExtrasDirectories = false;
        try {
            hasExtrasDirectories = Files.walk(fullPath, 1) // Only check immediate children
            .filter(Files::isDirectory).anyMatch(path -> {
                String dirName = path.getFileName().toString().toLowerCase();
                return dirName.contains("bonus") || dirName.contains("extra");
            });
        } catch (IOException ex) {
            ex.printStackTrace();
        }

        // If "extras" directory is needed, create it now
        if (hasExtrasDirectories) {
            ensureDirectoryExists(extrasDirPath);
        }

        // Main sound conversion
        try (Stream<Path> paths = Files.walk(fullPath)) {
            Map<String, Integer> fileNameCounter = new HashMap<>();

            paths.filter(Files::isRegularFile)
            .filter(path -> !path.getFileName().toString().startsWith("."))
            .filter(path -> {
                String fileName = path.getFileName().toString();
                String parentDirName = path.getParent().getFileName().toString().toLowerCase();
                if (parentDirName.contains("bonus") || parentDirName.contains("extra")) {
                    Path extraFilePath = extrasDirPath.resolve(fileName);
                    copyFile(path, extraFilePath);
                    log(sessionId, "- Moved extra/bonus file -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/extras/" + fileName);
                    return false;
                }
                return true;
            })
            .sorted((path1, path2) -> {
                String file1 = path1.getFileName().toString().toLowerCase();
                String file2 = path2.getFileName().toString().toLowerCase();
                String prefix1 = file1.replaceAll("\\(\\d+\\)\\.wav$", "").replaceAll("\\d*\\.wav$", "");
                String prefix2 = file2.replaceAll("\\(\\d+\\)\\.wav$", "").replaceAll("\\d*\\.wav$", "");
                int prefixCompare = prefix1.compareTo(prefix2);
                if (prefixCompare != 0) {
                    return prefixCompare;
                }
                boolean file1IsUnnumbered = !file1.matches(".*\\d.*\\.wav$");
                boolean file2IsUnnumbered = !file2.matches(".*\\d.*\\.wav$");

                if (file1IsUnnumbered && !file2IsUnnumbered) {
                    return -1; // File1 (unnumbered) should come before File2 (numbered)
                } else if (!file1IsUnnumbered && file2IsUnnumbered) {
                    return 1; // File1 (numbered) should come after File2 (unnumbered)
                }
                int number1 = extractNumber(file1);
                int number2 = extractNumber(file2);
                return Integer.compare(number1, number2);
            })

            .forEach(path -> {
                try {
                    String fileName = path.getFileName().toString();
                    // Convert to lowercase only if the file is a .wav file
                    if (fileName.toLowerCase().endsWith(".wav")) {
                        fileName = fileName.toLowerCase();
                    }

                        int number = fileName.matches(".*\\d+\\.wav$") ? Integer.parseInt(fileName.replaceAll("\\D+", "")) : 1;

// Check and convert audio file if needed
File inputFile = path.toFile();
boolean wasConverted = false;
try {
    wasConverted = AudioConverter.convertToWavIfNeeded(inputFile);
} catch (UnsupportedAudioFileException | IOException e) {
    logger.error("Audio conversion failed: " + e.getMessage());
}

if (wasConverted) {
    log(sessionId, "- File: " + fileName + " was converted to 44.1kHz, 16bit monaural .wav format.");
}


                    // Move non-wav files directly to the target folder
                    if (!fileName.endsWith(".wav")) {
                        Path nonWavFilePath = targetDirPath.resolve(fileName);
                    copyFile(path, nonWavFilePath);
                    log(sessionId, "- Moved non-wav file -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + fileName);
                        return;
                    }

                    // Move "track" wav files to "tracks" folder if not xeno
                    if (fileName.contains("track") || fileName.contains("theme")) {
                        if (tgtBoardType == BoardType.XENO3) {
                            log(sessionId, "Targetboard = Xeno, renaming files named 'track' or 'theme'");
                        } else {
                            ensureDirectoryExists(tracksDirPath);
                            Path trackFilePath = tracksDirPath.resolve(fileName);
                            copyFile(path, trackFilePath);
                            log(sessionId,  "Moved track file -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + fileName);
                            return;
                        }
                    }

                    // For other wav files, use the mapping
                    String baseName = fileName.replaceAll("( \\(\\d+\\)| \\d+|\\(\\d+\\)|\\d+)+\\.wav$", ".wav");

                    // If we're doing Proffie to Proffie, keep the baseName as is
                    String convertedBaseName = (mapping == null) ? baseName : mapping.getOrDefault(baseName, baseName);

                    String outputPath = "";
                    Path originalPath;
                    Path newPath;

                    if (convertedBaseName != null) {
                        int count = soundCounter.getOrDefault(convertedBaseName, 0) + 1;
                        soundCounter.put(convertedBaseName, count);

                        String prefix = (convertedBaseName.contains("."))
                                        ? convertedBaseName.substring(0, convertedBaseName.lastIndexOf('.'))
                                        : convertedBaseName;

                        String formattedCount = String.valueOf(count);

                        Set<String> loggedFiles = new HashSet<>();  // flag to prevent multi logging of poweroff case 

                        if (tgtBoardType == BoardType.CFX) {
                            String newPrefix;
                            int currentCounter;


                            String switchKey = convertedBaseName.toLowerCase().replaceAll("\\.wav$", "");
                            String commonKey;
                            switch (switchKey) {
                                // Adding pwroff2 regardless of only 1 input file.
                                case "poweroff":
                                    commonKey = "pwroff";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    if (currentCounter == 1) {
                                        // Create poweroff.wav
                                        Path poweroffPath = targetDirPath.resolve("poweroff.wav");
                                        copyFile(path, poweroffPath);
                                        log(sessionId, "Converted: " + path.getFileName() + " -> " + poweroffPath.getFileName());

                                        // Also create pwroff2.wav
                                        Path pwroff2Path = targetDirPath.resolve("pwroff2.wav");
                                        copyFile(path, pwroff2Path);
                                        log(sessionId, "Also create pwroff2.wav: " + path.getFileName() + " -> " + pwroff2Path.getFileName());
                                    } else if (currentCounter == 2) {
                                        // Overwrite pwroff2.wav
                                        Path pwroff2Path = targetDirPath.resolve("pwroff2.wav");
                                        copyFile(path, pwroff2Path);
                                        log(sessionId, "Updated pwroff2.wav: " + path.getFileName() + " -> " + pwroff2Path.getFileName());
                                    } else {
                                        // Follow original pattern for subsequent files
                                        newPrefix = "poweroff" + (currentCounter - 1);
                                        Path poweroffPath = targetDirPath.resolve(newPrefix + ".wav");
                                        copyFile(path, poweroffPath);
                                        // Log the file creation
                                        log(sessionId, "Converted: " + path.getFileName() + " -> " + poweroffPath.getFileName());
                                    }
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    loggedFiles.add(path.getFileName().toString()); // Add the filename to the set
                                    break;

                                // case "clash":
                                //     commonKey = "clash";
                                //     currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                //     if (currentCounter == 1) {
                                //         newPrefix = "clash" + currentCounter;
                                //     } else if (currentCounter == 2) {
                                //         newPrefix = "fclash" + (currentCounter -1);
                                //     } else {
                                //         newPrefix = "clash" + (currentCounter - 1);
                                //     }
                                //     outputPath = targetDir + "/" + newPrefix + ".wav";
                                //     fileNameCounter.put(commonKey, currentCounter + 1);
                                //     break;

                                case "font":
                                    commonKey = "font";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    if (currentCounter == 1) {
                                        Path fontPath = targetDirPath.resolve("font.wav");
                                        outputPath = fontPath.toString();
                                    } else {
                                        int nextBootCounter = fileNameCounter.getOrDefault("boot", 1);
                                        Path bootPath = targetDirPath.resolve("boot" + (nextBootCounter == 1 ? "" : nextBootCounter) + ".wav");
                                        outputPath = bootPath.toString();
                                        fileNameCounter.put("boot", nextBootCounter + 1);
                                    }
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    break;

                                // These get no number on the first file, then sequence the rest staring from 2
                                case "boot":
                                    commonKey = "boot";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    Path bootPath = targetDirPath.resolve("boot" + (currentCounter == 1 ? "" : currentCounter) + ".wav");
                                    outputPath = bootPath.toString();
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    break;

                                case "color":
                                    commonKey = "color";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    Path colorPath = targetDirPath.resolve(convertedBaseName.substring(0, convertedBaseName.length() - 4) + (currentCounter == 1 ? "" : currentCounter) + ".wav");
                                    outputPath = colorPath.toString();
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    break;
                                // case "blaster":
                                //     commonKey = "blaster";
                                //     currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                //     outputPath = targetDir + "/" + convertedBaseName.substring(0, convertedBaseName.length() - 4) + (currentCounter == 1 ? "" : currentCounter) + ".wav";
                                //     fileNameCounter.put(commonKey, currentCounter + 1);
                                //     break;
                                case "poweron":
                                    commonKey = "poweron";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    Path poweronPath = targetDirPath.resolve(convertedBaseName.substring(0, convertedBaseName.length() - 4) + (currentCounter == 1 ? "" : currentCounter) + ".wav");
                                    outputPath = poweronPath.toString();
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    break;
                                case "lockup":
                                    commonKey = "lockup";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    Path lockupPath = targetDirPath.resolve(convertedBaseName.substring(0, convertedBaseName.length() - 4) + (currentCounter == 1 ? "" : currentCounter) + ".wav");
                                    outputPath = lockupPath.toString();
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    break;
                                case "drag":
                                    commonKey = "drag";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    Path dragPath = targetDirPath.resolve(convertedBaseName.substring(0, convertedBaseName.length() - 4) + (currentCounter == 1 ? "" : currentCounter) + ".wav");
                                    outputPath = dragPath.toString();
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    break;
                                // case "drag":
                                //     commonKey = "drag";
                                //     currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                //     // Use commonKey to generate outputPath
                                //     outputPath = targetDir + "/" + commonKey + (currentCounter == 1 ? "" : currentCounter) + ".wav";
                                //     fileNameCounter.put(commonKey, currentCounter + 1);
                                //     break;

                                case "force":
                                    commonKey = "force";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    Path forcePath = targetDirPath.resolve(convertedBaseName.substring(0, convertedBaseName.length() - 4) + (currentCounter == 1 ? "" : currentCounter) + ".wav");
                                    outputPath = forcePath.toString();
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    break;

                                default:
                                    currentCounter = fileNameCounter.getOrDefault(switchKey, 1);
                                    Path defaultPath = targetDirPath.resolve(convertedBaseName.substring(0, convertedBaseName.length() - 4) + currentCounter + ".wav");
                                    outputPath = defaultPath.toString();
                                    fileNameCounter.put(switchKey, currentCounter + 1);
                                    break;
                            }

                        } else if (tgtBoardType == BoardType.PROFFIE) {
                            if (prefix.length() > 6 && count == 1 && soundCounter.containsKey(baseName)) {
                                formattedCount = String.valueOf(count);
                            } else {
                                formattedCount = (prefix.length() > 6) ? String.valueOf(count) : String.format("%02d", count);
                            }
                            if (optimizeCheckbox) {
                                originalPath = count == 1 ? targetDirPath.resolve(prefix + ".wav") : targetDirPath.resolve(prefix).resolve(prefix + formattedCount + ".wav");
                                outputPath = originalPath.toString();

                                if (count == 2) {
                                    originalPath = targetDirPath.resolve(prefix + ".wav");
                                    newPath = targetDirPath.resolve(prefix).resolve(prefix + (prefix.length() > 6 ? "1.wav" : "01.wav"));
                                    ensureDirectoryExists(targetDirPath.resolve(prefix));
                                                                        Files.move(originalPath, newPath, StandardCopyOption.REPLACE_EXISTING);
                                    log(sessionId, "- Numbered and moved first file to subdirectory: ");
                                    log(sessionId, effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + prefix + ".wav" +
                                                    " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + prefix + "/" + newPath.getFileName());
                                }
                            } else {
                                originalPath = targetDirPath.resolve((count > 1 ? prefix + formattedCount : prefix) + ".wav");
                                outputPath = originalPath.toString();

                                if (count == 2) {
                                    originalPath = targetDirPath.resolve(prefix + ".wav");
                                   newPath = targetDirPath.resolve(prefix + (prefix.length() > 6 ? "1.wav" : "01.wav"));
                                    Files.move(originalPath, newPath, StandardCopyOption.REPLACE_EXISTING);
                                    // Update the map directly with the new numbered filename
                                    String newNumberedFilename = prefix + (prefix.length() > 6 ? "1.wav" : "01.wav");
                                    if (originalFilenames.containsKey(prefix + ".wav")) {
                                        // Update the map with the new numbered filename
                                        originalFilenames.put(newNumberedFilename, originalFilenames.get(prefix + ".wav"));
                                        // Remove the unnumbered entry as it's no longer needed
                                        originalFilenames.remove(prefix + ".wav");
                                    }
                                   String logPathPrefix = is_chained_ ? shortTargetDir : effectiveSourceDirName + "_" + tgtBoardType.toString();
                                        log(sessionId, "- Numbered the first file: ");
                                        log(sessionId, logPathPrefix + "/" + prefix + ".wav" + " -> " + logPathPrefix + "/" + newPath.getFileName());
                                }
                            }

                        } else if (tgtBoardType == BoardType.VERSO && convertedBaseName.equals("font.wav")) {
                            String commonKey = "font";
                            int currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                            fileNameCounter.put(commonKey, currentCounter + 1);

                            if (currentCounter == 1) {
                                originalPath = targetDirPath.resolve("font.wav");
                                outputPath = originalPath.toString();
                                copyFile(path, Paths.get(outputPath));
                                log(sessionId, "Converted: " + path.getFileName().toString() + " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + path.getFileName().toString());
                            } else {
                                log(sessionId, "Skipped additional 'font' file: " + fileName);
                            }
                            return;

                        } else if (tgtBoardType == BoardType.XENO3) {
                            originalPath = targetDirPath.resolve(prefix + " (" + count + ").wav");
                            outputPath = originalPath.toString();

                        } else if (count > 1 || (tgtBoardType != BoardType.PROFFIE && count == 1)) {
                            originalPath = targetDirPath.resolve(prefix + formattedCount + ".wav");
                            outputPath = originalPath.toString();
                        } else {
                            originalPath = targetDirPath.resolve(prefix + ".wav");
                            outputPath = originalPath.toString();
                        }

                        String proffieFilename = "";

                        // Store the original filename and its corresponding PROFFIE format filename
                        if (is_chained_ && !second_loop_) {
                            proffieFilename = Paths.get(outputPath.toString()).getFileName().toString();
                            originalFilenames.put(proffieFilename, fileName);  // Map PROFFIE format name to original filename
                        }

                        if (!loggedFiles.contains(path.getFileName().toString())) {
                            copyFile(path, Paths.get(outputPath));
                            String targetPathLog;

                            // Check if the conversion is chained and in the second loop
                            if (is_chained_ && second_loop_) {

                                // Retrieve the original filename using PROFFIE format name as key
                                String originalFilename = originalFilenames.getOrDefault(path.getFileName().toString(), path.getFileName().toString());
                                String finalTargetFilename;

                                // Conditional logging based on target board type
                                if (tgtBoardType == BoardType.VERSO) {
                                    // Format for VERSO board
                                    finalTargetFilename = prefix + formattedCount + ".wav";
                                    targetPathLog = effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + finalTargetFilename;
                                    log(sessionId, "Converted: " + originalFilename + " -> " + targetPathLog);
                                } else if (tgtBoardType == BoardType.XENO3) {
                                    // Format for XENO3 board
                                    finalTargetFilename = prefix + " (" + count + ").wav";
                                    targetPathLog = effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + finalTargetFilename;
                                    log(sessionId, "Converted: " + originalFilename + " -> " + targetPathLog);
                                } else {
                                    // Default format for other boards
                                    finalTargetFilename = prefix + formattedCount + ".wav";
                                    targetPathLog = effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + finalTargetFilename;
                                    log(sessionId, "Converted: " + originalFilename + " -> " + targetPathLog);
                                }
                            } else {
                                // Original logic for handling outputPath for non-chained or first loop conversions
                                if ("PROFFIE".equals(realTargetBoard)) {
                                    targetPathLog = count > 1 && optimizeCheckbox 
                                        ? "DDC_PROFFIE/" + prefix + "/" + Paths.get(outputPath).getFileName().toString()
                                        : "DDC_PROFFIE/" + Paths.get(outputPath).getFileName().toString();
                                } else {
                                    targetPathLog = outputPath.replace(tempDirName + "/", "");
                                }
                                log(sessionId, "Converted: " + path.getFileName().toString() + " -> " + targetPathLog);
                            }
                        }







                    } else { // convertedBaseName = null
                        logger.info("** Skipped wav file without mapping: " + fileName);
                    }
                } catch (IOException e) {
                    System.err.println("An IOException occurred: " + e.getMessage());
                }
            });
            zipTargetDir = targetDirPath.toString();
            if (!is_chained_) {
                log(sessionId, "\n");
            } else if (!second_loop_) {
                log(sessionId, "\nLoop 2:\n");
            } else {
                log(sessionId, "\n");
            }

        } catch (IOException ex) {
            System.err.println("An error occurred while reading the file: " + ex.getMessage());
        }

        // After processing all files, check for default INIs for Proffie
        if (!is_chained_) {
            if (tgtBoardType == BoardType.PROFFIE) {
                String[] defaultFiles = {"config.ini", "smoothsw.ini"};
                for (String defaultFile : defaultFiles) {
                    File targetDefaultFile = targetDirPath.resolve(defaultFile).toFile();
                    if (!targetDefaultFile.exists()) {
                        File inisFile = new File(DEFAULTS_PATH + "/" + defaultFile);
                        if (inisFile.exists()) {
                            try {
                                Files.copy(inisFile.toPath(), targetDefaultFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
                                log(sessionId, "Copied missing default file -> " + shortTargetDir + "/" + defaultFile);
                            } catch (IOException e) {
                                // e.printStackTrace();
                                System.err.println("Error while copying file: " + defaultFile);

                            }
                        }
                    }
                }
            }
            log(sessionId, "------------- | **** MTFBWY **** | -------------");
        } else if (second_loop_) {
        log(sessionId, "------------- | **** MTFBWY **** | -------------");
        }
    }

    public class MutableInt {
        public int value;
        public MutableInt(int value) {
            this.value = value;
        }
    }

    public void cleanupTemporaryDirectory(String tempDirName) {
        logger.info("** Cleanup time. Removing temp files inside: (tempDirName) " + tempDirName);
        try {
            Path tempDir = Paths.get(tempDirName);
            if (Files.exists(tempDir)) {
                Files.walk(tempDir)
                    .sorted(Comparator.reverseOrder())  // Important to delete child before parent
                    .forEach(path -> {
                        try {
                            Files.deleteIfExists(path);
                        } catch (IOException e) {
                            // Handle the exception, e.g., logging it.
                            e.printStackTrace();
                        }
                    });
            }

            // Deleting the generated zip file.

        } catch (IOException e) {
            // Handle the exception, e.g., logging it.
            e.printStackTrace();
        }
    }

    public void chainConvertSoundFont(String sessionId, String sourceBoard, String targetBoard, String tempDirName, boolean optimize, String sourceDirName) throws IOException {
        BoardType srcBoardType = BoardType.valueOf(sourceBoard.toUpperCase());
        BoardType tgtBoardType = BoardType.valueOf(targetBoard.toUpperCase());
        originalSourceBoard = sourceBoard;
        originalSourceDirName = sourceDirName;
        is_chained_ = !(srcBoardType == BoardType.PROFFIE || tgtBoardType == BoardType.PROFFIE);
        
        logStringBuilder.setLength(0);

            // Using realTargetBoard for logging only
            realTargetBoard = targetBoard;
        if (is_chained_) {
            // Do the chained conversion;
            // convert to PROFFIE first and save it in /temporaryDirectory/Converted_to_PROFFIE.            logger.info("** realTargetBoard: " + realTargetBoard);
// logger.info("((((((((((((( chainConvertSoundFont Starting Round 1 chained, sending  sourceDirName as " + sourceDirName);
            convertSounds(sessionId, srcBoardType, BoardType.PROFFIE, tempDirName, false, sourceDirName);
            second_loop_ = !second_loop_;

            // Now use the converted PROFFIE files as source for the actual target.

            Path tempProffieDir = Paths.get(tempDirName, "Converted_to_PROFFIE");
            List<Path> proffieFiles = Files.walk(tempProffieDir)
                                           .filter(Files::isRegularFile)
                                           .collect(Collectors.toList());
            // Clear and Set Up Log for Second Conversion
            // logStringBuilder.setLength(0);  // not needed because we don't log during first loop anyway, and this just wipes out the header???
            String proffieDirName = proffieFiles.get(0).getParent().getFileName().toString();
// logger.info("((((((((((((( chainConvertSoundFont Starting second_loop_. Stashing originalSourceDirName = " + originalSourceDirName);
// logger.info("((((((((((((( sending  sourceDirName as " + proffieDirName);
            // Second Conversion Loop: PROFFIE to Final Target
            convertSounds(sessionId, BoardType.PROFFIE, tgtBoardType, tempDirName, false, proffieDirName);
            second_loop_ = !second_loop_;
        } else {
            // Direct Conversion (including Proffie to Proffie)
            convertSounds(sessionId, srcBoardType, tgtBoardType, tempDirName, optimize, sourceDirName);
        }
    }

    public void removeOriginalDirectory(String originalDirName, String tempDirName) {
        Path originalDir = Paths.get(tempDirName, originalDirName);
        try {
            Files.walk(originalDir)
                 .sorted(Comparator.reverseOrder())  // Important to delete child before parent
                 .forEach(path -> {
                     try {
                         Files.deleteIfExists(path);
                     } catch (IOException e) {
                         e.printStackTrace();
                     }
                 });
        } catch (IOException e) {
            e.printStackTrace();
        }
        logger.info("** Completed removal of Original directory: " + originalDir.toString());
    }

    public Path zipConvertedFiles(String sessionId, String tempDirName, String sourceBoard, String targetBoard) throws IOException {
        String targetSubDirPath = tempDirName + "/Converted_to_" + targetBoard;
        Path zipPath = Paths.get(tempDirName, "Converted_to_" + targetBoard + ".zip");

        // Logging the structure
        Path zipSourceDirPath = Paths.get(targetSubDirPath);
        try {
            conversionLogService.sendLogToEmitter(sessionId, "\n");
            conversionLogService.sendLogToEmitter(sessionId, "**** _Conversion_Log.txt file is included in the converted font folder. ****");
            conversionLogService.sendLogToEmitter(sessionId, "\n");
            log(sessionId, "\n");
            Files.writeString(Paths.get(zipTargetDir, "_Conversion_Log.txt"), logStringBuilder.toString());
        } catch (IOException e) {
            System.err.println("Failed to write log: " + e.getMessage());
        // logger.info(p.toString());
        }
        logger.info("** Zipping files from directory: " + zipSourceDirPath);

        try (FileSystem zipFs = FileSystems.newFileSystem(zipPath, Map.of("create", "true"))) {
            Files.walk(zipSourceDirPath)
                .filter(Files::isRegularFile)
                .forEach(sourceFilePath -> {
                try {
                        Path relativePathInZip = zipSourceDirPath.relativize(sourceFilePath);
                        String modifiedPathInZip = relativePathInZip.toString().replaceFirst(
                            "^([^/]+)", "$1_" + targetBoard);
                        Path pathInZip = zipFs.getPath("/", modifiedPathInZip);
                        Files.createDirectories(pathInZip.getParent());

                        Files.copy(sourceFilePath, pathInZip, StandardCopyOption.REPLACE_EXISTING);
                    } catch (IOException e) {
                    e.printStackTrace();
                        System.err.println("Error zipping file: " + sourceFilePath);
                }
            });

        } catch (IOException e) {
            e.printStackTrace();
            throw new IOException("Error encountered during zip operation: " + e.getMessage());
        }
        logger.info("** ZIP file created at: " + zipPath);
        return zipPath;
    }
}
