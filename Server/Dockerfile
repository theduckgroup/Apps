# compose.yaml is not used by Digital Ocean, only for local testing

# For local testing, in .env.dev-local set PORT to 8080
# This is the same as Digital Ocean

# To test: docker compose up --build

FROM node:24-alpine

# Install mongodb-database-tools
RUN apk add --no-cache mongodb-tools

# Can't see the output of this
# RUN mongodump --version

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy dependency files first to leverage build cache
COPY package*.json ./

# Install production dependencies only
RUN npm ci --only=production
# RUN npm ci

# Copy the rest of your application code
COPY . .

# Expose the port Express app listens on
EXPOSE 8080

# Define the command to start your app
# CMD ["npm", "start"] also works
CMD ["npx", "tsx", "src/index.ts"]
