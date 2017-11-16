FROM centos:7

LABEL maintainer="luigi.pertoldi@pd.infn.it"

USER root
WORKDIR /root

RUN yum update -y && \
    yum install -y epel-release deltarpm && \
    yum groupinstall -y "Development Tools" && \
    yum install -y htop zsh vim wget cmake3 \
                   expat-devel xerces-c-devel fftw-devel \
                   libXmu-devel libXi-devel libX11-devel \
                   libXext-devel libXft-devel libXpm-devel \
                   libzip-devel mesa-libGLU-devel \
                   libjpeg-devel libpng-devel && \
    ln -s /usr/bin/cmake3 /usr/bin/cmake

RUN dbus-uuidgen > /etc/machine-id

# install ROOT CERN from precompiled binary
# it will be installed in /opt/root

ENV PATH="/opt/root/bin:$PATH" \
    LD_LIBRARY_PATH="/opt/root/lib:$LD_LIBRARY_PATH" \
    MANPATH="/opt/root/man:$MANPATH" \
    PYTHONPATH="/opt/root/lib:$PYTHONPATH" \
    ROOTSYS="/opt/root"

RUN mkdir -p /opt/root && \
    wget -O- https://root.cern.ch/download/root_v6.06.08.Linux-centos7-x86_64-gcc4.8.tar.gz \
    | tar --strip-components 1 -xz -C "/opt/root"

# compile and install CLHEP
# it will be installed in /opt/clhep

ENV CLHEP_BASE_DIR="/opt/clhep" \
    CLHEP_INCLUDE_DIR="/opt/clhep/include" \
    CLHEP_LIB_DIR="/opt/clhep/lib"

RUN mkdir -p src && \
    wget -O- http://proj-clhep.web.cern.ch/proj-clhep/DISTRIBUTION/tarFiles/clhep-2.3.4.4.tgz \
    | tar --strip-components 2 -xz -C "src" && \
    mkdir -p build && \
    cd build && \
    cmake -DCMAKE_INSTALL_PREFIX="/opt/clhep" \
          -DCMAKE_CXX_FLAGS=-std=c++11 \
          --fail-on-missing ../src && \
    cmake --build . -- -j"$(nproc)" && \
    mkdir -p /opt/clhep && \
    make install && \
    cd .. && rm -rf src/* build/*

# compile and install geant4
# it will be installed in /opt/geant4

ENV PATH="/opt/geant4/bin:/opt/clhep/bin:$PATH" \
    LD_LIBRARY_PATH="/opt/geant4/lib64:/opt/clhep/lib:$LD_LIBRARY_PATH" \
    G4LEDATA="/opt/geant4/share/Geant4-10.3.3/data/G4EMLOW6.50" \
    G4LEVELGAMMADATA="/opt/geant4/share/Geant4-10.3.3/data/PhotonEvaporation4.3.2" \
    G4NEUTRONHPDATA="/opt/geant4/share/Geant4-10.3.3/data/G4NDL4.5" \
    G4NEUTRONXSDATA="/opt/geant4/share/Geant4-10.3.3/data/G4NEUTRONXS1.4" \
    G4PIIDATA="/opt/geant4/share/Geant4-10.3.3/data/G4PII1.3" \
    G4RADIOACTIVEDATA="/opt/geant4/share/Geant4-10.3.3/data/RadioactiveDecay5.1.1" \
    G4REALSURFACEDATA="/opt/geant4/share/Geant4-10.3.3/data/RealSurface1.0" \
    G4SAIDXSDATA="/opt/geant4/share/Geant4-10.3.3/data/G4SAIDDATA1.1" \
    G4ENSDFSTATEDATA="/opt/geant4/share/Geant4-10.3.3/data/G4ENSDFSTATE2.1" \
    G4ABLADATA="/opt/geant4/share/Geant4-10.3.3/data/G4ABLA3.0"


RUN mkdir -p /opt/geant4 && \
    wget -O- http://cern.ch/geant4/support/source/geant4.10.03.p03.tar.gz \
    | tar --strip-components 1 -xz -C "src" && \
    cd build && \
    cmake -DCMAKE_INSTALL_PREFIX="/opt/geant4" \
          -DGEANT4_BUILD_CXXSTD=c++11 \
          -DGEANT4_USE_SYSTEM_CLHEP=ON \
          -DCLHEP_ROOT_DIR=/opt/clhep \
          -DGEANT4_USE_GDML=ON \
          -DGEANT4_USE_OPENGL_X11=ON \
          -DGEANT4_USE_RAYTRACER_X11=ON \
          -DGEANT4_INSTALL_DATA=ON \
          --fail-on-missing \
          ../src && \
    cmake --build . -- -j"$(nproc)" && \
    make install && \
    cd .. && rm -rf src build

# compile and install the gerda software:
# some shell logic is needed to speed up the build with make -j"$(nproc)" 
# when an error occurs and thus Docker stops the build
#
# the software will be installed in /opt/gerdasw

COPY MGDO /opt/gerdasw/src/MGDO
WORKDIR /opt/gerdasw/src/MGDO
RUN mkdir -p /opt/gerdasw && \
    ./configure --enable-tam --enable-streamers CXXFLAGS='-std=c++11' --prefix="/opt/gerdasw" && \
    make -j"$(nproc)" || true && \
    make -j"$(nproc)" || true && \
    make -j"$(nproc)" || true && \
    make && make install

# make the software visible

ENV PATH="/opt/gerdasw/bin:$PATH" \
    LD_LIBRARY_PATH="/opt/gerdasw/lib:$LD_LIBRARY_PATH" \
    MGDODIR="/opt/gerdasw/src/MGDO"

COPY GELATIO /opt/gerdasw/src/GELATIO
WORKDIR /opt/gerdasw/src/GELATIO
RUN ./configure CXX='g++ -std=c++11' --prefix="/opt/gerdasw" && \
#    make -j"$(nproc)" -k || true && \
#    make -j"$(nproc)" -k || true && \
#    make -j"$(nproc)" -k || true && \
    make && make install && \

ENV GELATIODIR="/opt/gerdasw/src/GELATIO"

COPY databricxx /opt/gerdasw/src/databricxx
WORKDIR /opt/gerdasw/src/databricxx
RUN ./autogen.sh && ./configure CXXFLAGS='-std=c++11' --prefix="/opt/gerdasw" && \
    make -j"$(nproc)" && make install && \
    rm -rf /opt/gerdasw/src/databricxx

COPY gerda-ada /opt/gerdasw/src/gerda-ada
WORKDIR /opt/gerdasw/src/gerda-ada
RUN ./autogen.sh && ./configure CXXFLAGS='-std=c++11' --prefix="/opt/gerdasw" && \
    make -j"$(nproc)" && make install && \
    rm -rf /opt/gerdasw/src/gerda-ada

COPY MaGe /opt/gerdasw/src/MaGe
WORKDIR /opt/gerdasw/src/MaGe
RUN ./configure CXXFLAGS='-std=c++11' --prefix="/opt/gerdasw" && \
    make -j"$(nproc)" || true && \
    make -j"$(nproc)" || true && \
    make -j"$(nproc)" || true && \
    make && make install && \
    rm -rf /opt/gerdasw/src/MaGe

ENV GERDA_ANA_SANDBOX="/common/sw-other/gerda-ana-sandbox" \
    MGGERDAGEOMETRY="/common/sw-other/gerdageometry" \
    MGGENERATORDATA="/common/sw-other/gerda-ana-sandbox/BackgroundModel/MaGe_Datafiles" \
    MU_CAL="/common/sw-other/gerda-metadata/config/_aux/geruncfg"

# install dotfiles

COPY local-env-skeleton /root/local-env-skeleton
WORKDIR /root/local-env-skeleton
RUN ./install-sh

WORKDIR /root
RUN rm -rf .gitconfig local-env-skeleton && \
    sed -i '/ZSH=<.../c\ZSH=/root/.oh-my-zsh' .zshrc && \
    sed -i '/DEFAULT_USER="<...>"/c\DEFAULT_USER=root' .zshrc && \
    sed -i '29 i POWERLEVEL9K_HOST_TEMPLATE="gerda-sw"' .zshrc

CMD /bin/zsh
