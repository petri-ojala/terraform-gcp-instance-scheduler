#
# Compile code

FROM golang:1.14 AS builder

WORKDIR /build
COPY scheduler.go .
RUN go get -d -v ./...
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -a -o scheduler

#
# Build final image

#FROM scratch AS final
FROM gcr.io/google.com/cloudsdktool/cloud-sdk:alpine AS final

WORKDIR /
COPY --from=builder /build/scheduler .
CMD [ "./scheduler" ]
