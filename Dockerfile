FROM mcr.microsoft.com/dotnet/core/aspnet:2.2-bionic as builder
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
     libpng-dev libgif-dev git autoconf libtool automake build-essential gettext libglib2.0-dev libcairo2-dev libtiff-dev libexif-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/share
RUN git clone https://github.com/mono/libgdiplus

# HACK: patch max memory size
WORKDIR /usr/local/share/libgdiplus/src
RUN sed -i 's/1024/10240/g' region-bitmap.h

WORKDIR /usr/local/share/libgdiplus
RUN ./autogen.sh \
    && make \
    && make install

WORKDIR /usr/local/share
RUN rm -r libgdiplus

FROM mcr.microsoft.com/dotnet/core/aspnet:2.2-bionic
RUN echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula \
    select true | debconf-set-selections
RUN apt-get update \
    && apt-get install -y --no-install-recommends ttf-mscorefonts-installer gss-ntlmssp libc6-dev \
     libgif-dev libglib2.0-dev libcairo2-dev libtiff-dev libexif-dev language-pack-ru gnupg1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* 
COPY --from=builder /usr/local/lib/libgdiplus* /usr/lib/

# Установка локализации в контейнере
ENV LANGUAGE ru_RU.UTF-8
ENV LANG ru_RU.UTF-8
ENV LC_ALL ru_RU.UTF-8
RUN echo "ru_RU.CP866 IBM866" >> /etc/locale.gen \
    && locale-gen

# Очищаем предопределенные адреса прослушивания ASP.NET Core, чтобы не было warning-ов при старте сервисов.
ENV ASPNETCORE_URLS=
