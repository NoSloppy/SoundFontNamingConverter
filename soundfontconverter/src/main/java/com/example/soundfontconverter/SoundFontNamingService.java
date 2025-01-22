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
import org.springframework.web.multipart.MultipartFile;
import java.util.stream.StreamSupport;

@Service
public class SoundFontNamingService {

    private static final String VERSION = "4.3.3";
    private final ConversionLogService conversionLogService;
    private static final Logger logger = LoggerFactory.getLogger(SoundFontConverterController.class);
    public static final String ANSI_RESET = "\u001B[0m";
    public static final String ANSI_RED = "\u001B[31m";
    public static final String ANSI_GREEN = "\u001B[32m";
    public static final String ANSI_YELLOW = "\u001B[33m";

    @Autowired
    public SoundFontNamingService(ConversionLogService conversionLogService) {
        this.conversionLogService = conversionLogService;
    }

    enum BoardType {
        CFX,
        GOLDEN_HARVEST,
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
    private boolean initialCleanupDone = false;
    private static final String PROFFIE_ADDS_PATH = "./inis";
    private static final String VERSO_ADDS_PATH = "./Verso_Blast";
    private static final String GOLDEN_HARVEST_ADDS_PATH = "./GOLDEN_HARVEST_settings";
    private static final Map<String, String> CFX_TO_PROFFIE = new HashMap<>();
    private static final Map<String, String> CFX_TO_VERSO = new HashMap<>();
    private static final Map<String, String> GOLDEN_HARVEST_TO_PROFFIE = new HashMap<>();
    private static final Map<String, String> PROFFIE_TO_CFX = new HashMap<>();
    private static final Map<String, String> PROFFIE_TO_GOLDEN_HARVEST = new HashMap<>();
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
        safeLoadMappingsFromCSV("./CSV/PROFFIE_TO_CFX.csv", PROFFIE_TO_CFX);
        safeLoadMappingsFromCSV("./CSV/GOLDEN_HARVEST_TO_PROFFIE.csv", GOLDEN_HARVEST_TO_PROFFIE);
        safeLoadMappingsFromCSV("./CSV/PROFFIE_TO_GOLDEN_HARVEST.csv", PROFFIE_TO_GOLDEN_HARVEST);
        safeLoadMappingsFromCSV("./CSV/VERSO_TO_PROFFIE.csv", VERSO_TO_PROFFIE);
        safeLoadMappingsFromCSV("./CSV/PROFFIE_TO_VERSO.csv", PROFFIE_TO_VERSO);
        safeLoadMappingsFromCSV("./CSV/XENO3_TO_PROFFIE.csv", XENO3_TO_PROFFIE);
        safeLoadMappingsFromCSV("./CSV/PROFFIE_TO_XENO3.csv", PROFFIE_TO_XENO3);
    // ... and so on for other mappings ...

        soundMappings.put(BoardType.getKey(BoardType.CFX, BoardType.PROFFIE), CFX_TO_PROFFIE);
        soundMappings.put(BoardType.getKey(BoardType.PROFFIE, BoardType.CFX), PROFFIE_TO_CFX);
        soundMappings.put(BoardType.getKey(BoardType.GOLDEN_HARVEST, BoardType.PROFFIE), GOLDEN_HARVEST_TO_PROFFIE);
        soundMappings.put(BoardType.getKey(BoardType.PROFFIE, BoardType.GOLDEN_HARVEST), PROFFIE_TO_GOLDEN_HARVEST);
        soundMappings.put(BoardType.getKey(BoardType.VERSO, BoardType.PROFFIE), VERSO_TO_PROFFIE);
        soundMappings.put(BoardType.getKey(BoardType.PROFFIE, BoardType.VERSO), PROFFIE_TO_VERSO);
        soundMappings.put(BoardType.getKey(BoardType.XENO3, BoardType.PROFFIE), XENO3_TO_PROFFIE);
        soundMappings.put(BoardType.getKey(BoardType.PROFFIE, BoardType.XENO3), PROFFIE_TO_XENO3);


      // Reverse Mapping first so actual mappings will override

        // CFX to Proffie mapping
        for (Map.Entry<String, String> entry : PROFFIE_TO_CFX.entrySet()) {
            CFX_TO_PROFFIE.putIfAbsent(entry.getValue(), entry.getKey());
        }
        // Golden Harvest to Proffie mapping
        for (Map.Entry<String, String> entry : PROFFIE_TO_GOLDEN_HARVEST.entrySet()) {
            GOLDEN_HARVEST_TO_PROFFIE.putIfAbsent(entry.getValue(), entry.getKey());
        }
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
            logger.error(ANSI_RED + "Exception occurred: " + ex.getClass().getSimpleName() + " - " + ex.getMessage() + ANSI_RESET);
        }
    }

    private static void copyFile(Path sourcePath, Path targetPath) {
        try {
            Files.copy(sourcePath, targetPath, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException ex) {
            logger.error(ANSI_RED + "Error copying file from " + sourcePath + " to " + targetPath + ANSI_RESET);
            logger.error(ANSI_RED + "Exception occurred: " + ex.getClass().getSimpleName() + " - " + ex.getMessage() + ANSI_RESET);
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

    // private boolean isSameAltDirectory(String prefix, String currentAltDirName, Map<String, String> lastAltDirForPrefix) {
    //     String lastAltDir = lastAltDirForPrefix.getOrDefault(prefix, "");
    //     lastAltDirForPrefix.put(prefix, currentAltDirName); // Update the map with the current alt directory
    //     return lastAltDir.equals(currentAltDirName);
    // }

    private void convertSounds(String sessionId, BoardType srcBoardType, BoardType tgtBoardType, String tempDirName, boolean optimizeCheckbox, String sourceDirName, boolean applyHighPass) throws IOException {
        soundCounter.clear();
        String key = BoardType.getKey(srcBoardType, tgtBoardType);
        String effectiveSourceDirName = (is_chained_ && second_loop_) ? originalSourceDirName : sourceDirName;
        Map<String, String> lastAltDirForPrefix = new HashMap<>(); // Declare this map at the beginning of your method
        

        logger.info("--------------------------------------------------");

        if (is_chained_) {  // means neither source nor target boards are PROFFIE
            if (!second_loop_) {
                logger.info("** First step: Renaming " + sourceDirName + " from " + srcBoardType + " to " + tgtBoardType);
                logger.info("** Second step: Renaming from " + tgtBoardType + " to " + sourceDirName + "_" + realTargetBoard);
                logger.info("** Last step: Zipping " + sourceDirName + "_" + realTargetBoard + " into RENAMED_to_" + realTargetBoard + ".zip");
                logger.info(" ");
            }
        } else {
            logger.info("** First step: Converting " + sourceDirName + " from " + srcBoardType + " to " + tgtBoardType);
            logger.info("** Last step: Zipping " + sourceDirName + "_" + tgtBoardType + " into RENAMED_to_" + tgtBoardType + ".zip");
            logger.info(" ");
        }

        // Include a special case for Golden Harvest output directory naming
        String shortTargetDir = "Renamed_to_" + tgtBoardType + "/" + 
                                   (tgtBoardType == BoardType.GOLDEN_HARVEST ? "sound1 - " : "") + 
                                   sourceDirName;
        Path targetDirPath = Paths.get(tempDirName, shortTargetDir);
        Path extrasDirPath = targetDirPath.resolve("extras");
        Path tracksDirPath = targetDirPath.resolve("tracks");

        // Prepare Log file
        ensureDirectoryExists(targetDirPath);
        String currentDate = new SimpleDateFormat("MMM dd, yyyy HH:mm:ss").format(new Date());


        if (!is_chained_) {
            logger.info( "------------------------------------------------");
            conversionLogService.sendLogToEmitter(sessionId, "---------------------------------------------------------------------\n");
            logStringBuilder.append( "------------------------------------------------\n");
            log(sessionId, "Renamed with Sound Font Naming Converter " + VERSION);
            log(sessionId, "Brian Conner a.k.a NoSloppy");
            log(sessionId, currentDate);
            logger.info(" ");
            conversionLogService.sendLogToEmitter(sessionId, "\n");
            logStringBuilder.append("\n");
            log(sessionId, "Converting: " + sourceDirName + " from " + srcBoardType + " to " + tgtBoardType);
            if (tgtBoardType == BoardType.PROFFIE) log(sessionId, "Optimized for Fat32 performance: " + (optimizeCheckbox ? "Yes" : "No"));
            logger.info(" ");
            conversionLogService.sendLogToEmitter(sessionId, "\n");
            logStringBuilder.append("\n");
        } else if (!second_loop_) {
            logger.info( "------------------------------------------------");
            logger.info( "Renamed with Sound Font Naming Converter " + VERSION);
            logger.info( "Brian Conner a.k.a NoSloppy");
            logger.info( currentDate);
            logger.info(" ");
            logger.info( "Converting: " + sourceDirName + " from " + srcBoardType + " to " + tgtBoardType);
            if (tgtBoardType == BoardType.PROFFIE) logger.info( "Optimized for Fat32 performance: " + (optimizeCheckbox ? "Yes" : "No"));
            logger.info(" ");
        } else {
            conversionLogService.sendLogToEmitter(sessionId, "---------------------------------------------------------------------\n");
            conversionLogService.sendLogToEmitter(sessionId, "Renamed with Sound Font Naming Converter " + VERSION);
            conversionLogService.sendLogToEmitter(sessionId, "Brian Conner a.k.a NoSloppy");
            conversionLogService.sendLogToEmitter(sessionId, currentDate);
            conversionLogService.sendLogToEmitter(sessionId, "\n");
            conversionLogService.sendLogToEmitter(sessionId, "Converting: " + effectiveSourceDirName + " from " + originalSourceBoard + " to " + tgtBoardType);
            logger.info( "Converting: " + sourceDirName + " from " + srcBoardType + " to " + tgtBoardType);
            if (tgtBoardType == BoardType.PROFFIE) conversionLogService.sendLogToEmitter(sessionId, "Optimized for Fat32 performance: " + (optimizeCheckbox ? "Yes" : "No"));
            conversionLogService.sendLogToEmitter(sessionId, "\n");

            logStringBuilder.append( "------------------------------------------------\n");
            logStringBuilder.append( "Renamed with Sound Font Naming Converter " + VERSION + "\n");
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
            // In the second loop, adjust the path to point to the renamed files
            fullPath = Paths.get(tempDirName, "Renamed_to_PROFFIE", sourceDirName);
        } else {
            // In the first loop, or non-chained conversions
            fullPath = Paths.get(tempDirName, sourceDirName);
        }

        // Main sound conversion
        try (Stream<Path> paths = Files.walk(fullPath)) {
            Map<String, Integer> fileNameCounter = new HashMap<>();
            Map<String, Integer> altDirCountMap = new HashMap<>(); // This will store counts in the format "altDirName_prefix"
            Map<String, Integer> existAsNumbered = new HashMap<>();

            paths.filter(Files::isRegularFile)
            .filter(path -> !path.getFileName().toString().startsWith("."))
            .sorted((path1, path2) -> {
                String file1 = path1.getFileName().toString().toLowerCase();
                String file2 = path2.getFileName().toString().toLowerCase();
                // Check for purely numeric filenames
                boolean file1IsNumeric = file1.matches("\\d+\\.wav$");
                boolean file2IsNumeric = file2.matches("\\d+\\.wav$");

                if (file1IsNumeric && !file2IsNumeric) {
                    return -1; // Prioritize file1 if it is numeric and file2 is not
                } else if (!file1IsNumeric && file2IsNumeric) {
                    return 1; // Prioritize file2 if it is numeric and file1 is not
                }
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
                    logger.info( ":----------------------------------------------> ");  // divider between each file
                    String fileName = path.getFileName().toString();
                    String originalFileName = fileName;
                    Path outputPath = null;
                    boolean isAltDirectory = false;
                    boolean wasAudioConverted = false;
                    boolean wasMetadataStripped = false;
                    String parentDirName = path.getParent().getFileName().toString().toLowerCase();
                    int number = fileName.matches(".*\\d+\\.wav$") ? Integer.parseInt(fileName.replaceAll("\\D+", "")) : 1;
                    String originalFilename = originalFilenames.getOrDefault(path.getFileName().toString(), path.getFileName().toString());
                    Path relativeXtraPath = targetDirPath.relativize(path);
                    String relativeXtraPathStr = relativeXtraPath.toString();
                    Path destinationXtraPath = null;
                    // Extract the relative part of the path for the source, excluding the top-level directory
                    String sourcePathForLog = path.subpath(2, path.getNameCount()).toString();// String logCategory = "";

                        Set<String> knownTracks = new HashSet<>();
                        try (Stream<String> stream = Files.lines(Paths.get("./known_tracks.txt"))) {
                            stream.map(String::toLowerCase).forEach(knownTracks::add);
                        } catch (IOException e) {
                            logger.error(ANSI_RED + "Problem reading map from ./known_tracks.txt " + e.getMessage() + ANSI_RESET);
                        }

                    // Right off the bat, let's move non-wav files directly to the target folder
                    if (!fileName.endsWith(".wav") && !fileName.endsWith(".mp3") && !fileName.endsWith(".mp4")) {
                        Path nonWavFilePath = targetDirPath.resolve(fileName);
                        copyFile(path, nonWavFilePath);
                        log(sessionId, "- Moved non-wav file -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + fileName);
                        return;
                    }

                    // Convert to lowercase only if the file is a .wav file
                    if (fileName.toLowerCase().endsWith(".wav")) {
                        fileName = fileName.toLowerCase();
                    }


                    // Check and convert input file to correct wav file if needed
                    if (!is_chained_ || is_chained_ && second_loop_) {
                        File inputFile = path.toFile();
                        try {
                            wasAudioConverted = false;
                            wasMetadataStripped = false;

                            if (fileName.toLowerCase().endsWith(".mp3") || fileName.toLowerCase().endsWith(".mp4")) {
                                // Convert MP3 or MP4 to WAV
                                wasAudioConverted = AudioConverter.convertToWavIfNeeded(inputFile, applyHighPass); // <----- ADDED applyHighPass
                                if (wasAudioConverted) {
                                    fileName = fileName.replaceAll("\\.mp3$|\\.mp4$", ".wav");
                                    path = Paths.get(inputFile.getParent(), fileName);
                                }
                            }

                            // Process the WAV file to ensure it meets the desired format
                            if (fileName.toLowerCase().endsWith(".wav")) {
                                wasAudioConverted = AudioConverter.convertToWavIfNeeded(path.toFile(), applyHighPass); // <----- ADDED applyHighPass
                            // Check and strip metadata
                                wasMetadataStripped = AudioConverter.stripMetadataIfPresent(path.toFile());
                            }

                        } catch (UnsupportedAudioFileException | IOException e) {
                            logger.error(ANSI_RED + "Audio conversion failed: " + e.getMessage() + ANSI_RESET);
                        }
                    }

                    // Direct handling for file names on the known_tracks.txt list, and/or otherwise containing "track", "theme", or "song"
                    if (knownTracks.contains(fileName.toLowerCase())
                        || fileName.toLowerCase().contains("track")
                        || fileName.toLowerCase().contains("theme")
                        || fileName.toLowerCase().contains("song")
                        || fileName.toLowerCase().contains("music")) {
                        if (tgtBoardType != BoardType.XENO3) {
                            Path targetFile = tracksDirPath.resolve(originalFileName); // Use original file name case.
                            ensureDirectoryExists(tracksDirPath); // Ensure the tracks directory exists
                            copyFile(path, targetFile); // Copy the file

                            if (knownTracks.contains(fileName.toLowerCase()) || (!fileName.toLowerCase().contains("track") && !relativeXtraPathStr.matches("(?i).*track.*$"))) {
                                log(sessionId, "(⌐■_■) This looks like a track file.");
                            }
                            log(sessionId, "- Moved track file: " + sourcePathForLog + " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/tracks/" + originalFileName);
                        } else {
                            log(sessionId, "Xeno3 doesn't use tracks subfolders. Putting file in font root.");
                        }
                        return; // Exit early since this file has been handled
                    }
                    // Determine if the path suggests an "extras" or "tracks" destination
                    if (relativeXtraPathStr.matches("(?i).*(bonus|extras?).*$")) {
                        destinationXtraPath = extrasDirPath;
                    }
                    if (relativeXtraPathStr.matches("(?i).*track.*$")) {
                        destinationXtraPath = tracksDirPath;
                    }


                    // Logic to find the key directory and handle the path from there
                    if (destinationXtraPath != null && !(tgtBoardType == BoardType.XENO3)) {
                        int keyDirIndex = -1;
                        for (int i = 0; i < relativeXtraPath.getNameCount(); i++) {
                            String component = relativeXtraPath.getName(i).toString().toLowerCase();
                            if (component.contains("track") || component.contains("extra") || component.contains("bonus")) {
                                keyDirIndex = i;
                                break; // Find the first occurrence and break
                            }
                        }

                        Path finalXtraPath;
                        if (keyDirIndex != -1) {
                            // Resolve the subpath from the key directory to maintain the structure
                            Path subpathFromKeyDir = relativeXtraPath.subpath(keyDirIndex + 1, relativeXtraPath.getNameCount());
                            finalXtraPath = destinationXtraPath.resolve(subpathFromKeyDir);
                        } else {
                            // If no key directory is found in the path, directly use the file name
                            finalXtraPath = destinationXtraPath.resolve(fileName);
                        }

                    // log(sessionId, "Final destination path: " + finalXtraPath.toString());
                        ensureDirectoryExists(finalXtraPath.getParent());
                        copyFile(path, finalXtraPath);

                        // Log handling
                        String targetPathForLog = finalXtraPath.toString().substring(finalXtraPath.toString().indexOf(shortTargetDir) + shortTargetDir.length() + 1).replaceFirst("^/", "");
                        String fileCategory = finalXtraPath.startsWith(tracksDirPath) ? "track" : "extra or bonus";
                    // log(sessionId, "Logging as: Source - " + sourcePathForLog + ", Target - " + targetPathForLog);
                        String logMessage = String.format("- Moved %s file: %s -> %s/%s", fileCategory, sourcePathForLog, effectiveSourceDirName + "_" + tgtBoardType.toString(), targetPathForLog);
                        log(sessionId, logMessage);
                        return;
                    }




                    boolean isNumericName = fileName.matches("\\d+\\.wav$");

                    String baseName = "";

                    if (isNumericName) {
                        if (tgtBoardType == BoardType.PROFFIE) {
                            // Copy the file over as-is for PROFFIE target board
                            Path relativePath = path.subpath(2, path.getNameCount()); // Adjust the starting index if needed
                            Path targetFilePath = targetDirPath.resolve(relativePath);
                            ensureDirectoryExists(targetFilePath.getParent());
                            copyFile(path, targetFilePath);

                            // Adjust the logging to reflect the final structure
                            String sourceFilePath = path.getParent().getFileName().toString() + "/" + path.getFileName().toString();
                            String targetFilePathString = effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + relativePath.toString();
                            log(sessionId, "- Moved numeric file " + sourceFilePath + " -> " + targetFilePathString);
                            // Update the existAsNumbered map
                            int currentNumber = extractNumber(fileName);
                            existAsNumbered.put(relativePath.getParent().getFileName().toString(), currentNumber);
                            return; // Skip further processing for PROFFIE numeric files
                        } else {
                            // Traverse up the path to find the first non-numeric directory for non-PROFFIE target boards
                            Path currentPath = path.getParent();
                            String firstNonNumericPart = "";
                            while (currentPath.getNameCount() > 0) {
                                String part = currentPath.getName(currentPath.getNameCount() - 1).toString();
                                if (!part.matches("\\d+")) {
                                    firstNonNumericPart = part;
                                    break;
                                }
                                currentPath = currentPath.getParent();
                            }

                            baseName = firstNonNumericPart.isEmpty() ? parentDirName : firstNonNumericPart + ".wav";
                            // // Update the existAsNumbered map for non-PROFFIE targets
                            // int currentNumber = extractNumber(fileName);
                            // existAsNumbered.put(firstNonNumericPart.isEmpty() ? parentDirName : firstNonNumericPart, currentNumber);
                        }
                    } else {
                        // Regular expression to extract baseName for non-numeric files
                        baseName = fileName.replaceAll("( \\(\\d+\\)| \\d+|\\(\\d+\\)|\\d+)+\\.wav$", ".wav");
                    }
                    // If we're doing Proffie to Proffie, keep the baseName as is
                    String convertedBaseName = (mapping == null) ? baseName : mapping.getOrDefault(baseName, baseName);

                    Path originalPath;
                    Path newPath;
                    String altDirName = "";
                    int altCount = 0;

                    if (convertedBaseName != null) {
                        int count = soundCounter.getOrDefault(convertedBaseName, 0) + 1;
                        soundCounter.put(convertedBaseName, count);

                        String prefix = (convertedBaseName.contains("."))
                                        ? convertedBaseName.substring(0, convertedBaseName.lastIndexOf('.'))
                                        : convertedBaseName;

                        String formattedCount = String.valueOf(count);
                        String formattedAltCount = "";

                        Set<String> loggedFiles = new HashSet<>();  // flag to prevent multi logging of poweroff case 


                        if (tgtBoardType == BoardType.CFX) {
                            String newPrefix;
                            int currentCounter;
                            String switchKey = convertedBaseName.toLowerCase().replaceAll("\\.wav$", "");
                            String commonKey;
                            switch (switchKey) {
                                // Adding pwroff2 regardless of only 1 input file.
                                // CFX requires a "pwroff2" file for retractions when blade is moving.
                                // So if only a single "in.wav" is received, it is made into both "poweroff" and "pwroff2" to fulfill the requirement.
                                // If a second "in" sound comes through, then it is used for "pwroff2" instead, replacing the first instance created from "in1".
                                // Any additional "in" sounds are then made as continued sequential "poweroff"s.
                                case "poweroff":
                                    commonKey = "pwroff";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    if (currentCounter == 1) {
                                        // Create poweroff.wav
                                        Path poweroffPath = targetDirPath.resolve("poweroff.wav");
                                        copyFile(path, poweroffPath);
                                        log(sessionId, "Renamed: " + path.getFileName() + " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + poweroffPath.getFileName());
                                        // Also create pwroff2.wav
                                        Path pwroff2Path = targetDirPath.resolve("pwroff2.wav");
                                        copyFile(path, pwroff2Path);
                                        log(sessionId, "- Also create pwroff2.wav: " + path.getFileName() + " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + pwroff2Path.getFileName());
                                    } else if (currentCounter == 2) {
                                        // Overwrite pwroff2.wav
                                        Path pwroff2Path = targetDirPath.resolve("pwroff2.wav");
                                        copyFile(path, pwroff2Path);
                                        log(sessionId, "- Updated pwroff2.wav: " + path.getFileName() + " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + pwroff2Path.getFileName());
                                    } else {
                                        // Follow original pattern for subsequent files
                                        newPrefix = "poweroff" + (currentCounter - 1);
                                        Path poweroffPath = targetDirPath.resolve(newPrefix + ".wav");
                                        copyFile(path, poweroffPath);
                                        // Log the file creation
                                        log(sessionId, "Renamed: " + path.getFileName() + " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + poweroffPath.getFileName());
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

                                // CFX only uses one font file, so any additional become boots.
                                case "font":
                                    commonKey = "font";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    if (currentCounter == 1) {
                                        outputPath = targetDirPath.resolve("font.wav");
                                    } else {
                                        log(sessionId, "-- CFX only uses one font file, so any additional become boots.");
                                        int nextBootCounter = fileNameCounter.getOrDefault("boot", 1);
                                        outputPath = targetDirPath.resolve("boot" + (nextBootCounter == 1 ? "" : nextBootCounter) + ".wav");
                                        fileNameCounter.put("boot", nextBootCounter + 1);
                                    }
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    break;

                                // These get no number on the first file, then sequence the rest staring from 2
                                case "boot":
                                    commonKey = "boot";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    outputPath = targetDirPath.resolve("boot" + (currentCounter == 1 ? "" : currentCounter) + ".wav");
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    break;
                                case "poweron":
                                    commonKey = "poweron";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    outputPath = targetDirPath.resolve(convertedBaseName.substring(0, convertedBaseName.length() - 4) + (currentCounter == 1 ? "" : currentCounter) + ".wav");
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    break;
                                case "lockup":
                                    commonKey = "lockup";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    outputPath = targetDirPath.resolve(convertedBaseName.substring(0, convertedBaseName.length() - 4) + (currentCounter == 1 ? "" : currentCounter) + ".wav");
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    break;
                                case "blaster":
                                    commonKey = "blaster";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    outputPath = targetDirPath.resolve(convertedBaseName.substring(0, convertedBaseName.length() - 4) + (currentCounter == 1 ? "" : currentCounter) + ".wav");
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    break;
                                case "drag":
                                    commonKey = "drag";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    outputPath = targetDirPath.resolve(convertedBaseName.substring(0, convertedBaseName.length() - 4) + (currentCounter == 1 ? "" : currentCounter) + ".wav");
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    break;
                                case "force":
                                    commonKey = "force";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    outputPath = targetDirPath.resolve(convertedBaseName.substring(0, convertedBaseName.length() - 4) + (currentCounter == 1 ? "" : currentCounter) + ".wav");
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    break;
                                case "color":
                                    commonKey = "color";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    outputPath = targetDirPath.resolve(convertedBaseName.substring(0, convertedBaseName.length() - 4) + (currentCounter == 1 ? "" : currentCounter) + ".wav");
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    break;

                                default:
                                    currentCounter = fileNameCounter.getOrDefault(switchKey, 1);
                                    outputPath = targetDirPath.resolve(convertedBaseName.substring(0, convertedBaseName.length() - 4) + currentCounter + ".wav");
                                    fileNameCounter.put(switchKey, currentCounter + 1);
                                    break;
                            }


                        } else if (tgtBoardType == BoardType.PROFFIE) {
                            // Check if a numeric file with this prefix has already been processed
                            if (existAsNumbered.containsKey(prefix)) {
                                int nextNumber = existAsNumbered.getOrDefault(prefix, 0) + 1;
                                Path numericFileSubDirPath = targetDirPath.resolve(prefix);
                                ensureDirectoryExists(numericFileSubDirPath);

                                // Use only the number for the file name, not the prefix
                                Path numericFilePath = numericFileSubDirPath.resolve(String.format("%04d.wav", nextNumber));
                                copyFile(path, numericFilePath);
                                log(sessionId, "- Moved non-numeric file as next numeric -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + prefix + "/" + numericFilePath.getFileName());
                                existAsNumbered.put(prefix, nextNumber);
                                return; // Skip further processing for this file
                            }
                            if (prefix.equals("tr")) {
                                // Special handling for "tr" files
                                formattedCount = String.format("%02d", count - 1); // Subtract 1 for offset
                            } else if (prefix.length() > 6 && count == 1 && soundCounter.containsKey(baseName)) {
                                formattedCount = String.valueOf(count);
                            } else {
                                formattedCount = (prefix.length() > 6) ? String.valueOf(count) : String.format("%02d", count);
                            }

                            if (optimizeCheckbox) {
                                // Handle Alt directories as their own environment
                                Path currentPath = path;
                                while (currentPath.getParent() != null) {
                                    String dirName = currentPath.getParent().getFileName().toString();
                                   if (dirName.toLowerCase().contains("alt")) {
                                        isAltDirectory = true;
                                        altDirName = dirName;
                                        break;
                                    }
                                    currentPath = currentPath.getParent();
                                }
                                Path baseDirPath = targetDirPath.resolve(altDirName);
                                if (isAltDirectory) {
                                    // logger.info("** Alt file found");
                                    ensureDirectoryExists(baseDirPath);
                                    // mapping out count for alt files
                                    String altDirPrefixKey = altDirName + "_" + prefix;
                                    altCount = altDirCountMap.getOrDefault(altDirPrefixKey, 0) + 1;
                                    altDirCountMap.put(altDirPrefixKey, altCount);
                                    if (prefix.equals("tr")) {
                                        // Special handling for "tr" files
                                        formattedAltCount = String.format("%02d", altCount - 1); // Subtract 1 for offset
                                    } else if (prefix.length() > 6 && altCount == 1 && soundCounter.containsKey(baseName)) {
                                        formattedAltCount = String.valueOf(altCount);
                                    } else {
                                        formattedAltCount = (prefix.length() > 6) ? String.valueOf(altCount) : String.format("%02d", altCount);
                                    }
                                    outputPath = (altCount == 1) ? baseDirPath.resolve(prefix + (prefix.equals("tr") ? "00.wav" : ".wav")) 
                                                                   : baseDirPath.resolve(prefix).resolve(prefix + formattedAltCount + ".wav");

                                    if (altCount == 2) {
                                        originalPath = baseDirPath.resolve(prefix + (prefix.equals("tr") ? "00.wav" : ".wav"));
                                        newPath = baseDirPath.resolve(prefix).resolve(prefix + (prefix.equals("tr") ? "00.wav" : (prefix.length() > 6 ? "1.wav" : "01.wav")));
                                        ensureDirectoryExists(baseDirPath.resolve(prefix));
                                        Files.move(originalPath, newPath, StandardCopyOption.REPLACE_EXISTING);
                                        log(sessionId, "- Numbered and moved first 'alt' file to subdirectory: ");
                                        log(sessionId, effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + altDirName + "/" + prefix + (prefix.equals("tr") ? "00.wav" : ".wav") +
                                                        " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + altDirName + "/" + prefix + "/" + newPath.getFileName());
                                    }
                                } else {
                                    // Process non-alt files
                                    outputPath = (count == 1) ? targetDirPath.resolve(prefix + (prefix.equals("tr") ? "00.wav" : ".wav")) 
                                                                : targetDirPath.resolve(prefix).resolve(prefix + formattedCount + ".wav");

                                    // Handle moving of the first file for non-alt directories
                                    if (count == 2) {
                                        originalPath = targetDirPath.resolve(prefix + (prefix.equals("tr") ? "00.wav" : ".wav"));
                                        newPath = targetDirPath.resolve(prefix).resolve(prefix + (prefix.equals("tr") ? "00.wav" : (prefix.length() > 6 ? "1.wav" : "01.wav")));
                                        ensureDirectoryExists(targetDirPath.resolve(prefix));
                                        Files.move(originalPath, newPath, StandardCopyOption.REPLACE_EXISTING);
                                        log(sessionId, "- Numbered and moved first file to subdirectory: ");
                                        log(sessionId, effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + prefix + (prefix.equals("tr") ? "00.wav" : ".wav") +
                                                                        " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + prefix + "/" + newPath.getFileName());
                                    }
                                }  // if (isAltDirectory)
                            } else { // not optimize_checkbox. alt folders would only exist in a PROFFIE souce font. Optimize is assumed.
                                outputPath = targetDirPath.resolve((count > 1 ? prefix + formattedCount : prefix) + ".wav");

                                if (count == 2) {
                                    originalPath = targetDirPath.resolve(prefix + ".wav");
                                   newPath = targetDirPath.resolve(prefix + (prefix.length() > 6 ? "1.wav" : "01.wav"));
                                    Files.move(originalPath, newPath, StandardCopyOption.REPLACE_EXISTING);
                                    // FOR LOGGING PURPOSES
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
                                        // log is ok here. "Renamed_to_PROFFIE" won't show in user logs if is_chained_
                                        log(sessionId, logPathPrefix + "/" + prefix + ".wav" + " -> " + logPathPrefix + "/" + newPath.getFileName());
                                }
                            }



                        } else if (tgtBoardType == BoardType.VERSO && convertedBaseName.equals("font.wav")) {
                            String commonKey = "font";
                            int currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                            fileNameCounter.put(commonKey, currentCounter + 1);

                            if (currentCounter == 1) {
                                originalPath = targetDirPath.resolve("font.wav");
                                copyFile(path, originalPath);
                                logger.info("Renamed: " + sourceDirName + " " + originalFilename + " -> temp " + path.getFileName().toString() + " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + path.getFileName().toString());
                                conversionLogService.sendLogToEmitter(sessionId, "Renamed: " + sourceDirName + " " + path.getFileName().toString() + " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + path.getFileName().toString());
                                logStringBuilder.append( "Renamed: " + sourceDirName + " " + path.getFileName().toString() + " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + path.getFileName().toString() + "\n");
                            // } else {  // Process additional font.wavs as boot.wavs
                            //     log(sessionId, "-- Verso only uses one font file, so any additional become boot.wav files.");
                            //     int nextBootCounter = fileNameCounter.getOrDefault("boot", 1);
                            //     originalPath = targetDirPath.resolve("boot" + (nextBootCounter == 1 ? "" : nextBootCounter) + ".wav");
                            //     fileNameCounter.put("boot", nextBootCounter + 1);
                            //     copyFile(path, originalPath);
                            //     logger.info("Renamed: " + sourceDirName + " " + originalFilename + " -> temp " + path.getFileName().toString() + " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/boot" + (nextBootCounter == 1 ? "" : nextBootCounter) + ".wav");
                            //     conversionLogService.sendLogToEmitter(sessionId, "Renamed: " + sourceDirName + " " + path.getFileName().toString() + " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/boot" + (nextBootCounter == 1 ? "" : nextBootCounter) + ".wav");
                            //     logStringBuilder.append("Renamed: " + sourceDirName + " " + path.getFileName().toString() + " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/boot" + (nextBootCounter == 1 ? "" : nextBootCounter) + ".wav\n");
                            // }
                            } else {  // Process additional font.wavs as fontALT.wavs
                                log(sessionId, "-- Verso only uses one font file, so any additional become fontALT files.");
                                originalPath = targetDirPath.resolve(commonKey + "ALT" + (currentCounter - 1) + ".wav");
                                copyFile(path, originalPath);
                                logger.info("Renamed: " + sourceDirName + " " + originalFilename + " -> temp " + path.getFileName().toString() + " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + commonKey + "ALT" + (currentCounter - 1) + ".wav");
                                conversionLogService.sendLogToEmitter(sessionId, "Renamed: " + sourceDirName + " " + path.getFileName().toString() + " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + commonKey + "ALT" + (currentCounter - 1) + ".wav");
                                logStringBuilder.append("Renamed: " + sourceDirName + " " + path.getFileName().toString() + " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + commonKey + "ALT" + (currentCounter - 1) + ".wav\n");
                            }
                            return;
                        } else if (tgtBoardType == BoardType.GOLDEN_HARVEST && convertedBaseName.equals("font.wav")) {
                            String commonKey = "font";
                            int currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                            fileNameCounter.put(commonKey, currentCounter + 1);

                            if (currentCounter == 1) {
                                originalPath = targetDirPath.resolve(commonKey + ".wav");
                                copyFile(path, originalPath);
                                logger.info("Renamed: " + sourceDirName + " " + originalFilename + " -> temp " + path.getFileName().toString() + " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + commonKey + ".wav");
                                conversionLogService.sendLogToEmitter(sessionId, "Renamed: " + sourceDirName + " " + path.getFileName().toString() + " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + commonKey + ".wav");
                                logStringBuilder.append( "Renamed: " + sourceDirName + " " + path.getFileName().toString() + " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + commonKey + ".wav\n");
                            } else {
                                log(sessionId, "-- Golden Harvest only uses one font file, so any additional become fontALT files.");
                                originalPath = targetDirPath.resolve(commonKey + "ALT" + (currentCounter - 1) + ".wav");
                                copyFile(path, originalPath);
                                logger.info("Renamed: " + sourceDirName + " " + originalFilename + " -> temp " + path.getFileName().toString() + " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + commonKey + "ALT" + (currentCounter - 1) + ".wav");
                                conversionLogService.sendLogToEmitter(sessionId, "Renamed: " + sourceDirName + " " + path.getFileName().toString() + " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + commonKey + "ALT" + (currentCounter - 1) + ".wav");
                                logStringBuilder.append("Renamed: " + sourceDirName + " " + path.getFileName().toString() + " -> " + effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + commonKey + "ALT" + (currentCounter - 1) + ".wav\n");
                            }
                            return;
                        } else if (tgtBoardType == BoardType.XENO3) {
                            outputPath = targetDirPath.resolve(prefix + " (" + count + ").wav");

                        // Don't number first file if target = PROFFIE, it might be the only one of its kind
                        } else if (count > 1 || (tgtBoardType != BoardType.PROFFIE && count == 1)) {
                            outputPath = targetDirPath.resolve(prefix + formattedCount + ".wav");

                        } else {
                            outputPath = targetDirPath.resolve(prefix + ".wav");
                        }

                    // Log for audio conversion
                    if (wasAudioConverted) {
                        if (is_chained_ && second_loop_) {
                            conversionLogService.sendLogToEmitter(sessionId, "Audio: Converting " + originalFilename + " to 44.1kHz, 16bit monaural .wav format.");
                            logStringBuilder.append( "Audio: Converting " + originalFilename + " to 44.1kHz, 16bit monaural .wav format.\n");
                        } else {
                            conversionLogService.sendLogToEmitter(sessionId, "Audio: Converting " + fileName + " to 44.1kHz, 16bit monaural .wav format.");
                            logStringBuilder.append( "Audio: Converting " + fileName + " to 44.1kHz, 16bit monaural .wav format.\n");
                        }
                    }
                    // Log for metadata stripping
                    if (wasMetadataStripped) {
                        if (is_chained_ && second_loop_) {
                            conversionLogService.sendLogToEmitter(sessionId, "Metadata stripped from: " + originalFilename);
                            logStringBuilder.append("Metadata stripped from: " + originalFilename + "\n");
                        } else {
                            conversionLogService.sendLogToEmitter(sessionId, "Metadata stripped from: " + fileName);
                            logStringBuilder.append("Metadata stripped from: " + fileName + "\n");
                        }
                    }

                        String proffieFilename = "";

                        // Store the original filename and its corresponding PROFFIE format filename
                        if (is_chained_ && !second_loop_) {
                            proffieFilename = outputPath.getFileName().toString();
                            originalFilenames.put(proffieFilename, fileName);  // Map PROFFIE format name to original filename
                        }
// Finally, we're doing something with the file. Here' we are copying it to the new target
                        if (loggedFiles.contains(path.getFileName().toString())) return;

                        copyFile(path, outputPath);

                        String targetPathLog;

                        if (is_chained_ && second_loop_) {

                            // For user logs: Retrieve the original filename using PROFFIE format name as key
                            String finalTargetFilename;

                            if (tgtBoardType == BoardType.XENO3) {
                                // Format with parenthesis for when final target XENO3 board
                                finalTargetFilename = prefix + " (" + count + ").wav";
                                targetPathLog = effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + finalTargetFilename;
                                conversionLogService.sendLogToEmitter(sessionId, "Renamed: " + originalFilename + " -> " + targetPathLog);
                                logStringBuilder.append( "Renamed: " + originalFilename + " -> " + targetPathLog + "\n");
                                logger.info("Renamed: " + sourceDirName + " " + originalFilename + " -> temp " + path.getFileName().toString() + " -> " + targetPathLog);
                            } else {
                                // target is not PROFFIE or XENO3 (so Loop 2 of chained)
                                finalTargetFilename = prefix + formattedCount + ".wav";
                                targetPathLog = effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + finalTargetFilename;
                                conversionLogService.sendLogToEmitter(sessionId, "Renamed: " + originalFilename + " -> " + targetPathLog);
                                logStringBuilder.append( "Renamed: " + originalFilename + " -> " + targetPathLog + "\n");
                                logger.info("Loop 2: Renaming temp Proffie version of:  " + path.getFileName().toString() + " -> " + targetPathLog);
                            }
                        } else {
                            if ("PROFFIE".equals(realTargetBoard)) {
                                if (isAltDirectory) {
                                    // Special handling for logging alt files
                                    // Get the relative path from the third element onwards and convert it to String for logging
                                    String sourcePathLog = path.subpath(2, path.getNameCount()).toString();
                                    String altTargetPath = altDirName + "/" 
                                                           + (altCount > 1 ? prefix + "/" : "") 
                                                           + outputPath.getFileName().toString();
                                    targetPathLog = sourceDirName + "_" + realTargetBoard + "/" + altTargetPath;
                                    log(sessionId, "Renamed: " + sourcePathLog + " -> " + targetPathLog);
                                } else {
                                    // Regular handling for non-alt files
                                    targetPathLog = count > 1 && optimizeCheckbox 
                                                    ? sourceDirName + "_" + realTargetBoard + "/" + prefix + "/" + outputPath.getFileName().toString()
                                                    : sourceDirName + "_" + realTargetBoard + "/" + outputPath.getFileName().toString();
                                    log(sessionId, "Renamed: " + path.getFileName().toString() + " -> " + targetPathLog);
                                }
                            } else if (srcBoardType == BoardType.PROFFIE) {
                                // For all non-chained conversions when source is PROFFIE
                                targetPathLog = effectiveSourceDirName + "_" + tgtBoardType.toString() + "/" + outputPath.getFileName().toString();
                                log(sessionId, "Renamed: " + path.getFileName().toString() + " -> " + targetPathLog);

                            } else {
                                // For Loop 1 of chained conversions when going to imtermediary PROFFIE
                                targetPathLog = outputPath.toString().replace(tempDirName + "/", "");
                                logger.info("Renamed: " + path.getFileName().toString() + " -> " + targetPathLog);
                            }
                        }

                    } else { // convertedBaseName = null
                        logger.info("** convertedBaseName = null. Skipped wav file without mapping: " + fileName);
                    }
                } catch (IOException e) {
                    logger.error(ANSI_RED + "An IOException occurred: " + e.getMessage() + ANSI_RESET);
                }
            });  // .forEach(path -> {
            zipTargetDir = targetDirPath.toString();
            if (!is_chained_) {
                logger.info(" ");
                conversionLogService.sendLogToEmitter(sessionId, "\n");
                logStringBuilder.append("\n");
            } else if (!second_loop_) {
                log(sessionId, "- - - - - - - - - - - - - - - - - - - - - - - -");
                log(sessionId, "Loop 2:");
                log(sessionId, "- - - - - - - - - - - - - - - - - - - - - - - -");
            }

        } catch (IOException ex) {  //// Main sound conversion try block
            logger.error(ANSI_RED + "An error occurred while reading the file: " + ex.getMessage() + ANSI_RESET);
        }

        // After processing all files, check if need to add default INIs for PROFFIE, or add blast1.wav if VERSO.
        if (!is_chained_) {  // source or target is PROFFIE
            if (tgtBoardType == BoardType.PROFFIE) {
                for (String defaultFile : new String[]{"config.ini", "smoothsw.ini"}) {
                    if (!Files.exists(targetDirPath.resolve(defaultFile)) || srcBoardType != BoardType.PROFFIE) {
                        log(sessionId, "-- Proffie needs a missing " + defaultFile + " file, so it has been added here for you.");
                        Files.copy(Paths.get(PROFFIE_ADDS_PATH, defaultFile), targetDirPath.resolve(defaultFile));
                        log(sessionId, "Added missing default file -> " + sourceDirName + "_" + realTargetBoard + "/" + defaultFile);
                    }
                }
            } else if (tgtBoardType == BoardType.VERSO) {
                logger.info( ":----------------------------------------------> ");  // divider between each file
                log(sessionId, "-- Verso uses a 'blaster firing' sound before the 'deflection' sound, so it's been added for you.");
                Files.copy(Paths.get(VERSO_ADDS_PATH, "blast1.wav"), targetDirPath.resolve("blast1.wav"));
                log(sessionId, "Added blast1.wav -> " + sourceDirName + "_" + realTargetBoard + "/blast1.wav");
            } else if (tgtBoardType == BoardType.GOLDEN_HARVEST) {
                log(sessionId, "-- Golden Harvest settings.txt file has been added for you.");
                Files.copy(Paths.get(GOLDEN_HARVEST_ADDS_PATH, "settings.txt"), targetDirPath.resolve("settings.txt"), StandardCopyOption.REPLACE_EXISTING);
                log(sessionId, "Added settings.txt -> " + sourceDirName + "_" + realTargetBoard + "/settings.txt");
            }
            logger.info(" ");
            conversionLogService.sendLogToEmitter(sessionId, "\n");
            logStringBuilder.append("\n");
            logger.info( ANSI_YELLOW + "------------------ | **** MTFBWY **** | ------------------" + ANSI_RESET);
            conversionLogService.sendLogToEmitter(sessionId, "------------------ | **** MTFBWY **** | ------------------");
            logStringBuilder.append( "------------------ | **** MTFBWY **** | ------------------\n");
            log(sessionId, " ");
            conversionLogService.sendLogToEmitter(sessionId, "**** _Conversion_Log.txt file is included in the renamed font folder. ****");
            conversionLogService.sendLogToEmitter(sessionId, "\n");
            Files.writeString(Paths.get(zipTargetDir, "_Conversion_Log.txt"), logStringBuilder.toString());
        } else if (second_loop_) {
            // Add blast1.wav for Verso board.
            if (tgtBoardType == BoardType.VERSO) {
                logger.info( ":----------------------------------------------> ");  // divider between each file
                log(sessionId, "-- Verso uses a 'blaster firing' sound before the 'deflection' sound, so it's been added for you.");
                Files.copy(Paths.get(VERSO_ADDS_PATH, "blast1.wav"), targetDirPath.resolve("blast1.wav"));
                log(sessionId, "Added blast1.wav -> " + sourceDirName + "_" + realTargetBoard + "/blast1.wav");
            }
            // Add settings.txt file for Golden Harvest board.
            if (tgtBoardType == BoardType.GOLDEN_HARVEST) {
                log(sessionId, "-- Golden Harvest settings.txt file has been added for you.");
                Files.copy(Paths.get(GOLDEN_HARVEST_ADDS_PATH, "settings.txt"), targetDirPath.resolve("settings.txt"), StandardCopyOption.REPLACE_EXISTING);
                log(sessionId, "Added settings.txt -> " + sourceDirName + "_" + realTargetBoard + "/settings.txt");
            }
            logger.info(" ");
            conversionLogService.sendLogToEmitter(sessionId, "\n");
            logStringBuilder.append("\n");
            logger.info( ANSI_YELLOW + "------------------ | **** MTFBWY **** | ------------------" + ANSI_RESET);
            conversionLogService.sendLogToEmitter(sessionId, "------------------ | **** MTFBWY **** | ------------------");
            logStringBuilder.append( "------------------ | **** MTFBWY **** | ------------------\n");
            log(sessionId, " ");

            conversionLogService.sendLogToEmitter(sessionId, "**** _Conversion_Log.txt file is included in the renamed font folder. ****");
            conversionLogService.sendLogToEmitter(sessionId, "\n");
            Files.writeString(Paths.get(zipTargetDir, "_Conversion_Log.txt"), logStringBuilder.toString());
        }

    }  // convertSounds()

    public void convertAudioIfNeeded(Path targetPath, File inputFile, Path tempDirPath, boolean applyHighPass) throws IOException {
        String filename = inputFile.getName();
        // Check if the file is a WAV, MP3, or MP4 file
        if (!filename.toLowerCase().endsWith(".wav") && 
            !filename.toLowerCase().endsWith(".mp3") && 
            !filename.toLowerCase().endsWith(".mp4")) {
            // Copy non-audio files to the target directory as is
            logger.info("Audio Format Check: " + inputFile.getName() + " is not a recognized audio file. Moving along.");
            logStringBuilder.append(inputFile.getName() + " is not a recognized audio file. Moving along.\n");
            Path newTargetPath = tempDirPath.resolve(filename);
            Files.copy(inputFile.toPath(), targetPath, StandardCopyOption.REPLACE_EXISTING);
            return;
        }

        // Process the WAV file (including those converted from MP3 or MP4)
        try {
            logger.info("Audio Format Check: " + inputFile.getName());

            // Ensure the WAV file meets the desired audio format specifications
            boolean wasAudioConverted = AudioConverter.convertToWavIfNeeded(inputFile, applyHighPass); // <----- PASS applyHighPass
            // Now check and strip metadata if present
            boolean wasMetadataStripped = AudioConverter.stripMetadataIfPresent(inputFile);

        } catch (UnsupportedAudioFileException e) {
            logger.error(ANSI_RED + "Unsupported audio file format: " + inputFile.getName(), e + ANSI_RESET);
            // Handle the exception as needed
        } catch (IOException e) {
            logger.error(ANSI_RED + "Audio conversion failed: " + inputFile.getName(), e + ANSI_RESET);
            // Handle the IOException as needed
        }

    }


    public Path zipAudioFiles(Path sourceDirPath, String zipFileName) throws IOException {
        Path zipPath = sourceDirPath.resolve(zipFileName + ".zip");

        try (FileSystem zipFs = FileSystems.newFileSystem(zipPath, Map.of("create", "true"))) {
            Files.walk(sourceDirPath)
                .filter(Files::isRegularFile)
                .filter(path -> !path.equals(zipPath)) // Exclude the zip file itself
                .forEach(sourceFilePath -> {
                    try {
                        Path relativePathInZip = sourceDirPath.relativize(sourceFilePath);
                        Path pathInZip = zipFs.getPath("/", relativePathInZip.toString());
                        Files.createDirectories(pathInZip.getParent());
                        Files.copy(sourceFilePath, pathInZip, StandardCopyOption.REPLACE_EXISTING);
                    } catch (IOException e) {
                        logger.error(ANSI_RED + "Error adding file to ZIP: " + sourceFilePath, e + ANSI_RESET);
                    }
                });
        } catch (IOException e) {
            logger.error(ANSI_RED + "Error creating ZIP file: " + zipPath, e + ANSI_RESET);
            throw e;
        }

        return zipPath;
    }


    public class MutableInt {
        public int value;
        public MutableInt(int value) {
            this.value = value;
        }
    }


    public void resetCleanupFlag() {
        initialCleanupDone = false;
    }

    public void performInitialCleanup(String tempDirName) {
        if (!initialCleanupDone) {
            cleanupTemporaryDirectory(tempDirName);
            initialCleanupDone = true;
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
                            logger.error(ANSI_RED + "Error cleaning up temporary directory: " + tempDirName, e + ANSI_RESET);
                        }
                    });
            }


        } catch (IOException e) {
            // Handle the exception, e.g., logging it.
            logger.error(ANSI_RED + "Error cleaning up temporary directory: " + tempDirName, e + ANSI_RESET);
        }
    }

    public void chainConvertSoundFont(String sessionId, String sourceBoard, String targetBoard, String tempDirName, boolean optimize, String sourceDirName, boolean applyHighPass) throws IOException {
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
            convertSounds(sessionId, srcBoardType, BoardType.PROFFIE, tempDirName, false, sourceDirName, applyHighPass); // <----- Added applyHighPass

            second_loop_ = !second_loop_;

            // Now use the renamed PROFFIE files as source for the actual target.

            Path tempProffieDir = Paths.get(tempDirName, "Renamed_to_PROFFIE");
            List<Path> proffieFiles = Files.walk(tempProffieDir)
                                           .filter(Files::isRegularFile)
                                           .collect(Collectors.toList());
            String proffieDirName = proffieFiles.get(0).getParent().getFileName().toString();
            // Second Conversion Loop: PROFFIE to Final Target
            convertSounds(sessionId, BoardType.PROFFIE, tgtBoardType, tempDirName, false, proffieDirName, applyHighPass); // <----- Added applyHighPass

            second_loop_ = !second_loop_;
        } else {
            // Direct Conversion (including Proffie to Proffie)
            convertSounds(sessionId, srcBoardType, tgtBoardType, tempDirName, optimize, sourceDirName, applyHighPass); // <----- Added applyHighPass

        }
    }

public void removeOriginalDirectory(Path directoryToDelete) {
    try {
        Files.walk(directoryToDelete)
             .sorted(Comparator.reverseOrder())
             .forEach(path -> {
                 try {
                     Files.deleteIfExists(path);
                 } catch (IOException e) {
                     logger.error(ANSI_RED + "Failed to delete path: " + path + " - " + e.getMessage() + ANSI_RESET);
                 }
             });
        logger.info("** Completed removal of directory: " + directoryToDelete);
    } catch (IOException e) {
        logger.error(ANSI_RED + "Failed to remove directory: " + directoryToDelete + " - " + e.getMessage() + ANSI_RESET);
    }
}


    public Path zipConvertedFiles(String sessionId, String tempDirName, String sourceBoard, String targetBoard) throws IOException {
        String targetSubDirPath = tempDirName + "/Renamed_to_" + targetBoard;
        Path zipPath = Paths.get(tempDirName, "Renamed_to_" + targetBoard + ".zip");

        // Logging the structure
        Path zipSourceDirPath = Paths.get(targetSubDirPath);

        // logger.info("** Zipping " + originalSourceDirName + "_" + targetBoard + " from directory: " + zipSourceDirPath);
        logger.info("** Zipping directory: " + zipSourceDirPath);

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
                    logger.error(ANSI_RED + "Error zipping file: " + sourceFilePath + ANSI_RESET);
                    e.printStackTrace();
                }
            });

        } catch (IOException e) {
            throw new IOException(ANSI_RED + "Error encountered during zip operation: " + e.getMessage() + ANSI_RESET);
        }
        logger.info("** ZIP file created at: " + zipPath);
        return zipPath;
    }
}
