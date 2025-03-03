#
# Build stage
#
FROM maven:3.9.9-eclipse-temurin-23-noble AS build
ENV HOME=/usr/app
RUN mkdir -p $HOME
WORKDIR $HOME
ADD . $HOME
RUN mvn wrapper:wrapper
RUN --mount=type=cache,target=/root/.m2 ./mvnw -f $HOME/pom.xml clean package

#
# Package stage
#
FROM eclipse-temurin:17-jdk-noble
RUN apt-get update -qq && apt-get -y install \
      ffmpeg 
ARG JAR_FILE=/usr/app/target/*.jar
COPY --from=build $JAR_FILE /app/runner.jar
ADD inis /inis
ADD CSV /CSV
ADD GOLDEN_HARVEST_settings /GOLDEN_HARVEST_settings
ADD Verso_Blast /Verso_blast
EXPOSE 8080
ENTRYPOINT java -jar /app/runner.jar