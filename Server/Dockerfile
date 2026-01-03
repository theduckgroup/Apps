FROM node:24-alpine

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy dependency files first to leverage build cache
COPY package*.json ./

# Copy the rest of your application code
COPY . .

# Install production dependencies only
RUN npm ci --only=production
# RUN npm ci

# Expose the port your Express app listens on (default is often 3000)
EXPOSE 8021

# 7. Define the command to start your app
CMD ["npm", "start"]
