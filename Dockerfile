FROM alpine:3.4

# ALPINE DEV + GHC
RUN echo "https://s3-us-west-2.amazonaws.com/alpine-ghc/7.10" >> /etc/apk/repositories
ADD https://raw.githubusercontent.com/mitchty/alpine-ghc/master/mitch.tishmack%40gmail.com-55881c97.rsa.pub \
    /etc/apk/keys/mitch.tishmack@gmail.com-55881c97.rsa.pub
RUN apk update
RUN apk add alpine-sdk linux-headers musl-dev gmp-dev zlib-dev ghc git

# FIX https://bugs.launchpad.net/ubuntu/+source/gcc-4.4/+bug/640734
WORKDIR /usr/lib/gcc/x86_64-alpine-linux-musl/5.3.0/
RUN cp crtbeginT.o crtbeginT.o.orig
RUN cp crtbeginS.o crtbeginT.o

# UPX
ADD https://github.com/lalyos/docker-upx/releases/download/v3.91/upx /usr/local/bin/upx
RUN chmod 755 /usr/local/bin/upx

# BOOTSTRAP
ADD https://s3.amazonaws.com/static-stack/stack-1.1.2-x86_64 /usr/local/bin/stack
RUN chmod 755 /usr/local/bin/stack

# STACK
ADD ./ /usr/local/src/stack/
WORKDIR /usr/local/src/stack
RUN stack                                            \
    --jobs $(cat /proc/cpuinfo|grep processor|wc -l) \
    --stack-yaml stack-static.yaml                   \
    install
RUN upx -o ./stack -q --best --ultra-brute ~/.local/bin/stack
RUN install ./stack /usr/local/bin/

# CLEANUP
WORKDIR /
RUN rm -rf ~/.stack ~/.local /usr/local/src/stack
