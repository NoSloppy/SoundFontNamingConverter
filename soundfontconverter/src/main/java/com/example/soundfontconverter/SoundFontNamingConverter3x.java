package com.example.soundfontconverter;

import java.nio.file.*;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.stream.Stream;
import java.io.File;
import java.io.BufferedReader;
import java.io.FileReader;
import java.util.List;

public class SoundFontNamingConverter3x {

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

  private static final String DEFAULTS_PATH = "./inis";

  // Declare individual mappings
  private static final Map<String, String> GH3_TO_PROFFIE = new HashMap<>();
  private static final Map<String, String> PROFFIE_TO_CFX = new HashMap<>();
  private static final Map<String, String> PROFFIE_TO_GH3 = new HashMap<>();
  private static final Map<String, String> PROFFIE_TO_VERSO = new HashMap<>();
  private static final Map<String, String> PROFFIE_TO_XENO3 = new HashMap<>();
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

  private static void initializeMappings() {
    // Load mappings from CSVs:
    loadMappingsFromCSV("./CSV/GH3_TO_PROFFIE.csv", GH3_TO_PROFFIE);
    loadMappingsFromCSV("./CSV/PROFFIE_TO_CFX.csv", PROFFIE_TO_CFX);
    loadMappingsFromCSV("./CSV/PROFFIE_TO_GH3.csv", PROFFIE_TO_GH3);
    loadMappingsFromCSV("./CSV/PROFFIE_TO_VERSO.csv", PROFFIE_TO_VERSO);
    loadMappingsFromCSV("./CSV/PROFFIE_TO_XENO3.csv", PROFFIE_TO_XENO3);
    loadMappingsFromCSV("./CSV/VERSO_TO_PROFFIE.csv", VERSO_TO_PROFFIE);
    loadMappingsFromCSV("./CSV/XENO3_TO_PROFFIE.csv", XENO3_TO_PROFFIE);
    // ... and so on for other mappings ...
 
    // Add initialized mappings to central repository
    soundMappings.put(BoardType.getKey(BoardType.PROFFIE, BoardType.CFX), PROFFIE_TO_CFX);
    soundMappings.put(BoardType.getKey(BoardType.PROFFIE, BoardType.GH3), PROFFIE_TO_GH3);
    soundMappings.put(BoardType.getKey(BoardType.PROFFIE, BoardType.VERSO), PROFFIE_TO_VERSO);
    soundMappings.put(BoardType.getKey(BoardType.PROFFIE, BoardType.XENO3), PROFFIE_TO_XENO3);
    soundMappings.put(BoardType.getKey(BoardType.GH3, BoardType.PROFFIE), GH3_TO_PROFFIE);
    soundMappings.put(BoardType.getKey(BoardType.VERSO, BoardType.PROFFIE), VERSO_TO_PROFFIE);
    soundMappings.put(BoardType.getKey(BoardType.XENO3, BoardType.PROFFIE), XENO3_TO_PROFFIE);

  // Reverse Mapping fist so actual mappings will override

    // GH3 to Proffie mapping
   for (Map.Entry<String, String> entry : PROFFIE_TO_GH3.entrySet()) {
        GH3_TO_PROFFIE.putIfAbsent(entry.getValue(), entry.getKey());
    }
    // Verso to Proffie mapping
    for (Map.Entry<String, String> entry : PROFFIE_TO_VERSO.entrySet()) {
        VERSO_TO_PROFFIE.putIfAbsent(entry.getValue(), entry.getKey());
    }
    // Xeno3 to Proffie mapping
    for (Map.Entry<String, String> entry : PROFFIE_TO_XENO3.entrySet()) {
        XENO3_TO_PROFFIE.putIfAbsent(entry.getValue(), entry.getKey());
    }

    // // Print the XENO3_TO_PROFFIE mapping after it's initialized
    // System.out.println("XENO3_TO_PROFFIE mapping: " + XENO3_TO_PROFFIE);

 }

// No optimizeForProffie  parameter included will default optimizeForProffie to true
  private static void convertSounds(BoardType sourceBoard, String sourceDir, BoardType targetBoard, String targetDir) {
    convertSounds(sourceBoard, sourceDir, targetBoard, targetDir, true);
  }

  // This version takes the optimizeForProffie parameter. It contains your main logic
  private static void convertSounds(BoardType sourceBoard, String sourceDir, BoardType targetBoard, String targetDir, boolean optimizeForProffie) {
    soundCounter.clear();  // Resetting the counter
    String key = BoardType.getKey(sourceBoard, targetBoard);
        System.out.println("----------------------------------------------------------------\n.");
        System.out.println("Converting from " + sourceBoard + " to " + targetBoard + "\n.");

    // If it's Proffie to Proffie, skip the mapping
    Map<String, String> mapping;
    // if (sourceBoard == BoardType.PROFFIE && targetBoard == BoardType.PROFFIE) {
    if (sourceBoard == BoardType.PROFFIE && targetBoard == BoardType.PROFFIE) {
      mapping = null; // No mapping required for Proffie to Proffie
    } else if (sourceBoard == BoardType.CFX && targetBoard == BoardType.PROFFIE) {
        System.out.println("Conversion from " + sourceBoard + " to " + targetBoard + " is not required. Proffieboard natively supports Plecter fonts.");
        return;

    } else {
      if (!soundMappings.containsKey(key)) {
        System.out.println("Conversion from " + sourceBoard + " to " + targetBoard + " is not supported.");
        return;
      }
      mapping = soundMappings.get(key);
    }

    ensureDirectoryExists(targetDir);
    ensureDirectoryExists(targetDir + "/tracks");

    // Check if source has directories named something like "Bonus Files" or "extra"
    boolean hasExtrasDirectories = false;

    try {
      hasExtrasDirectories = Files.walk(Paths.get(sourceDir), 1)  // Only check immediate children
      .filter(Files::isDirectory)
      .anyMatch(path -> {
        String dirName = path.getFileName().toString().toLowerCase();
        return dirName.contains("bonus") || dirName.contains("extra");
      });
    } catch (IOException ex) {
      ex.printStackTrace();
    }

    // If "extras" directory is needed, create it now
    if (hasExtrasDirectories) {
      ensureDirectoryExists(targetDir + "/extras");
    }

    // Main sound conversion
    try (Stream<Path> paths = Files.walk(Paths.get(sourceDir))) {
      paths.filter(Files::isRegularFile)
      .filter(path -> !path.getFileName().toString().startsWith("."))
      .filter(path -> {
        if (sourceBoard == BoardType.PROFFIE && path.getFileName().toString().endsWith(".ini")) {
          return false;
        }
        String parentDirName = path.getParent().getFileName().toString().toLowerCase();
        if (parentDirName.contains("bonus") || parentDirName.contains("extra")) {
          copyFile(path.toString(), targetDir + "/extras/" + path.getFileName().toString());
          System.out.println("Moved extra/bonus file: " + path.getFileName());
          return false;
        }
        return true;
      })
      .forEach(path -> {
        String fileName = path.getFileName().toString();

        // Move non-wav files directly to the target folder
        if (!fileName.endsWith(".wav")) {
            copyFile(path.toString(), targetDir + "/" + fileName);
            System.out.println("Moved non-wav file: " + fileName);
          return;
        }

        // Move "track" wav files to "tracks" folder
        if (fileName.contains("track")) {
          copyFile(path.toString(), targetDir + "/tracks/" + fileName);
          System.out.println("Moved track file: " + fileName);
          return;
        }

        // For other wav files, use the mapping
        String baseName = fileName.replaceAll(" (\\(\\d+\\))?\\.wav$|\\d+\\.wav$", ".wav");
        // If we're doing Proffie to Proffie, keep the baseName as is
        String convertedBaseName = (mapping == null) ? baseName : mapping.getOrDefault(baseName, baseName);
        
        // Print the base and convertedBaseName for each file being processed
        // System.out.println("Base Name: " + baseName + ", Converted Name: " + convertedBaseName);

        if (convertedBaseName != null) {
          int count = soundCounter.getOrDefault(convertedBaseName, 0) + 1;
          soundCounter.put(convertedBaseName, count);

          // String prefix = convertedBaseName.substring(0, convertedBaseName.lastIndexOf('.'));
String prefix = (convertedBaseName.contains(".")) ? convertedBaseName.substring(0, convertedBaseName.lastIndexOf('.')) : convertedBaseName;
          String extension = ".wav";
          String outputPath;
          String formattedCount = String.valueOf(count);  // reintroduced declaration

          if (targetBoard == BoardType.PROFFIE) {
            if (optimizeForProffie) {
              if (prefix.length() > 6 && count == 1 && soundCounter.containsKey(baseName)) {
                  formattedCount = String.valueOf(count);
              } else {
                  formattedCount = (prefix.length() > 6) ? String.valueOf(count) : String.format("%02d", count);
              }

              outputPath = count == 1 ? targetDir + "/" + prefix + extension : targetDir + "/" + prefix + "/" + prefix + formattedCount + extension;
              if (count == 2) {
                  String originalPath = targetDir + "/" + prefix + extension;
                  String newPath = targetDir + "/" + prefix + "/" + prefix + (prefix.length() <= 6 ? "01" : "1") + extension;
                  ensureDirectoryExists(targetDir + "/" + prefix);
                  copyFile(originalPath, newPath);
                  new File(originalPath).delete();
                  System.out.println("Numbered and moved first file to subdirectory: " + originalPath + " -> " + newPath);
              }
          } else {
              if (prefix.length() <= 6) {
                  formattedCount = String.format("%02d", count);
              }
              outputPath = targetDir + "/" + (count > 1 ? prefix + formattedCount : prefix) + extension;
              if (count == 2) {
                  String originalPath = targetDir + "/" + prefix + extension;
                  String newPath = targetDir + "/" + prefix + (prefix.length() > 6 ? "1" : "01") + extension;
                  copyFile(originalPath, newPath);
                  new File(originalPath).delete();
              }
          }
        } else if (targetBoard == BoardType.XENO3) {
          String base = prefix.replace(" (1)", ""); // Remove any (1) from the prefix
        if (count > 0) { // For XENO3, we always want a count
          base = base + " (" + count + ")";
        }
        outputPath = targetDir + "/" + base + extension;
        } else if (count > 1 || (targetBoard != BoardType.PROFFIE && count == 1)) {
          outputPath = targetDir + "/" + prefix + formattedCount + extension;
        } else {
          outputPath = targetDir + "/" + prefix + extension;
        }

        copyFile(path.toString(), outputPath);
        System.out.println("Converted: " + fileName + " -> " + outputPath);
        } else {
          System.out.println("Skipped wav file without mapping: " + fileName);
        }

      });
    } catch (IOException ex) {
    ex.printStackTrace();
    }
    // After processing all files, check for default INIs for Proffie
    if (targetBoard == BoardType.PROFFIE) {
      // Check for the default files and copy them if they don't exist in the target directory
      String[] defaultFiles = { "config.ini", "smoothsw.ini" };
      for (String defaultFile : defaultFiles) {
        File targetDefaultFile = new File(targetDir, defaultFile);
        if (!targetDefaultFile.exists()) {
          File inisFile = new File("./inis/" + defaultFile);
          if (inisFile.exists()) {
            try {
              Files.copy(inisFile.toPath(), targetDefaultFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
              System.out.println("Copied default file: " + defaultFile);
            } catch (IOException e) {
            e.printStackTrace();  // You said you don't need additional logging, but keeping it here just in case you change your mind.
            }
          }
        }
      }
    }
  }

  private static void ensureDirectoryExists(String dirPath) {
    File dir = new File(dirPath);
    if (!dir.exists()) {
      dir.mkdirs();
    }
  }


  private static void copyFile(String sourcePath, String targetPath) {
    try {
      Path source = Paths.get(sourcePath);
      Path target = Paths.get(targetPath);
      Files.copy(source, target, StandardCopyOption.REPLACE_EXISTING);
    } catch (IOException ex) {
      System.err.println("Error copying file from " + sourcePath + " to " + targetPath);
      ex.printStackTrace();
    }
  }

  public static void main(String[] args) {
    if (args.length < 4) {
      System.out.println("Usage: java SoundFontNamingConverter3x <source board> <source directory> <target board> <target directory> [optimization]");
      return;
    }

    BoardType sourceBoard = BoardType.valueOf(args[0].toUpperCase());
    BoardType targetBoard = BoardType.valueOf(args[2].toUpperCase());

    String sourceDir = args[1];
    String targetDir = args[3];
    boolean optimizeForProffie = true;  // Default to true

    // If the target board is PROFFIE, then consider the optimization argument, if present.
    if (targetBoard == BoardType.PROFFIE) {
      if (args.length == 5) {
        optimizeForProffie = Boolean.parseBoolean(args[4]);
      }
      convertSounds(sourceBoard, sourceDir, targetBoard, targetDir, optimizeForProffie);
    } else {
      // For non-PROFFIE boards, we don't need the optimization argument.
      convertSounds(sourceBoard, sourceDir, targetBoard, targetDir);
    }
  }

}

// Working with CSV files as maps, next, add Proffie to CFX

// issues PROFFIE TO CFX:
// - 
// - poweroff needs pwroff for second occurance, then additional poweroffs after that.
// - Eventually, need to map out all boards to all boards. I'd love an automated process for that Chat GPT...
