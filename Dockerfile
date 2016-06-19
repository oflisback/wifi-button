# Use Node v4 as the base image.
FROM node:4

# Add everything in the current directory to our image, in the 'app' folder.
ADD . /app

# Install dependencies
RUN cd /app; npm install --production

# Run our app.
CMD ["node", "/app/button-subscriber.js"]  

