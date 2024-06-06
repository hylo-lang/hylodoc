FROM alexcazacu1/hylo-base-image-cicd:1.0.4
# This image is built on top of the base hylo image which is available on the official hylo repo, or at `source.Dockerfile`.

# Install node 22
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    build-essential

# Add NodeSource APT repository for Node 22.x (replace with the correct URL if available)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash -

# Install Node.js and npm
RUN apt-get install -y nodejs

# Verify installation
RUN node -v && npm -v