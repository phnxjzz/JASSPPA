# Multi-stage build for SPPA Java application
# Build stage
FROM openjdk:21-jdk-slim AS builder

# Install Maven
RUN apt-get update && apt-get install -y maven && rm -rf /var/lib/apt/lists/*

# Copy project files
COPY pom.xml /app/pom.xml
COPY src /app/src
WORKDIR /app

# Build WAR
RUN mvn clean package -DskipTests -q

# Runtime stage
FROM openjdk:21-jdk-slim

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy WAR from builder
COPY --from=builder /app/target/sistem-pendaftaran-produk-air-*.war /app.war

# Expose port (Cloud Run/App Engine will override PORT env var)
EXPOSE 8080

# Environment variables (can be overridden at runtime)
ENV PORT=8080 \
    DATABASE_URL="jdbc:mysql://localhost:3306/sistemppa" \
    DATABASE_USER="root" \
    DATABASE_PASSWORD="root" \
    JAVA_OPTS="-Xmx512m -Xms256m"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:${PORT}/sistemppa/ || exit 1

# Run WAR with embedded Tomcat
# Note: WAR is executed with java -jar which runs embedded Tomcat
CMD java ${JAVA_OPTS} -jar /app.war --server.port=${PORT}
