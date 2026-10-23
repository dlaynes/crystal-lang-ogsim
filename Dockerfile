FROM crystallang/crystal:1.13.3-alpine

WORKDIR /app

COPY . .

RUN crystal build main.cr --release -o ogame-sim

CMD ["./ogame-sim"]
