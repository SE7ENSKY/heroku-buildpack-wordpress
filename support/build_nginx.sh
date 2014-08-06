#!/bin/bash

set -e

if [ "$NGINX_VERSION" == "" ]; then
  echo "must set NGINX_VERSION, i.e NGINX_VERSION=1.7.4"
  exit 1
fi

if [ "$UPLOAD_TO" == "" ]; then
  echo "must set UPLOAD_TO, i.e. export UPLOAD_TO=ftp://user:pass@host/path"
  exit 1
fi

PCRE_VERSION=8.35

basedir="$( cd -P "$( dirname "$0" )" && pwd )"

# make a temp directory
tempdir="$( mktemp -t nginx_XXXX )"
rm -rf $tempdir
mkdir -p $tempdir
pushd $tempdir

# download and extract nginx
curl http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tgz
tar xzvf nginx.tgz

# download and extract pcre into contrib directory
pushd nginx-$NGINX_VERSION/contrib
curl ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-${PCRE_VERSION}.tar.gz -o pcre.tgz
tar zvxf pcre.tgz
popd

# build and package nginx for heroku
cd $tempdir/nginx-$NGINX_VERSION
./configure --prefix=/app/vendor/nginx \
  --with-pcre=contrib/pcre-${PCRE_VERSION} \
  --with-http_ssl_module \
  --with-http_gzip_static_module \
  --with-http_stub_status_module \
  --with-http_realip_module \
  && make install

compiled_nginx_file=nginx-$NGINX_VERSION-heroku.tar.gz
cd /app/vendor/nginx
tar -czvpf $tempdir/$compiled_nginx_file .

curl --upload-file $tempdir/$compiled_nginx_file $UPLOAD_TO/$compiled_nginx_file
