#
# Compile code

FROM golang:1.14 AS builder

WORKDIR /build
COPY main.go .
RUN go get -d -v ./...
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -a -o main

#
# Build final scratch image with binary

#FROM scratch AS final
FROM gcr.io/google.com/cloudsdktool/cloud-sdk:alpine AS final

#ENV scheduler_projects=pojala-gcp-playground
#ENV scheduler_zones=europe

WORKDIR /
COPY --from=builder /build/main .
CMD [ "./main" ]
