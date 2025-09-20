#!/bin/bash
# App Tier Initialization Script

# Update system
apt-get update
apt-get install -y openjdk-11-jdk curl

# Create app user
useradd -m -s /bin/bash appuser

# Create simple Java application
mkdir -p /opt/app
cat > /opt/app/SimpleApp.java << 'EOF'
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

public class SimpleApp {
    private static final String DB_URL = "jdbc:sqlserver://${db_server};databaseName=${db_name};encrypt=true;trustServerCertificate=false;";

    public static void main(String[] args) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);
        server.createContext("/", new MainHandler());
        server.createContext("/health", new HealthHandler());
        server.setExecutor(null);
        server.start();
        System.out.println("App tier server started on port 8080");
    }

    static class MainHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange t) throws IOException {
            String response = "Hello from App Tier! Time: " + new java.util.Date();
            t.sendResponseHeaders(200, response.length());
            OutputStream os = t.getResponseBody();
            os.write(response.getBytes());
            os.close();
        }
    }

    static class HealthHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange t) throws IOException {
            String response = "healthy";
            t.sendResponseHeaders(200, response.length());
            OutputStream os = t.getResponseBody();
            os.write(response.getBytes());
            os.close();
        }
    }
}
EOF

# Compile and run the application
cd /opt/app
javac SimpleApp.java

# Create systemd service
cat > /etc/systemd/system/app-tier.service << 'EOF'
[Unit]
Description=App Tier Service
After=network.target

[Service]
Type=simple
User=appuser
WorkingDirectory=/opt/app
ExecStart=/usr/bin/java SimpleApp
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Set permissions
chown -R appuser:appuser /opt/app

# Enable and start service
systemctl daemon-reload
systemctl enable app-tier
systemctl start app-tier

# Configure logging
echo "App tier initialized on $(hostname) at $(date)" >> /var/log/app-tier-init.log