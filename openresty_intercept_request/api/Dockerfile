FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm i --only=production

COPY . .

EXPOSE 3000

CMD ["npm", "start"]

