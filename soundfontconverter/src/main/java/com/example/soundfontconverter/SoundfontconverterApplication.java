// package com.example.soundfontconverter;

// import org.springframework.boot.SpringApplication;
// import org.springframework.boot.autoconfigure.SpringBootApplication;

// @SpringBootApplication
// public class SoundfontconverterApplication {

// 	public static void main(String[] args) {
// 		SpringApplication.run(SoundfontconverterApplication.class, args);
// 	}

// }
package com.example.soundfontconverter;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import java.util.Collections;

@SpringBootApplication
public class SoundfontconverterApplication {

    public static void main(String[] args) {
        SpringApplication app = new SpringApplication(SoundfontconverterApplication.class);
        
        // Use PORT environment variable if available
        String port = System.getenv("PORT");
        if (port != null) {
            app.setDefaultProperties(Collections.singletonMap("server.port", port));
        }

        app.run(args);
    }
}
