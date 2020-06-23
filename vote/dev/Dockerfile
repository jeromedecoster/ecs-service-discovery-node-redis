FROM node:14.3-slim AS build
WORKDIR /app
ADD package.json .
RUN npm install

FROM node:14.3-slim
WORKDIR /app
COPY --from=build /app .
ADD . .
EXPOSE 3000 35729
CMD ["./dev/cmd.sh"]
