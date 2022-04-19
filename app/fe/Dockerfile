# base image
FROM node:12.2.0

WORKDIR /app

# add `/app/node_modules/.bin` to $PATH
ENV PATH /app/node_modules/.bin:$PATH

# install and cache app dependencies
COPY package.json /app/package.json
RUN npm install
# RUN npm install -g @angular/cli@7.3.9

# add app
COPY . /app

EXPOSE 4200

# start app
CMD ng serve --host 0.0.0.0 --port 4200 --disableHostCheck true
