# This image won't be shipped with our final container
# we only use it to compile our app.
FROM node:16-alpine as build
ENV PATH /app/node_modules/.bin:$PATH
WORKDIR /app
COPY . /app
RUN npm install
RUN npm run build

# production image using nginx and including our
# compiled app only. This is called multi-stage builds
FROM nginx:1.21.6-alpine
COPY --from=build /app/build /usr/share/nginx/html
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx/nginx.conf /etc/nginx/conf.d
EXPOSE 8000
CMD ["nginx", "-g", "daemon off;"]