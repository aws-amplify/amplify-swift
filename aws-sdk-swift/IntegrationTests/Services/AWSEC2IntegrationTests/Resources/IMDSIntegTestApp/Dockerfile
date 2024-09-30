# Can also be set to a specific swift version like swift:5.7
FROM swift:latest

# Install dependencies to container
RUN apt-get update && apt-get install -y libssl-dev

# Set our working directory
WORKDIR /app

# Copy the entire Swift project into the Docker image
COPY . .

# Build the swift application in release mode
RUN swift build --configuration release

# Command to run the test application
CMD [".build/release/IMDSIntegTestApp"]
