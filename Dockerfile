FROM node

RUN mkdir /code
# ADD src/*.bs.js /code/
ADD . /code/
WORKDIR /code

RUN yarn install -D

CMD ["node", "/code/src/Demo.bs.js"]
