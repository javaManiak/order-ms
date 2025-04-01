# Use an official Maven image to build the application
FROM maven:3.8.7-eclipse-temurin-17 AS build

# Set the working directory inside the container
WORKDIR /app

# Copy the pom.xml and download dependencies (this helps in leveraging Docker cache)
COPY pom.xml .

# Download all dependencies (to avoid re-downloading every time code changes)
RUN mvn dependency:go-offline

# Copy the source code to the container
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests

# Use an official OpenJDK image to run the application
FROM openjdk:17-jdk-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the JAR file from the build stage
COPY --from=build /app/target/order-ms-*.jar /app/order-ms.jar

# Expose the port your app runs on (replace with your actual port)
EXPOSE 8080

# Command to run the application
ENTRYPOINT ["java", "-jar", "/app/order-ms.jar"]