FROM node:14-slim

WORKDIR /usr/src/app
COPY package*.json ./

RUN npm install

USER node 
EXPOSE 3000
CMD ["npm", "start"]
