FROM eclipse-temurin:8-jre-alpine

WORKDIR /app

COPY target/my-app.jar app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]