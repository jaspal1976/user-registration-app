FROM node:18-alpine

WORKDIR /app

# Enable corepack for Yarn 4
RUN corepack enable && corepack prepare yarn@stable --activate

# Copy package files
COPY package.json yarn.lock* ./

# Install dependencies (Yarn 4 will handle lockfile automatically)
RUN yarn install

# Copy application code
COPY . .

# Expose port
EXPOSE 3000

# Start development server
CMD ["yarn", "dev", "--host", "0.0.0.0"]
