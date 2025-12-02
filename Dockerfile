FROM node:18-alpine

COPY package.json yarn.lock ./

RUN yarn install

COPY . .

EXPOSE 3000

CMD yarn typeorm migration:run && yarn start