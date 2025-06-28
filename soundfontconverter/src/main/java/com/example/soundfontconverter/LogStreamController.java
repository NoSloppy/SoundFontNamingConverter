package com.example.soundfontconverter;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import org.springframework.beans.factory.annotation.Autowired;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;

@RestController
public class LogStreamController {
    private static final Logger logger = LoggerFactory.getLogger(LogStreamController.class);
    private static final long SSE_EMITTER_TIMEOUT = 30_000L; // 30 seconds timeout

    private final ConversionLogService conversionLogService;

    @Autowired
    public LogStreamController(ConversionLogService conversionLogService) {
        this.conversionLogService = conversionLogService;
    }

    @GetMapping("/stream-conversion-logs")
    public SseEmitter streamConversionLogs(HttpServletRequest request) {
        String sessionId = request.getSession().getId();
        logger.debug("Creating SSE Emitter for session: {}", sessionId);
        SseEmitter emitter = new SseEmitter(SSE_EMITTER_TIMEOUT); // Set the timeout
        // Send "kick-start" message to make connection active(otherwise status just always (pending))
        try {
            emitter.send(SseEmitter.event().comment(""));
        } catch (IOException e) {
            logger.error("Error sending test message to session: {}", sessionId, e);
        }
        conversionLogService.addEmitter(sessionId, emitter);
        emitter.onCompletion(() -> {
            logger.debug("SSE Emitter completed for session: {}", sessionId);
            conversionLogService.removeEmitter(sessionId);
        });

        emitter.onTimeout(() -> {
            logger.debug("SSE Emitter timed out for session: {}", sessionId);
            conversionLogService.removeEmitter(sessionId);
        });

        return emitter;
    }

}
