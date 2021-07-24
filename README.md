
# Docker BuildKit Buildx - the command line in front of BuildKit

--------------------------------------------------------------

## About This Project

This project was to get around the problem of how to create multi-architectured images without making lots of different tags and images. The automation currently makes this look like one single image in your repository. Buildx is a Docker CLI plugin which extends the Docker build command and provides some additional features. These are provided by the Moby Project which is a new build mechanism in Docker.

Using these new features you can carry out builds on multi-nodes, different hosts and new build functionality like a cache mechanism which is now a built in feature.

Let's start with sianrelease.go, a basic hello world program in Go which is hosted on my OS architecture remotely.

```sh
go build sianrelease.go
```

```sh
./sianrelease
```

This should return `I am MyMac.local hosting sianrelease on darwin/amd64`
The script has created a Dockerfile with a template which includes a multi-stage build in Golang.

```sh
docker build -t sianrachel/test .
```

The code on my machine is Dockerised. I have a Docker image which prints my container id which is the hostname. It's running in a Linux container on amd64

```sh
docker run sianrachel/test
```

If we had to build the same code for a different architecture, say Python 3.8.x, I would have to prepare a manifest file for this, add Docker images to manifest list and push to Docker Hub.

One of the features of builds is that it helps you to build Docker images for multi platform and therefore multi architecture.

Note that you need Docker 19.03 or higher installed on your machine.

If you are on a stable release of Docker, you will have to manually add Docker-buildx and Docker-app as CLI plugins.

```sh
docker plugin ls
```

Check if you have `docker-buildx`, `docker-app`, and `cli-plugins` installed.

```sh
ls ~/.docker/cli-plugins
```

If you don't, here is how to install Docker-buildx manually navigate to build GitHub as you need to manually install the CLI plugin if you are running a stable version of Docker.

<https://github.com/Docker/buildx/releases/tag/v0.5.1>

### Manual Mac Installation

```sh
export DOCKER_BUILDKIT=1
```

```sh
docker build --platform=local -o . git://github.com/docker/buildx
```

```sh
mkdir -p ~/.docker/cli-plugins
```

```sh
mv buildx ~/.docker/cli-plugins/docker-buildx
```

```sh
ls ~/.docker/cli-plugins
```

Change the permission to execute

```sh
chmod a+x ~/.docker/cli-plugins/docker-buildx
```

List plugins

```sh
ls ~/.docker/conf/cli-plugins
```

Enable docker-app in the CLI

```sh
DOCKER_CLI_EXPERIMENTAL=enabled
```

```sh
export OSTYPE="$(uname | tr A-Z a-z)"
```

Download your OS tarball

```sh
curl -fsSL --output "/tmp/docker-app-${OSTYPE}.tar.gz" "https://github.com/docker/app/releases/download/v0.8.0/docker-app-${OSTYPE}.tar.gz" tar xf "/tmp/docker-app-${OSTYPE}.tar.gz" -C /tmp/
```

Install as a Docker CLI plugin

```sh
mkdir -p ~/.docker/cli-plugins && cp "/tmp/docker-app-plugin-${OSTYPE}" ~/.docker/cli-plugins/docker-app
```

List CLI-plugins

```sh
ls ~/.docker/cli-plugins/
```

Buildx has a command called `default builder` build which is the same functionality as Docker build. This uses the Docker driver.

This uses an embedded library in Dockerd which has a storage mechanism called moby storage. It doesn’t support multi-platform build at this time so we need to create a new builder.

Create a new driver type called container and giving my builder a name `dockerbuilder`

```sh
docker buildx create --driver docker-container --name dockerbuilder
```

```sh
docker buildx inspect --bootstrap
```

```sh
docker buildx ls
```

The Docker build project runs itself as a backend Docker container - but at this point there are no containers running.

Let's switch to the builder we created:

```sh
docker buildx use dockerbuilder
```

This builds those three images simultaneously in a parallel build on your machine. You could also point all three builds to execute on a remote node; all you would need to do is add a new builder which points to the remote node. This is also pushing the images to Docker Hub.

### Recap

1. We ran a single cmd line which builds the same app across different architectures in parallel

2. If you wanted this could be pointed at remote engines and not just your local Docker machine

3. This one-liner also does a simultaneous push to a registry depending on if the build is successful

4. When all the created images are built, this would create a manifest file for you that is pushed to the Docker Hub

5. Manifest files are a bill of materials for the Docker images which capture the basic architecture pattern or platform. When you pull an alpine image it pulls down the specific image for what you are operating - eg a Python 3.8.8 - and all this information is stored in a manifest file

Let's build!

```sh
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t sianrachel/sianrelease:multiarc . --push
```

```sh
docker buildx ls
```

This is now running buildkit in the background for you, but the command line has changed - you don't need to set an environment variable anymore, you are using buildx to do that for you. The entire buildkit is running in a container.

Check that the images were pushed. If not, run long build command again.

You can see that as layers are exporting it is expanding and also pushing the manifest file.

### Docker imagetools

```sh
docker buildx imagetools inspect sianrachel/sianrelease:multiarc
```

This will lift and show your Docker images that were pushed to Docker Hub.

This should show three images listed that have multi arc support. This is the information which is included in a manifest. It is worth noting that Docker does figure out which architecture you are working on and compiles the manifest accordingly. It finds the tagged image for that particular architecture, so you don't have to specify this manually. This supercedes the old manual setting of the environment variable.

### Resources

<https://github.com/docker/buildx>
