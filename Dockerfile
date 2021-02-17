FROM golang
WORKDIR /
ADD helloWorld /
EXPOSE 8083
ENTRYPOINT ["./helloWorld"]
