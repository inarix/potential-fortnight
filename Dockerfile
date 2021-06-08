FROM argoproj/argocli:v3.0.7 AS argo-builder
FROM alpine:3.11

LABEL version="1.0.0"
LABEL repository="https://github.com/inarix/potential-fortnigh"
LABEL homepage="https://github.com/inarix/potential-fortnigh"
LABEL maintainer="Alexandre Saison <alexandre.saison@inarix.com>"

RUN apk add --no-cache ca-certificates curl jq bash groff less python binutils py-pip  mailcap 

# Install AWS AUTH AUTHENTICATOR
RUN curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/aws-iam-authenticator &&\
    chmod +x ./aws-iam-authenticator &&\
    mkdir -p $HOME/bin && cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$PATH:$HOME/bin &&\
    echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc &&\
    source ~/.bashrc

# Install Glib 'cause does aws install does not work on ALPINE
RUN pip install --upgrade awscli s3cmd python-magic && \
    apk -v --purge del py-pip

COPY --from=argo-builder /bin/argo /usr/local/bin/argo
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
