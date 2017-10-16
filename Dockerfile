FROM centos:7

LABEL maintainer="luigi.pertoldi@pd.infn.it"

USER root
WORKDIR /root

RUN yum install -y epel-release deltarpm \
	&& yum groupinstall -y "Development Tools" \
	&& yum install -y \
		htop zsh vim wget cmake \
		expat-devel xerces-c-devel fftw-devel \
		libXmu-devel libXi-devel libX11-devel libXext-devel libXft-devel libXpm-devel \
		libzip-devel mesa-libGLU-devel \
		libjpeg-devel libpng-devel

#RUN mkdir -p ranger \
#	&& wget -O- http://nongnu.org/ranger/ranger-stable.tar.gz \
#	| tar --strip-components 1 -xz -C "ranger" \
#	&& cd ranger && make install \
#	&& cd .. && rm -rf ranger

RUN dbus-uuidgen > /etc/machine-id

# install ROOT CERN from precompiled binary
# it will be installed in /opt/root

ENV PATH="/opt/root/bin:$PATH" \
	LD_LIBRARY_PATH="/opt/root/lib:$LD_LIBRARY_PATH" \
	MANPATH="/opt/root/man:$MANPATH" \
	PYTHONPATH="/opt/root/lib:$PYTHONPATH" \
	ROOTSYS="/opt/root"

RUN mkdir -p /opt/root \
	&& wget -O- https://root.cern.ch/download/root_v6.06.08.Linux-centos7-x86_64-gcc4.8.tar.gz \
	| tar --strip-components 1 -xz -C "/opt/root"

# compile and install CLHEP
# it will be installed in /opt/clhep

RUN mkdir -p src \
	&& wget -O- http://proj-clhep.web.cern.ch/proj-clhep/DISTRIBUTION/tarFiles/clhep-2.1.3.1.tgz \
	| tar --strip-components 2 -xz -C "src" \
	&& mkdir -p build \
	&& cd build \
	&& cmake -DCMAKE_INSTALL_PREFIX="/opt/clhep" --fail-on-missing ../src \
	&& cmake --build . -- -j"$(nproc)" \
	&& mkdir -p /opt/clhep \
	&& make install \
	&& cd .. && rm -rf src/* build/*

# compile and install geant4
# it will be installed in /opt/geant4

ENV PATH="/opt/geant4/bin:/opt/clhep/bin:$PATH" \
	LD_LIBRARY_PATH="/opt/geant4/lib64:/opt/clhep/lib:$LD_LIBRARY_PATH" \
	G4LEDATA="/opt/geant4/share/Geant4-9.6.4/data/G4EMLOW6.32" \
	G4LEVELGAMMADATA="/opt/geant4/share/Geant4-9.6.4/data/PhotonEvaporation2.3" \
	G4NEUTRONHPDATA="/opt/geant4/share/Geant4-9.6.4/data/G4NDL4.2" \
	G4NEUTRONXSDATA="/opt/geant4/share/Geant4-9.6.4/data/G4NEUTRONXS1.2" \
	G4PIIDATA="/opt/geant4/share/Geant4-9.6.4/data/G4PII1.3" \
	G4RADIOACTIVEDATA="/opt/geant4/share/Geant4-9.6.4/data/RadioactiveDecay3.6" \
	G4REALSURFACEDATA="/opt/geant4/share/Geant4-9.6.4/data/RealSurface1.0" \
	G4SAIDXSDATA="/opt/geant4/share/Geant4-9.6.4/data/G4SAIDDATA1.1"

RUN mkdir -p /opt/geant4 \
	&& wget -O- https://geant4.web.cern.ch/geant4/support/source/geant4.9.6.p04.tar.gz \
	| tar --strip-components 1 -xz -C "src" \
	&& cd build \
	&& cmake -DCMAKE_INSTALL_PREFIX="/opt/geant4" \
		-DGEANT4_USE_SYSTEM_CLHEP=ON \
		-DCLHEP_ROOT_DIR=/opt/clhep \
		-DGEANT4_USE_GDML=ON \
		-DGEANT4_USE_OPENGL_X11=ON \
		-DGEANT4_USE_RAYTRACER_X11=ON \
		-DGEANT4_INSTALL_DATA=ON \
		-DGEANT4_INSTALL_EXAMPLES=ON \
		--fail-on-missing \
		../src \
	&& cmake --build . -- -j"$(nproc)" \
	&& make install \
	&& cd .. && rm -rf src build

# compile and install the gerda software:
# some shell logic is needed to speed up the build with make -j"$(nproc)" 
# when an error occurs and thus Docker stops the build
#
# the software will be installed in /opt/gerdasw

COPY MGDO /root/MGDO
WORKDIR /root/MGDO
RUN mkdir -p /opt/gerdasw \\
	&& ./configure --enable-tam --enable-streamers --prefix="/opt/gerdasw"\
	&& make -j"$(nproc)" || true && make -j"$(nproc)" || true && make && make install \
	&& cd /root && rm -rf MGDO

# make the software visible

ENV PATH="/opt/gerdasw/bin:$PATH" \
	LD_LIBRARY_PATH="/opt/gerdasw/lib:$LD_LIBRARY_PATH"

COPY GELATIO /root/GELATIO
WORKDIR /root/GELATIO
RUN ./configure --prefix="/opt/gerdasw"\
	&& make -j"$(nproc)" || true && make -j"$(nproc)" || true && make && make install \
	&& cd /root && rm -rf GELATIO

COPY databricxx /root/databricxx
WORKDIR /root/databricxx
RUN ./autogen.sh && ./configure --prefix="/opt/gerdasw" \
	&& make -j"$(nproc)" && make install \
	&& cd /root && rm -rf databricxx

COPY gerda-ada /root/gerda-ada
WORKDIR /root/gerda-ada
RUN ./autogen.sh && ./configure --prefix="/opt/gerdasw" \
	&& make -j"$(nproc)" && make install \
	&& cd /root && rm -rf gerda-ada

COPY MaGe /root/MaGe
WORKDIR /root/MaGe
RUN ./configure --prefix="/opt/gerdasw" \
	&& make -j"$(nproc)" || true && make -j"$(nproc)" || true && make && make install \
	&& cd /root && rm -rf MaGe

# install dotfiles

#COPY local-env-skeleton /root/local-env-skeleton
#WORKDIR /root/local-env-skeleton
#RUN ./install-sh

WORKDIR /root
CMD /bin/zsh
