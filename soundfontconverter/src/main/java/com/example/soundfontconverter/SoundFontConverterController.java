package com.example.soundfontconverter;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import java.util.Set;
import java.util.HashSet;

import java.io.IOException;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicBoolean;

import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.TimeUnit;
import java.util.UUID;
import java.util.Collections;
import java.nio.file.StandardCopyOption;

import java.io.StringWriter;
import java.io.PrintWriter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.util.Enumeration;
import jakarta.servlet.http.HttpSession;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import com.example.soundfontconverter.ConversionLogService;
import com.example.soundfontconverter.SoundFontNamingService;

@Controller
public class SoundFontConverterController {

    private Timer cleanupTimer = new Timer(true); // 'true' makes it a daemon thread.
    private final Set<String> activeSessions = Collections.synchronizedSet(new HashSet<>());
    private final AtomicInteger activeSessionCounter = new AtomicInteger(0);
    private static final int MAX_CONCURRENT_SESSIONS = 10;
    private static final int CLEANUP_MINUTES = 3;
    private static final Logger logger = LoggerFactory.getLogger(SoundFontConverterController.class);
    private final AtomicBoolean isConversionActive = new AtomicBoolean(false);
    public static final String ANSI_RESET = "\u001B[0m";
    public static final String ANSI_RED = "\u001B[31m";
    public static final String ANSI_GREEN = "\u001B[32m";
    public static final String ANSI_YELLOW = "\u001B[33m";

    @Autowired
    private SoundFontNamingService soundFontNamingService;
    @Autowired
    private HttpServletRequest request;
    @Autowired
    private ConversionLogService conversionLogService;


    @GetMapping("/")
    public String index(HttpSession session) {
    logger.info(ANSI_GREEN + "-- Index page accessed. Resetting session. --" + ANSI_RESET);
        // Clear session attributes for a fresh start
    session.invalidate(); // Invalidate the current session and create a new one

        return "index";
    }
@GetMapping("/downloadConvertedFiles")
public void downloadConvertedFiles(@RequestParam String targetBoard, @RequestParam String dirIdentifier, HttpServletResponse response) {
    try {
        String tempDirName = "temporaryDirectory-" + dirIdentifier;
        Path fileLocation = Paths.get(tempDirName, "Converted_to_" + targetBoard + ".zip");

        if (!Files.exists(fileLocation)) {
            // Log an error if the file does not exist
            logger.info(ANSI_RED + "Error: File not found at " + fileLocation + ANSI_RESET);
            // Set an appropriate response for file not found
            response.sendError(HttpStatus.NOT_FOUND.value(), "Error: File not found.");
            return;
        }

        // Set the content type and header for file download
        response.setContentType("application/zip");
        response.setHeader(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=" + fileLocation.getFileName().toString());

        // Stream the file to the response's output stream
        Files.copy(fileLocation, response.getOutputStream());
        response.getOutputStream().flush();

        logger.info(ANSI_GREEN + "** File downloaded successfully: " + fileLocation.getFileName() + ANSI_RESET);

    } catch (Exception e) {
        logger.error(ANSI_RED + "Error occurred while downloading file: " + e.getMessage() + ANSI_RESET);
        try {
            // Respond with an internal server error status in case of exceptions
            response.sendError(HttpStatus.INTERNAL_SERVER_ERROR.value(), "Error occurred while downloading file.");
        } catch (IOException ex) {
            logger.error(ANSI_RED + "Error sending error response: " + ex.getMessage() + ANSI_RESET);
        }
    }
}


@PostMapping("/audioConvert")
public ResponseEntity<?> convertAudioOnly(
        @RequestParam("audioFiles") MultipartFile[] audioFiles,
        @RequestParam("filePaths") List<String> filePaths,
        HttpSession session) {

// Retrieve or create a unique session-specific identifier for audio conversion
String sessionIdentifier = (String) session.getAttribute("audioSessionIdentifier");
if (sessionIdentifier == null) {
    sessionIdentifier = "audio-" + UUID.randomUUID().toString().substring(0, 8);
    session.setAttribute("audioSessionIdentifier", sessionIdentifier);
}
String tempDirName = "temporaryDirectory-" + sessionIdentifier;


    try {
        logger.info(ANSI_GREEN + "----------- Converting Audio Only -------------" + ANSI_RESET);
        isConversionActive.set(true);
        logger.info(ANSI_YELLOW + "isConversionActive = " + isConversionActive + ANSI_RESET);
        soundFontNamingService.cleanupTemporaryDirectory(tempDirName);
        Path tempDirPath = Paths.get(tempDirName);
        if (!Files.exists(tempDirPath)) {
            Files.createDirectories(tempDirPath);
        }

        // Process and save uploaded files preserving directory structure.
        for (int i = 0; i < audioFiles.length; i++) {
            MultipartFile audioFile = audioFiles[i];
            String relativePath = filePaths.get(i); // Use webkitRelativePath from the form data
            Path targetPath = tempDirPath.resolve(relativePath);

            // Create directories for any subpaths
            Files.createDirectories(targetPath.getParent());
            // Copy and process the file
            Files.copy(audioFile.getInputStream(), targetPath, StandardCopyOption.REPLACE_EXISTING);
            // weed out non-wav or non-mp3 files
            soundFontNamingService.convertAudioIfNeeded(targetPath, targetPath.toFile(), tempDirPath);
        }
        // Zip the processed files
        Path resultZip = soundFontNamingService.zipAudioFiles(tempDirPath, "Converted_Audio_Only");
        logger.info("Converted Audio zipped and ready for download." );
        logger.info(ANSI_YELLOW + "----------- | **** MTFBWY **** | -------------" + ANSI_RESET);

        // Handle empty zip file scenario
        if (Files.size(resultZip) == 0) {
            return new ResponseEntity<>("No audio files were processed.", HttpStatus.BAD_REQUEST);
        }

        byte[] zipData = Files.readAllBytes(resultZip);
        HttpHeaders headers = new HttpHeaders();
        headers.add(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=" + resultZip.getFileName().toString());
        headers.setContentType(MediaType.parseMediaType("application/zip"));
        isConversionActive.set(false);
        logger.info(ANSI_YELLOW + "isConversionActive = " + isConversionActive + ANSI_RESET);

        scheduleFileDeletion(CLEANUP_MINUTES);

        return new ResponseEntity<>(zipData, headers, HttpStatus.OK);
    } catch (Exception e) {
        logger.error(ANSI_RED + "Error occurred during audio conversion: ", e + ANSI_RESET);
        return generateErrorResponse("Error occurred during audio conversion: ", e);
    }
}

    @PostMapping("/convert")
    public ResponseEntity<?> convertSoundFont(
            @RequestParam String sourceBoard,
            @RequestParam String targetBoard,
            @RequestParam("files") MultipartFile[] files,
            @RequestParam(required = false) String optimizeCheckbox,
            @RequestParam String sourceDirName,
            @RequestParam("filePaths") String[] filePaths, // Added this line to receive the array of file paths
        HttpSession session) {

        session.setAttribute("sourceBoard", sourceBoard);
        session.setAttribute("targetBoard", targetBoard);

        boolean optimize = "true".equals(optimizeCheckbox); // Interpret the value

        String sessionId = request.getSession().getId();

        // Check if the session exceeds the maximum allowed
        synchronized (activeSessions) {
            if (!activeSessions.contains(sessionId) && activeSessions.size() >= MAX_CONCURRENT_SESSIONS) {
                return new ResponseEntity<>(Map.of("status", "error", "message", "Server full. Wait time 3 minutes or less.\nClick 'Convert' to try again"), HttpStatus.TOO_MANY_REQUESTS);
            }
            activeSessions.add(sessionId);
        }

        // Check for new session
        boolean isNewSession = activeSessions.add(sessionId);
        if (isNewSession) {
            int currentActiveSessions = activeSessionCounter.incrementAndGet();
            if (currentActiveSessions > MAX_CONCURRENT_SESSIONS) {
                activeSessionCounter.decrementAndGet();
                activeSessions.remove(sessionId);
                return new ResponseEntity<>(Map.of("status", "error", "message", "Server busy. Please wait and try again."), HttpStatus.TOO_MANY_REQUESTS);
            }
        }

        // Clear screen for GUI logs
        conversionLogService.clearLogEmitters(sessionId);
        // space out new conversion in console log
        logger.info("\n");

        // Log all request parameters
        Enumeration<String> parameterNames = request.getParameterNames();
        while (parameterNames.hasMoreElements()) {
            String paramName = parameterNames.nextElement();
            if ("filePaths".equals(paramName)) continue;
            String[] paramValues = request.getParameterValues(paramName);
            for (String paramValue : paramValues) {
                logger.info("** Param: " + paramName + " Value: " + paramValue);
            }
        }

        // Check if the number of active sessions exceeds the maximum allowed
       synchronized (activeSessions) {
            boolean isSessionActive = activeSessions.contains(sessionId);

            if (!isSessionActive) {
                if (activeSessions.size() >= MAX_CONCURRENT_SESSIONS) {
                    // New session trying to start a conversion when max limit reached
                    return new ResponseEntity<>(Map.of("status", "error", "message", "Server full. Please wait."), HttpStatus.TOO_MANY_REQUESTS);
                } else {
                    // New session starting a conversion and limit not reached
                    activeSessions.add(sessionId);
                }
            }
            // Else, this is an ongoing session and can continue its conversion
        }


        // Retrieve or create a unique session-specific identifier
        String sessionIdentifier = (String) session.getAttribute("sessionIdentifier");
        if (sessionIdentifier == null) {
            // Generate a shortened UUID (8 characters)
            sessionIdentifier = UUID.randomUUID().toString().substring(0, 8);
            session.setAttribute("sessionIdentifier", sessionIdentifier);
        }
        String tempDirName = "temporaryDirectory-" + sessionIdentifier;
        session.setAttribute("tempDirName", tempDirName);
        logger.info("** Temporary directory set: " + tempDirName);

        try {
            isConversionActive.set(true);
        logger.info(ANSI_YELLOW + "isConversionActive = " + isConversionActive + ANSI_RESET);
            // 1. Initial Cleanup: Clear the temporary directory before processing new files
            soundFontNamingService.performInitialCleanup(tempDirName);
            //soundFontNamingService.cleanupTemporaryDirectory(tempDirName);
 
            // 2. Make temp directory
            Path tempDirPath = Paths.get(tempDirName);
            if (!Files.exists(tempDirPath)) {
                Files.createDirectories(tempDirPath);
            }

            // 3. Get uploaded files
             String filePath = "";

        List<Path> savedFiles = new ArrayList<>();
    for (int i = 0; i < files.length; i++) {
        MultipartFile file = files[i];
        if (i < filePaths.length && filePaths[i] != null && !filePaths[i].isEmpty()) {
            filePath = filePaths[i]; // Use the complete path from the frontend
        } else {
            filePath = file.getOriginalFilename(); // Fallback to original filename
        }

        Path savePath = Paths.get(tempDirName, filePath);
        Files.createDirectories(savePath.getParent());
        Files.copy(file.getInputStream(), savePath, StandardCopyOption.REPLACE_EXISTING);
        savedFiles.add(savePath);
        // logger.info("File saved at: " + savePath);
    }

            logger.info("isSafari = " + isSafari(request));

            // 4. Convert files.    
            soundFontNamingService.chainConvertSoundFont(sessionId, sourceBoard, targetBoard, tempDirName, optimize, sourceDirName);

            // 5. After converting filesRemove the original directory.
            Path commonParentDir = findCommonParentDirectory(savedFiles);
            soundFontNamingService.removeOriginalDirectory(commonParentDir);

            return new ResponseEntity<>(Map.of("status", "fontProcessed", "message", "One font folder processed"), HttpStatus.OK);
        } catch (Exception e) {
            conversionLogService.sendLogToEmitter(sessionId, "Conversion failed due to " + e.getMessage());
            return new ResponseEntity<>(Map.of("status", "error", "message", "Conversion failed due to " + e.getMessage()), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

@GetMapping("/finalizeConversion")
public ResponseEntity<?> finalizeConversion(HttpSession session) {
    String sessionId = (String) session.getAttribute("sessionIdentifier");
    String tempDirName = "temporaryDirectory-" + sessionId;
    String sourceBoard = (String) session.getAttribute("sourceBoard");
    String targetBoard = (String) session.getAttribute("targetBoard");

    try {
        // 6. Zip the converted files.
        Path resultZip = soundFontNamingService.zipConvertedFiles(sessionId, tempDirName, sourceBoard, targetBoard);

        // 7. After successful conversion, schedule cleanup
        isConversionActive.set(false);
        logger.info(ANSI_YELLOW + "isConversionActive = " + isConversionActive + ANSI_RESET);
        scheduleFileDeletion(CLEANUP_MINUTES);
        soundFontNamingService.resetCleanupFlag();

        return new ResponseEntity<>(Map.of("status", "success", "message", "Conversion complete!", "dirIdentifier", sessionId), HttpStatus.OK);

    } catch (Exception e) {
        isConversionActive.set(false);
        conversionLogService.sendLogToEmitter(sessionId, "Conversion failed due to " + e.getMessage());
        return new ResponseEntity<>(Map.of("status", "error", "message", "Conversion failed due to " + e.getMessage()), HttpStatus.INTERNAL_SERVER_ERROR);
    }
}



    private Path findCommonParentDirectory(List<Path> paths) {
        if (paths == null || paths.isEmpty()) {
            return null;
        }

        Path commonPath = paths.get(0).getParent();
        for (Path path : paths) {
            while (path != null && !path.startsWith(commonPath)) {
                commonPath = commonPath.getParent();
            }
        }
        return commonPath;
    }

    private boolean isSafari(HttpServletRequest request) {
        String userAgent = request.getHeader("User-Agent");
        return userAgent != null && userAgent.contains("Safari") && !userAgent.contains("Chrome");
    }

    private void scheduleFileDeletion(int minutes) {
        cleanupTimer.cancel();
        cleanupTimer.purge();
        cleanupTimer = new Timer(true);

        cleanupTimer.schedule(new TimerTask() {
            @Override
            public void run() {
                if (isConversionActive.get()) {
                    logger.info("** Cleanup skipped as a conversion is active.");
                    // Reschedule cleanup after a delay
                    scheduleFileDeletion(CLEANUP_MINUTES);
                } else {
                    logger.info("** Performing scheduled cleanup for all temporary directories.");
                    deleteAllTempDirectories();
                    synchronized (activeSessions) {
                        activeSessions.clear();
                        logger.info("** All active sessions cleared.");
                    }
                }
            }
        }, TimeUnit.MINUTES.toMillis(minutes) + TimeUnit.SECONDS.toMillis(5));
    }


    private void deleteAllTempDirectories() {
        File currentDirectory = new File("."); // Current directory
        File[] tempDirs = currentDirectory.listFiles(
            (File dir) -> dir.isDirectory() && dir.getName().startsWith("temporaryDirectory")
        );

        if (tempDirs != null) {
            for (File dir : tempDirs) {
                deleteDirectoryRecursively(dir);
                logger.info("** Deleted temporary directory: " + dir.getName());
            }
        }
    }

    private void deleteDirectoryRecursively(File directory) {
        if (directory.isDirectory()) {
            File[] files = directory.listFiles();
            if (files != null) {
                for (File file : files) {
                    deleteDirectoryRecursively(file); // Recursive delete
                }
            }
        }
        directory.delete(); // Delete file or empty directory
    }

        private ResponseEntity<String> generateErrorResponse(String message, Exception e) {
            StringWriter sw = new StringWriter();
            e.printStackTrace(new PrintWriter(sw));
            String exceptionAsString = sw.toString();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(message + exceptionAsString);
        }

    }
