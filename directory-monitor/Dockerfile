# Use a minimal Python image
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Copy the script into the container
COPY directory_monitor.py .

# Create the watched directory
RUN mkdir /watched

RUN python -m pip install requests

# Run the script
CMD ["python", "directory_monitor.py"]