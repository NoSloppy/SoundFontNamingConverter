package com.example.soundfontconverter;

import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.context.request.async.AsyncRequestTimeoutException;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.web.multipart.MaxUploadSizeExceededException;

@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(AsyncRequestTimeoutException.class)
    public ResponseEntity<String> handleAsyncRequestTimeoutException(AsyncRequestTimeoutException e) {
        // Custom response for timeout
        return new ResponseEntity<>("Request Timeout", HttpStatus.REQUEST_TIMEOUT);
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<String> handleMaxUploadSizeExceededException(MaxUploadSizeExceededException e) {
        // Custom response for file size limit exceeded
        return ResponseEntity.status(HttpStatus.EXPECTATION_FAILED).body("max file size of 100Mb or total upload of 2500mb exceeded. Please select fewer for conversion");
    }

    // Other exception handlers can be added here if needed
}
