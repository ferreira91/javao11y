# Use the official OpenJDK base image
FROM openjdk:17

# Argument to specify the JAR name
ARG JAR_FILE=target/*.jar

# Copy the project's JAR into the container
COPY ${JAR_FILE} app.jar

# Copy the Otel agent into the container
COPY opentelemetry-javaagent.jar opentelemetry-javaagent.jar

# Expose the default Spring Boot port
EXPOSE 8080

ENV OTEL_SERVICE_NAME="javao11y"
ENV OTEL_TRACES_EXPORTER="jaeger"
ENV OTEL_METRICS_EXPORTER="prometheus"
ENV OTEL_LOGS_EXPORTER="logging"
ENV JAVA_TOOL_OPTIONS="-javaagent:opentelemetry-javaagent.jar"

# Command to run the Spring Boot application
ENTRYPOINT ["java","-jar","/app.jar"]
