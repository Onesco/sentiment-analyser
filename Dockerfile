# Dockerfile

FROM node:18-alpine

# Set working directory
WORKDIR /usr/src/app

# Install dependencies
COPY package*.json ./
RUN npm install

# Copy source code
COPY . .

# Expose app port (adjust as needed)
EXPOSE 3000

# Start the application
CMD ["npm", "run", "start"]