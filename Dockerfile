# Dependency check stage
FROM owasp/dependency-check:7.1.1 as dependency-check
WORKDIR /app
COPY pom.xml .
COPY src ./src
EXPOSE 9000
RUN /usr/share/dependency-check/bin/dependency-check.sh --scan ./src && \
    apt-get update && \
    apt-get install python3 && \
    echo "Report generated at http://localhost:9000/dependency-check-report.html" && \
    python3 -m http.server 9000 --directory /app
# Build stage
FROM maven:3.9.6-eclipse-temurin-17 AS build
COPY --from=dependency-check /app /app
WORKDIR /app
RUN mvn clean package
FROM amazoncorretto:21-alpine-jdk
RUN apk add --no-cache wget tar
RUN wget https://downloads.apache.org/tomcat/tomcat-10/v10.1.40/bin/apache-tomcat-10.1.40.tar.gz && \
    tar xvf apache-tomcat-10.1.40.tar.gz -C /opt/ && \
    rm apache-tomcat-10.1.40.tar.gz

EXPOSE 8080

COPY --from=build /app/target/WebApp.war /opt/apache-tomcat-10.1.40/webapps/

CMD ["/opt/apache-tomcat-10.1.40/bin/catalina.sh", "run"]