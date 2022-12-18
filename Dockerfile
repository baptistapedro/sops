FROM ubuntu:20.04 as builder

RUN ln -snf /usr/share/zoneinfo/$CONTAINER_TIMEZONE /etc/localtime && echo $CONTAINER_TIMEZONE > /etc/timezone

RUN DEBIAN_FRONTEND=noninteractive \
	apt-get update && apt-get install -y build-essential tzdata pkg-config \
	wget clang git

RUN wget https://go.dev/dl/go1.19.1.linux-amd64.tar.gz
RUN rm -rf /usr/local/go && tar -C /usr/local -xzf go1.19.1.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

ADD . /sops
WORKDIR /sops
ADD fuzzers/fuzz_decryptmsg.go ./fuzzers/
WORKDIR ./fuzzers/
RUN go mod init myfuzz
RUN go mod tidy
RUN go install github.com/dvyukov/go-fuzz/go-fuzz@latest github.com/dvyukov/go-fuzz/go-fuzz-build@latest
RUN go get github.com/dvyukov/go-fuzz/go-fuzz-dep
#RUN go get github.com/mozilla/sops/v3@latest
RUN /root/go/bin/go-fuzz-build -libfuzzer -o harness.a
RUN clang -fsanitize=fuzzer harness.a -o fuzz_decryptmsg

FROM ubuntu:20.04
COPY --from=builder /sops/fuzzers/fuzz_decryptmsg /
RUN mkdir /testsuite/
RUN echo "ENC[AES256_GCM,data:oYyi,iv:MyIDYbT718JRr11QtBkcj3Dwm4k1aCGZBVeZf0EyV8o=,tag:t5z2Z023Up0kxwCgw1gNxg==,type:str]" > /testsuite/s1

ENTRYPOINT []
CMD ["/fuzz_decryptmsg"]
