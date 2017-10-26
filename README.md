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
## Enable X11 forwarding
### Mac OSX:
Make sure you have XQuartz installed and running. First get your IP address:
```shell
$ ip=$(ifconfig en0 | grep inet | awk '$1=="inet" {print $2}')
```
Then add your IP adress to the list allowed to make connections to the X server using `xhost`:
```shell
$ xhost +$(ip)
```
Finally run the container setting the correct `DISPLAY` variable, for example to launch `interface` run:
```shell
$ docker run -e DISPLAY=$(ip):0 gerda-sw interface
```
**N.B.**: the `xhost +$(ip)` instruction grants access to the X server for the specified `ip` address. This could expose your system to security holes if, for example, your IP address gets renewed or you switch network and forget to remove the old IP from the `xhost` list. Be sure to keep your `xhost` list clean!
