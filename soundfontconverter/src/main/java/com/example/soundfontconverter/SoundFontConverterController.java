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
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.TimeUnit;
import java.util.UUID;
import java.util.Collections;

import java.io.StringWriter;
import java.io.PrintWriter;
import jakarta.servlet.http.HttpServletRequest;
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


    @Autowired
    private SoundFontNamingService soundFontNamingService;
    @Autowired
    private HttpServletRequest request;
    @Autowired
    private ConversionLogService conversionLogService;


    @GetMapping("/")
    public String index(HttpSession session) {
    logger.info("Index page accessed. Resetting session.");
        // Clear session attributes for a fresh start
    session.invalidate(); // Invalidate the current session and create a new one

        return "index";
    }

    @GetMapping("/downloadConvertedFiles")
    public ResponseEntity<?> downloadConvertedFiles(@RequestParam String targetBoard, @RequestParam String dirIdentifier) {
        try {
            String tempDirName = "temporaryDirectory-" + dirIdentifier;
            Path fileLocation = Paths.get(tempDirName, "Converted_to_" + targetBoard + ".zip");
         if (!Files.exists(fileLocation)) {
            // Log an error if the file does not exist
            logger.info("Error: File not found at " + fileLocation);
            return new ResponseEntity<>("Error: File not found.", HttpStatus.NOT_FOUND);
        }

                   byte[] data = Files.readAllBytes(fileLocation);

            HttpHeaders headers = new HttpHeaders();
            headers.add(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=" + fileLocation.getFileName().toString());
            headers.setContentType(MediaType.parseMediaType("application/zip"));

            return new ResponseEntity<>(data, headers, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>("Error occurred while downloading file.", HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @PostMapping("/convert")
    public ResponseEntity<?> convertSoundFont(
            @RequestParam String sourceBoard,
            @RequestParam String targetBoard,
            @RequestParam("files") MultipartFile[] files,
            @RequestParam(required = false) String optimizeCheckbox,
            @RequestParam String sourceDirName, HttpSession session) {

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

        // Log all request parameters
        Enumeration<String> parameterNames = request.getParameterNames();
        while (parameterNames.hasMoreElements()) {
            String paramName = parameterNames.nextElement();
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
            // 1. Initial Cleanup: Clear the temporary directory before processing new files
            soundFontNamingService.cleanupTemporaryDirectory(tempDirName);
 
            // 2. Make temp directory
            Path tempDirPath = Paths.get(tempDirName);
            if (!Files.exists(tempDirPath)) {
                Files.createDirectories(tempDirPath);
            }

            // 3. Get uploaded files
            String filePath = "";
            List<Path> savedFiles = new ArrayList<>();
            for (MultipartFile file : files) {
                filePath = file.getOriginalFilename();
                // If using Safari, this retrieves JUST the file name, not the source folder on the path, so we need to add it.
                // So for example, Safari = blaster.wav, but Chrome will give DDC/blaster.wav.
                if (sourceDirName != null && !sourceDirName.isBlank() && !filePath.startsWith(sourceDirName + "/")) {
                    filePath = Paths.get(sourceDirName, filePath).normalize().toString();
                    if (!filePath.startsWith(sourceDirName)) {
                        throw new SecurityException("Invalid file path.");
                    }
                }
                if (filePath.endsWith(".DS_Store")) continue;
                Path savePath = Paths.get(tempDirName, filePath); // Include sourceDirName?
                Files.createDirectories(savePath.getParent());
                Files.copy(file.getInputStream(), savePath);
                savedFiles.add(savePath);
            }
// logger.info("Debug: Sample file path received to process files from : " + filePath);


            // 4. Convert files.    
            soundFontNamingService.chainConvertSoundFont(sessionId, sourceBoard, targetBoard, tempDirName, optimize, sourceDirName);

            // 5. Remove the original directory.
            String originalDirectoryName = savedFiles.get(0).getParent().getFileName().toString();
            soundFontNamingService.removeOriginalDirectory(originalDirectoryName, tempDirName);

            // 6. Zip the converted files.
            Path resultZip = soundFontNamingService.zipConvertedFiles(sessionId, tempDirName, sourceBoard, targetBoard);

            // 7. After successful conversion, schedule cleanup
            scheduleFileDeletion(CLEANUP_MINUTES);

            return new ResponseEntity<>(Map.of("status", "success", "message", "Conversion complete!", "dirIdentifier", sessionIdentifier), HttpStatus.OK);

        } catch (Exception e) {
            conversionLogService.sendLogToEmitter(sessionId, "Conversion failed due to " + e.getMessage());
            return new ResponseEntity<>(Map.of("status", "error", "message", "Conversion failed due to " + e.getMessage()), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    private void scheduleFileDeletion(int minutes) {
        cleanupTimer.cancel();
        cleanupTimer.purge();
        cleanupTimer = new Timer(true);

        cleanupTimer.schedule(new TimerTask() {
            @Override
            public void run() {
                logger.info("Performing scheduled cleanup for all temporary directories.");
                deleteAllTempDirectories();
                synchronized (activeSessions) {
                    activeSessions.clear();
                    logger.info("All active sessions cleared.");
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
                logger.info("Deleted temporary directory: " + dir.getName());
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
