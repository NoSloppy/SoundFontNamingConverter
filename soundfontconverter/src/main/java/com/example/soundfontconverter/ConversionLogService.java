package com.example.soundfontconverter;

import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.concurrent.ConcurrentHashMap;
import java.util.Set;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class ConversionLogService {
    private static final Logger logger = LoggerFactory.getLogger(ConversionLogService.class);

    private final ConcurrentHashMap<String, SseEmitter> emitters = new ConcurrentHashMap<>();

public void addEmitter(String sessionId, SseEmitter emitter) {
    emitter.onCompletion(() -> removeAndCompleteEmitter(sessionId));
    emitter.onTimeout(() -> removeAndCompleteEmitter(sessionId));
    emitters.put(sessionId, emitter);
    logger.info("Emitter added for session: {}", sessionId);
}

private void removeAndCompleteEmitter(String sessionId) {
    SseEmitter emitter = emitters.remove(sessionId);
    if (emitter != null) {
        emitter.complete();
        logger.info("Emitter completed and removed for session: {}", sessionId);
    }
}

    public void removeEmitter(String sessionId) {
        emitters.remove(sessionId);
        logger.info("Emitter removed for session: {}", sessionId);
    }

private void safelySendMessage(String sessionId, SseEmitter.SseEventBuilder message) {
    SseEmitter emitter = emitters.get(sessionId);
    if (emitter != null) {
        try {
            emitter.send(message);
        } catch (IOException e) {
            removeAndCompleteEmitter(sessionId);
            logger.error("Error sending message to session: {}", sessionId, e);
        }
    }
}

public void sendLogToEmitter(String sessionId, String logMessage) {
    safelySendMessage(sessionId, SseEmitter.event().data(logMessage));
}

public void clearLogEmitters(String sessionId) {
    safelySendMessage(sessionId, SseEmitter.event().data("CLEAR_LOGS"));
}

}
