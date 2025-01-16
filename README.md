# Cross compilation container (powered by Gentoo)
This container sets up a minimal container with an ARM32v7 cross compiler and additional build tools.

## How to build
1. Make sure you have a decent cpu, enough RAM, and a lot of time to spare
2. Run `docker build -t localhost/crosstool:latest .`

## How to use
1. If you want to run the compiled ARM32v7 binaries, run `sudo ./binfmt.sh`
2. `docker run --rm -it -v /path/to/your/project:/project localhost/crosstool:latest`
3. `cd project`
4. `make build`
