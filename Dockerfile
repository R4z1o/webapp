# Build stage
FROM maven:3.9.6-eclipse-temurin-21 AS build

WORKDIR /app

# Copy source
COPY pom.xml .
COPY src ./src

# Build WAR
RUN mvn clean package -DskipTests

# Runtime stage
FROM tomcat:10.1.41-jdk21-temurin

LABEL org.opencontainers.image.source="https://github.com/DataDog/vulnerable-java-application/"

# Optional: add sample files (used by your app)
RUN mkdir -p /tmp/files && echo "hello" > /tmp/files/hello.txt && echo "world" > /tmp/files/foo.txt

# Deploy WAR to Tomcat
COPY --from=build /app/target/*.war /usr/local/tomcat/webapps/WebApp.war

# Expose port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
