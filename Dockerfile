FROM golang as build
COPY sianrelease.go .
RUN  go build sianrelease.go 

FROM scratch
COPY --from=build /go/sianrelease /sianrelease
CMD ["/sianrelease"]