FROM eclipse-temurin:21-jdk-alpine as build

WORKDIR /workspace/app

COPY gateway/mvnw .
COPY gateway/.mvn .mvn
COPY gateway/pom.xml .
COPY gateway/src src

RUN ./mvnw install -DskipTests

FROM eclipse-temurin:21-jre-alpine

VOLUME /tmp

COPY --from=build /workspace/app/target/*.jar app.jar

EXPOSE 8000

ENTRYPOINT ["java","-jar","/app.jar"]
