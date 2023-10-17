FROM registry.redhat.io/ubi9/nodejs-18:latest AS web-builder

WORKDIR /opt/app-root

USER 0

RUN npm install --global yarn

COPY web/package*.json web/
COPY web/yarn.lock web/yarn.lock
COPY Makefile Makefile
RUN make install-frontend-ci-clean

COPY web/ web/
RUN make build-frontend

FROM registry.redhat.io/ubi9/go-toolset:1.19 as go-builder

WORKDIR /opt/app-root

COPY Makefile Makefile
COPY go.mod go.mod
COPY go.sum go.sum

RUN make install-backend

COPY cmd/ cmd/
COPY pkg/ pkg/

RUN make build-backend

FROM registry.redhat.io/ubi9/ubi-minimal

COPY --from=web-builder /opt/app-root/web/dist /opt/app-root/web/dist
COPY --from=go-builder /opt/app-root/plugin-backend /opt/app-root

ENTRYPOINT ["/opt/app-root/plugin-backend", "-static-path", "/opt/app-root/web/dist"]
