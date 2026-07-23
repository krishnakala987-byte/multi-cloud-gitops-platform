# Multi-stage build: ~300MB builder -> ~7MB distroless runtime, non-root.
# Zero Go dependencies, so no go.sum / module downloads needed at build time.
FROM golang:1.22-alpine AS build
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /cloud-atlas .

# Distroless static: no shell, no package manager, tiny attack surface.
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /cloud-atlas /cloud-atlas
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/cloud-atlas"]
