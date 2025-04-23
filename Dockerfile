FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package
FROM openjdk:17-jdk-slim
EXPOSE 8081
COPY --from=build /app/target/WebApp.war /root/apache-tomcat-10.1.40/webapps
CMD ["bash /root/apache-tomcat-10.1.40/bin/catalina.sh", "run"]