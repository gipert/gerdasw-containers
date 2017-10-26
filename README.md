# gerda-sw-docker
[Docker](https://www.docker.com) containers with a basic installation of the GERDA software.
### Notes:
* MaGe is checked out at `GERDAphaseII` branch
* Repositories which need constant updates (like e.g. metadata repositories) are not included in the images. They can be included e.g. inside an externally mounted volume (see below)
* Let's take advantage of git! Open a new branch if you want to provide an image with different features
* Use git tags to distinguish between software versions?

### Use instructions:
**Clone with `--recursive`** (note: requires access to GERDA's private repositories).

Images can be build up with:
```shell
$ cd gerda-sw-docker
$ sudo docker build . -t gerda-sw
```
A call to `docker run gerda-sw` with no arguments spawns a zsh shell by default:
```shell
$ sudo docker run \
  -i -t \
  -h gerda-sw \
  gerda-sw
```
The `-i` and `-t` flags allow to start an interactive session inside a new tty (mandatory to spawn the shell). Optional: `-h gerda-sw` sets the container's hostname to 'gerda-sw'.

Any other custom command can be injected inside the container, e.g.:
```shell
$ sudo docker run gerda-sw MaGe
```

To mount a folder (`/path/to/src`) inside the container (mount point: `/path/to/dest`) run it with:
```shell
$ sudo docker run \
  -v /path/to/src:/path/to/dest \
  gerda-sw <...>
```
### Enable X11 forwarding
HELP WANTED
