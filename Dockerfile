FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package
FROM amazoncorretto:21-alpine-jdk
RUN apk add --no-cache wget tar
RUN wget https://downloads.apache.org/tomcat/tomcat-10/v10.1.41/bin/apache-tomcat-10.1.41.tar.gz && \
    tar xvf apache-tomcat-10.1.41.tar.gz -C /opt/ && \
    rm apache-tomcat-10.1.41.tar.gz
EXPOSE 8080


COPY --from=build /app/target/WebApp.war /opt/apache-tomcat-10.1.41/webapps/
CMD ["/opt/apache-tomcat-10.1.41/bin/catalina.sh", "run"]