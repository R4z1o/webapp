FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package
FROM openjdk:17-jdk-slim
ENV TOMCAT_VERSION 10.1.40
RUN apt-get update && apt-get install -y wget && \
    wget https://downloads.apache.org/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz && \
    tar xvf apache-tomcat-${TOMCAT_VERSION}.tar.gz -C /opt/ && \
    rm apache-tomcat-${TOMCAT_VERSION}.tar.gz

EXPOSE 8080

COPY --from=build /app/target/WebApp.war /opt/apache-tomcat-${TOMCAT_VERSION}/webapps/

CMD ["/opt/apache-tomcat-${TOMCAT_VERSION}/bin/catalina.sh", "run"]