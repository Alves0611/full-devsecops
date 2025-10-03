FROM openjdk:8-jdk-alpine
EXPOSE 8080
ARG JAR_FILE=target/*.jar

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy artifact & switch user
COPY ${JAR_FILE} /home/appuser/app.jar
USER appuser
WORKDIR /home/appuser

ENTRYPOINT ["java","-jar","/home/appuser/app.jar"]