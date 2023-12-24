package com.example.soundfontconverter;

import org.springframework.stereotype.Service;

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

@Service
public class SoundFontNamingService {

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
    private boolean chained = false;
    private String realTarget = "PROFFIE";
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
  //... additional board mappings can be added here

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
                System.out.println("Creating directory: " + dirPath);
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

// If no optimizeForProffie parameter is included, default optimizeForProffie to true
    private void convertSounds(BoardType sourceBoard, String sourceDir, BoardType targetBoard, String targetDir) throws IOException {
        convertSounds(sourceBoard, sourceDir, targetBoard, targetDir, true);
    }

  // This version takes the optimizeForProffie parameter. It's the main logic
    private void convertSounds(BoardType sourceBoard, String sourceDir, BoardType targetBoard, String targetDir, boolean optimizeForProffie) throws IOException {
        soundCounter.clear();
        String key = BoardType.getKey(sourceBoard, targetBoard);
        System.out.println("----------------------------------------------------------------\n.");
        if (targetBoard == BoardType.PROFFIE && realTarget == "PROFFIE") {
            System.out.println("Converting from " + sourceBoard + " to " + targetBoard + "\n.");
        } else if (targetBoard != BoardType.PROFFIE) {
            realTarget = targetBoard.toString();
        } else {   
            System.out.println("Converting from " + sourceBoard + " to " + realTarget + "\n.");
        }

        // Directory structure code here:
        String sourceDirName = new File(sourceDir).getName();
        // Include a special case for GH3 output directory naming
        String finalTargetDir = targetDir + "/Converted_to_" + targetBoard + "/" + 
                                (targetBoard == BoardType.GH3 ? "sound1 - " : "") + 
                                sourceDirName;

        // Prepare Log file
        if (chained == false) {
            ensureDirectoryExists(Paths.get(finalTargetDir));
            SimpleDateFormat sdf = new SimpleDateFormat("MMM dd, yyyy");
            String currentDate = sdf.format(new Date());
            logStringBuilder.append("Converted with SoundFont Naming Converter 3.0\n");
            logStringBuilder.append("Brian Conner a.k.a NoSloppy\n\n");
            logStringBuilder.append(currentDate).append("\n");

            if (targetBoard == BoardType.PROFFIE && realTarget == "PROFFIE") {
                logStringBuilder.append("Converted: ").append(sourceBoard).append(" to ").append(targetBoard).append("\n");
                logStringBuilder.append("Optimized for Fat32 performance: ").append(optimizeForProffie ? "Yes" : "No").append("\n\n");
            } else if (targetBoard != BoardType.PROFFIE) {
                realTarget = targetBoard.toString();
            } else {
                logStringBuilder.append("Converted: ").append(sourceBoard).append(" to ").append(realTarget).append("\n");
                logStringBuilder.append("\n");
            }
        }

        // If it's Proffie to Proffie, skip the mapping
        Map<String, String> mapping;
        if (sourceBoard == BoardType.PROFFIE && targetBoard == BoardType.PROFFIE) {
            mapping = null; // No mapping required for Proffie to Proffie
        } else {
            if (!soundMappings.containsKey(key)) {
                System.out.println("Conversion from " + sourceBoard + " to " + targetBoard + " is not supported.");
                return;
            }
            mapping = soundMappings.get(key);
        }

        ensureDirectoryExists(Paths.get(finalTargetDir));

    // Check if source has directories named something like "Bonus Files" or "extra"
        boolean hasExtrasDirectories = false;
        try {
            hasExtrasDirectories = Files.walk(Paths.get(sourceDir), 1) // Only check immediate children
            .filter(Files::isDirectory).anyMatch(path -> {
                String dirName = path.getFileName().toString().toLowerCase();
                return dirName.contains("bonus") || dirName.contains("extra");
            });
        } catch (IOException ex) {
            ex.printStackTrace();
        }

    // If "extras" directory is needed, create it now
        if (hasExtrasDirectories) {
            ensureDirectoryExists(Paths.get(finalTargetDir + "/extras"));
        }

    // Main sound conversion
        try (Stream<Path> paths = Files.walk(Paths.get(sourceDir))) {
            Map<String, Integer> fileNameCounter = new HashMap<>();
            boolean fontSoundProcessed = false;

            paths.filter(Files::isRegularFile)
            .filter(path -> !path.getFileName().toString().startsWith("."))
            .filter(path -> {

                String parentDirName = path.getParent().getFileName().toString().toLowerCase();
                if (parentDirName.contains("bonus") || parentDirName.contains("extra")) {
                    copyFile(path, Paths.get(finalTargetDir, "extras", path.getFileName().toString()));
                    String logEntryExtras = "Moved extra/bonus file to " + finalTargetDir + "/extras/" + path.getFileName();
                        System.out.println(logEntryExtras);
                        logStringBuilder.append(logEntryExtras).append("\n");
                    return false;
                }
                return true;
            })
            .sorted(Comparator.comparing(Path::toString))
            .forEach(path -> {
                try {
                    String fileName = path.getFileName().toString();
                    // Convert to lowercase only if the file is a .wav file
                    if (fileName.toLowerCase().endsWith(".wav")) {
                        fileName = fileName.toLowerCase();
                    }
                    // Move non-wav files directly to the target folder
                    if (!fileName.endsWith(".wav")) {
                        copyFile(path, Paths.get(finalTargetDir, fileName));
                        String logEntryNonWav = "Moved non-wav file: " + fileName;
                        System.out.println(logEntryNonWav);
                        logStringBuilder.append(logEntryNonWav).append("\n");
                        return;
                    }

                    // Move "track" wav files to "tracks" folder if not xeno
                    if (fileName.contains("track") || fileName.contains("theme")) {
                        if (targetBoard == BoardType.XENO3) {
                            System.out.println("Targetboard = Xeno, renaming files named 'track' or 'theme'");
                        } else {
                            ensureDirectoryExists(Paths.get(finalTargetDir + "/tracks"));
                            copyFile(path, Paths.get(finalTargetDir, "tracks", fileName));
                            String logEntryTrack = "Moved track file: " + fileName;
                            System.out.println(logEntryTrack);
                            logStringBuilder.append(logEntryTrack).append("\n");
                            return;
                        }
                    }

                    // For other wav files, use the mapping
                    // String baseName = fileName.replaceAll(" (\\(\\d+\\))?\\.wav$|\\d+\\.wav$", ".wav");
                    // String baseName = fileName.replaceAll("( \\(\\d+\\)| \\d+|\\d+)?\\.wav$", ".wav");
                    String baseName = fileName.replaceAll("( \\(\\d+\\)| \\d+|\\(\\d+\\)|\\d+)+\\.wav$", ".wav");


                    // If we're doing Proffie to Proffie, keep the baseName as is
                    String convertedBaseName = (mapping == null) ? baseName : mapping.getOrDefault(baseName, baseName);

                    String outputPath = "";
                    if (convertedBaseName != null) {
                        int count = soundCounter.getOrDefault(convertedBaseName, 0) + 1;
                        soundCounter.put(convertedBaseName, count);

                        String prefix = (convertedBaseName.contains(".")) ? convertedBaseName.substring(0, convertedBaseName.lastIndexOf('.')) : convertedBaseName;
                        String formattedCount = String.valueOf(count);

                        Set<String> loggedFiles = new HashSet<>(); // flag to prevent multi logging of poweroff case 

                        if (targetBoard == BoardType.CFX) {
                            String newPrefix;
                            int currentCounter;


                            String switchKey = convertedBaseName.toLowerCase().replaceAll("\\.wav$", "");
                            // process incoming "melt" files as "drag" as well - JUST MAP IT!!
                            // if ("melt".equalsIgnoreCase(switchKey)) {
                            //     switchKey = "drag";
                            // }
                            String commonKey;
                            switch (switchKey) {
                                // Adding pwroff2 regardless of only 1 input file.
                                case "poweroff":
                                    commonKey = "pwroff";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    if (currentCounter == 1) {
                                        // Create poweroff.wav
                                        outputPath = finalTargetDir + "/poweroff.wav";
                                        copyFile(path, Paths.get(outputPath));
                                        // Log the file creation
                                        String logEntryPoweroff = "Converted: " + path.getFileName().toString() + " -> " + outputPath.replace("temporaryDirectory/", "");
                                        System.out.println(logEntryPoweroff);
                                        logStringBuilder.append(logEntryPoweroff).append("\n");

                                        // Also create pwroff2.wav
                                        outputPath = finalTargetDir + "/pwroff2.wav";
                                        copyFile(path, Paths.get(outputPath));
                                        // Log the file creation
                                        String logEntryPwroff2 = "Converted: " + path.getFileName().toString() + " -> " + outputPath.replace("temporaryDirectory/", "");
                                        System.out.println(logEntryPwroff2);
                                        logStringBuilder.append(logEntryPwroff2).append("\n");
                                    } else if (currentCounter == 2) {
                                        // Overwrite pwroff2.wav
                                        outputPath = finalTargetDir + "/pwroff2.wav";
                                        copyFile(path, Paths.get(outputPath));
                                        // Log the file update
                                        String logEntryUpdate = "Updated: " + path.getFileName().toString() + " -> " + outputPath.replace("temporaryDirectory/", "");
                                        System.out.println(logEntryUpdate);
                                        logStringBuilder.append(logEntryUpdate).append("\n");
                                    } else {
                                        // Follow original pattern for subsequent files
                                        newPrefix = "poweroff" + (currentCounter - 1);
                                        outputPath = finalTargetDir + "/" + newPrefix + ".wav";
                                        copyFile(path, Paths.get(outputPath));
                                        // Log the file creation
                                        String logEntrySubsequent = "Converted: " + path.getFileName().toString() + " -> " + outputPath.replace("temporaryDirectory/", "");
                                        System.out.println(logEntrySubsequent);
                                        logStringBuilder.append(logEntrySubsequent).append("\n");
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
                                //     outputPath = finalTargetDir + "/" + newPrefix + ".wav";
                                //     fileNameCounter.put(commonKey, currentCounter + 1);
                                //     break;

                                case "font":
                                    commonKey = "font";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    if (currentCounter == 1) {
                                        outputPath = finalTargetDir + "/font" + ".wav";
                                    } else {
                                        int nextBootCounter = fileNameCounter.getOrDefault("boot", 1);
                                        outputPath = finalTargetDir + "/boot" + (nextBootCounter == 1 ? "" : nextBootCounter) + ".wav";
                                        fileNameCounter.put("boot", nextBootCounter + 1);
                                    }
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    break;

                                // These get no number on the first file, then sequence the rest staring from 2
                                case "boot":
                                    commonKey = "boot";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    outputPath = finalTargetDir + "/boot" + (currentCounter == 1 ? "" : currentCounter) + ".wav";
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    break;

                                case "color":
                                    commonKey = "color";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    outputPath = finalTargetDir + "/" + convertedBaseName.substring(0, convertedBaseName.length() - 4) + (currentCounter == 1 ? "" : currentCounter) + ".wav";
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    break;
                                // case "blaster":
                                //     commonKey = "blaster";
                                //     currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                //     outputPath = finalTargetDir + "/" + convertedBaseName.substring(0, convertedBaseName.length() - 4) + (currentCounter == 1 ? "" : currentCounter) + ".wav";
                                //     fileNameCounter.put(commonKey, currentCounter + 1);
                                //     break;
                                case "poweron":
                                    commonKey = "poweron";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    outputPath = finalTargetDir + "/" + convertedBaseName.substring(0, convertedBaseName.length() - 4) + (currentCounter == 1 ? "" : currentCounter) + ".wav";
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    break;
                                case "lockup":
                                    commonKey = "lockup";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    outputPath = finalTargetDir + "/" + convertedBaseName.substring(0, convertedBaseName.length() - 4) + (currentCounter == 1 ? "" : currentCounter) + ".wav";
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    break;
                                case "drag":
                                    commonKey = "drag";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    outputPath = finalTargetDir + "/" + convertedBaseName.substring(0, convertedBaseName.length() - 4) + (currentCounter == 1 ? "" : currentCounter) + ".wav";
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    break;
                                // case "drag":
                                //     commonKey = "drag";
                                //     currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                //     // Use commonKey to generate outputPath
                                //     outputPath = finalTargetDir + "/" + commonKey + (currentCounter == 1 ? "" : currentCounter) + ".wav";
                                //     fileNameCounter.put(commonKey, currentCounter + 1);
                                //     break;

                                case "force":
                                    commonKey = "force";
                                    currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                                    outputPath = finalTargetDir + "/" + convertedBaseName.substring(0, convertedBaseName.length() - 4) + (currentCounter == 1 ? "" : currentCounter) + ".wav";
                                    fileNameCounter.put(commonKey, currentCounter + 1);
                                    break;

                                default:
                                    currentCounter = fileNameCounter.getOrDefault(switchKey, 1);
                                    outputPath = finalTargetDir + "/" + convertedBaseName.substring(0, convertedBaseName.length() - 4) + currentCounter + ".wav";

                                    fileNameCounter.put(switchKey, currentCounter + 1);
                                    break;
                            }

                        } else if (targetBoard == BoardType.PROFFIE) {
                            if (prefix.length() > 6 && count == 1 && soundCounter.containsKey(baseName)) {
                                formattedCount = String.valueOf(count);
                            } else {
                                formattedCount = (prefix.length() > 6) ? String.valueOf(count) : String.format("%02d", count);
                            }
                            if (optimizeForProffie) {
                                outputPath = count == 1 ? finalTargetDir + "/" + prefix + ".wav" : finalTargetDir + "/" + prefix + "/" + prefix + formattedCount + ".wav";

                                if (count == 2) {
                                    Path originalPath = Paths.get(finalTargetDir, prefix + ".wav");
                                    Path newPath = Paths.get(finalTargetDir, prefix, prefix + (prefix.length() > 6 ? "1" : "01") + ".wav");
                                    ensureDirectoryExists(Paths.get(finalTargetDir + "/" + prefix));
                                    Files.move(originalPath, newPath, StandardCopyOption.REPLACE_EXISTING);
                                    String logEntryProffie = "Numbered and moved first file to subdirectory:\n" 
                                                             + "    " + originalPath.subpath(2, originalPath.getNameCount()) 
                                                             + " -> " 
                                                             + newPath.subpath(2, newPath.getNameCount());
                                    System.out.println(logEntryProffie);
                                    logStringBuilder.append(logEntryProffie).append("\n");
                                }
                            } else {
                                outputPath = finalTargetDir + "/" + (count > 1 ? prefix + formattedCount : prefix) + ".wav";
                                
                                if (count == 2) {
                                    Path originalPath = Paths.get(finalTargetDir, prefix + ".wav");
                                    Path newPath = Paths.get(finalTargetDir, prefix + (prefix.length() > 6 ? "1" : "01") + ".wav");
                                    Files.move(originalPath, newPath, StandardCopyOption.REPLACE_EXISTING);
                                    String logEntryProffie = "Numbered the first file:\n "
                                                             + "    " + originalPath.subpath(2, originalPath.getNameCount()) 
                                                             + " -> " 
                                                             + newPath.subpath(2, newPath.getNameCount());
                                    System.out.println(logEntryProffie);
                                    logStringBuilder.append(logEntryProffie).append("\n");
                                }
                            }
                        } else if (targetBoard == BoardType.VERSO && convertedBaseName.equals("font.wav")) {
                            String commonKey = "font";
                            int currentCounter = fileNameCounter.getOrDefault(commonKey, 1);
                            fileNameCounter.put(commonKey, currentCounter + 1);

                            if (currentCounter == 1) {
                                outputPath = finalTargetDir + "/font.wav";
                                copyFile(path, Paths.get(outputPath));
                                String logEntryVerso = "Converted: " + path.getFileName().toString() + " -> " + outputPath.replace("temporaryDirectory/", "");
                                System.out.println(logEntryVerso);
                                logStringBuilder.append(logEntryVerso).append("\n");
                            } else {
                                String logEntryVersoSkipped = "Skipped additional 'font' file: " + fileName;
                                System.out.println(logEntryVersoSkipped);
                                logStringBuilder.append(logEntryVersoSkipped).append("\n");
                            }
                            return;

                        } else if (targetBoard == BoardType.XENO3) {
                            outputPath = Paths.get(finalTargetDir, prefix + " (" + count + ").wav").toString();

                        } else if (count > 1 || (targetBoard != BoardType.PROFFIE && count == 1)) {
                            outputPath = Paths.get(finalTargetDir, prefix + formattedCount + ".wav").toString();
                        } else {
                            outputPath = Paths.get(finalTargetDir, prefix + ".wav").toString();
                        }

                        // Now write the answer after all that checking and filtering.
                                                // one more check if poweroff happened.
                        // Conditional general logging
                        if (!loggedFiles.contains(path.getFileName().toString())) {
                            copyFile(path, Paths.get(outputPath));
                            String logEntry = "Converted: " + path.getFileName().toString() + " -> " + outputPath.replace("temporaryDirectory/", "");
                            System.out.println(logEntry);
                            logStringBuilder.append(logEntry).append("\n");
                        }

                    } else { // convertedBaseName = null
                        System.out.println("Skipped wav file without mapping: " + fileName);
                    }
                } catch (IOException e) {
                    System.err.println("An IOException occurred: " + e.getMessage());
                }
            });
            if (chained == true) {
                logStringBuilder.append("\n*********----- MTFBWY -----*********\n");
            } else {
                logStringBuilder.append("\n\n");
            }
            try {
                System.out.println("--- Writing _Conversion_Log.txt ---");
                Files.writeString(Paths.get(finalTargetDir, "_Conversion_Log.txt"), logStringBuilder.toString());
            } catch (IOException e) {
                System.err.println("Failed to write log: " + e.getMessage());
            }
        } catch (IOException ex) {
            System.err.println("An error occurred while reading the file: " + ex.getMessage());
        }

    // After processing all files, check for default INIs for Proffie
        if (targetBoard == BoardType.PROFFIE) {
            String[] defaultFiles = {"config.ini", "smoothsw.ini"};
            for (String defaultFile : defaultFiles) {
                File targetDefaultFile = new File(finalTargetDir, defaultFile);
                if (!targetDefaultFile.exists()) {
                    File inisFile = new File(DEFAULTS_PATH + "/" + defaultFile);
                    if (inisFile.exists()) {
                        try {
                            Files.copy(inisFile.toPath(), targetDefaultFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
                            System.out.println("Copied default file: " + defaultFile);
                        } catch (IOException e) {
                            // e.printStackTrace();
                            System.err.println("Error while copying file: " + defaultFile);

                        }
                    }
                }
            }
        }
    }

    public class MutableInt {
        public int value;
        public MutableInt(int value) {
            this.value = value;
        }
    }

    public void cleanupTemporaryDirectory() {
        System.out.println("Removing any existing temporaryDirectory and generated zip file");
        try {
            Path tempDir = Paths.get("temporaryDirectory");
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
            Files.deleteIfExists(Paths.get("temporaryDirectory.zip"));

        } catch (IOException e) {
            // Handle the exception, e.g., logging it.
            e.printStackTrace();
        }
    }

public void convertSoundFont(List<Path> savedFiles, String sourceBoard, String targetBoard, boolean optimize) throws IOException {
    BoardType srcBoard = BoardType.valueOf(sourceBoard.toUpperCase());
    BoardType tgtBoard = BoardType.valueOf(targetBoard.toUpperCase());

    String sourceDir = savedFiles.get(0).getParent().toString();
    convertSounds(srcBoard, sourceDir, tgtBoard, "temporaryDirectory", optimize);
}

    public void chainConvertSoundFont(List<Path> savedFiles, String sourceBoard, String targetBoard, boolean optimize) throws IOException {
        // Clear the StringBuilder for subsequent log entries
        logStringBuilder.setLength(0);
        if ("PROFFIE".equals(sourceBoard) || "PROFFIE".equals(targetBoard)) {
            // Just convert normally.
            convertSoundFont(savedFiles, sourceBoard, targetBoard, optimize);
        } else {
            // Do the chained conversion;
            // cCnvert to PROFFIE first and save it in /temporaryDirectory/Converted_to_PROFFIE.
            // Using realTarget for logging only
            realTarget = targetBoard;
            convertSoundFont(savedFiles, sourceBoard, "PROFFIE", false);
            chained = !chained;

            // Now use the converted PROFFIE files as source for the actual target.
            // Clear the StringBuilder for subsequent log entries
            //logStringBuilder.setLength(0);
            Path tempProffieDir = Paths.get("temporaryDirectory", "Converted_to_PROFFIE");
            List<Path> proffieFiles = Files.walk(tempProffieDir)
            .filter(Files::isRegularFile)
            .collect(Collectors.toList());
            convertSoundFont(proffieFiles, "PROFFIE", targetBoard, false);
            chained = !chained;

            // Optional: Cleanup the temporary directory used for the PROFFIE conversion.
        }
    }

    public void removeOriginalDirectory(String originalDirName) {
        Path originalDir = Paths.get("temporaryDirectory", originalDirName);
        try {
            System.out.println("Initiating removal of directory: " + originalDir.toString());
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
        System.out.println("Completed removal of directory: " + originalDir.toString());
    }

    public Path zipConvertedFiles(String targetDir) throws IOException {
        Path zipPath = Paths.get(targetDir + ".zip");

        // Logging the structure
        Path sourcePath = Paths.get(targetDir);
        System.out.println("Logging directory structure before zipping:");
        Files.walk(sourcePath).forEach(p -> {
        // System.out.println(p.toString());
        });
        System.out.println("Starting to create ZIP file...");

        try (FileSystem zipFs = FileSystems.newFileSystem(zipPath, Map.of("create", "true"))) {
            // Exclude the top-level source directory itself when walking
            Files.walk(sourcePath).filter(p -> !p.equals(sourcePath)).forEach(path -> {
                try {
                    if (Files.isRegularFile(path) && Files.size(path) > 0) { // Ensure it's a file and has content
                        String sourceDirName = sourcePath.getFileName().toString();
                        Path destPath = zipFs.getPath("/" + sourceDirName + "/" + sourcePath.relativize(path).toString());

                        // Ensure the parent directory structure exists in the ZIP
                        if (destPath.getParent() != null) {
                            Files.createDirectories(destPath.getParent());
                        }

                        Files.copy(path, destPath, StandardCopyOption.REPLACE_EXISTING);
                    }
                } catch (NoSuchFileException e) {
                    System.err.println("Directory structure in ZIP does not match expected structure: " + e.getMessage());
                } catch (Exception e) {
                    e.printStackTrace();
                    System.err.println("Error processing file: " + path.toString() + 
                           ". Destination path in ZIP: " + zipFs.getPath("/" + sourcePath.relativize(path).toString()));
                }
            });

        } catch (Exception e) {
            e.printStackTrace();
            throw new IOException("Error encountered during zip operation: " + e.getMessage());
        }
        System.out.println("Conversion complete. Zip file saved and ready for download from " + targetDir + ".zip");
        return zipPath;
    }
}
