FROM node

RUN mkdir /code
# ADD src/*.bs.js /code/
ADD . /code/
WORKDIR /code
ENV PATH=/code/node_modules/.bin:$PATH

RUN yarn install -D

CMD ["node", "/code/src/Main.bs.js"]
