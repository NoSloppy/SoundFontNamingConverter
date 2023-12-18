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

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import java.io.StringWriter;
import java.io.PrintWriter;
// import javax.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Enumeration;
// import org.springframework.http.server.ServletServerHttpResponse;
// import org.springframework.http.server.ServerHttpRequest;

@Controller
public class SoundFontConverterController {

    @Autowired
    private SoundFontNamingService soundFontNamingService;
    @Autowired
    private HttpServletRequest request;

    @GetMapping("/")
    public String index() {
        return "index";
    }

    @GetMapping("/downloadConvertedFiles")
    public ResponseEntity<?> downloadConvertedFiles(@RequestParam String targetBoard) {
        try {
            Path fileLocation = Paths.get("temporaryDirectory", "Converted_to_" + targetBoard + ".zip");
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
            @RequestParam(required = false) String optimizeForProffie) {

        boolean optimize = "true".equals(optimizeForProffie); // Interpret the value

    // Log all request parameters
    Enumeration<String> parameterNames = request.getParameterNames();
    while (parameterNames.hasMoreElements()) {
        String paramName = parameterNames.nextElement();
        String[] paramValues = request.getParameterValues(paramName);
        for (String paramValue : paramValues) {
            System.out.println("Param: " + paramName + " Value: " + paramValue);
        }
    }

        // 1. Cleanup any existing temporaryDirectory before processing new files.
        soundFontNamingService.cleanupTemporaryDirectory();

        Path tempDirPath = Paths.get("temporaryDirectory");
        if (!Files.exists(tempDirPath)) {
            try {
                Files.createDirectories(tempDirPath);
            } catch (IOException e) {
                return generateErrorResponse("Directory creation failed for path: " + tempDirPath, e);
            }
        }

        List<Path> savedFiles = new ArrayList<>();
        for (MultipartFile file : files) {
            if (file.getOriginalFilename().endsWith(".DS_Store")) continue;
            Path savePath = Paths.get("temporaryDirectory", file.getOriginalFilename());
            try {
                Files.createDirectories(savePath.getParent());
                Files.copy(file.getInputStream(), savePath);
                savedFiles.add(savePath);
            } catch (IOException e) {
                return generateErrorResponse("File handling failed for path: " + savePath, e);
            }
        }

        try {        
            // 3. Convert files.
            soundFontNamingService.chainConvertSoundFont(savedFiles, sourceBoard, targetBoard, optimize);

            // 4. Remove the original directory.
            String originalDirectoryName = savedFiles.get(0).getParent().getFileName().toString();
            soundFontNamingService.removeOriginalDirectory(originalDirectoryName);

            // 5. Zip the converted files.
            Path resultZip = soundFontNamingService.zipConvertedFiles("temporaryDirectory/Converted_to_" + targetBoard);

            // 6.Return a JSON indicating success instead of the zipped file
            return new ResponseEntity<>(Map.of("status", "success", "message", "Conversion complete!"), HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>(Map.of("status", "error", "message", "Conversion failed due to " + e.getMessage()), HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    private ResponseEntity<String> generateErrorResponse(String message, Exception e) {
        StringWriter sw = new StringWriter();
        e.printStackTrace(new PrintWriter(sw));
        String exceptionAsString = sw.toString();
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(message + exceptionAsString);
    }

}
