docker build -t nas2docker/ffmpeg_grpc_ssh:1.0 --build-arg http_proxy=$http_proxy --build-arg https_proxy=$https_proxy .

docker run -it -p 2222:22 nas2docker/ffmpeg_grpc_ssh:1.0