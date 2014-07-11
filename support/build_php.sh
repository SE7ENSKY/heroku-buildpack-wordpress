#!/bin/bash

set -e

if [ "$PHP_VERSION" == "" ]; then
  echo "must set PHP_VERSION, i.e PHP_VERSION=5.5.14"
  exit 1
fi

if [ "$UPLOAD_TO" == "" ]; then
  echo "must set UPLOAD_TO, i.e. export UPLOAD_TO=ftp://user:pass@host/path"
  exit 1
fi

basedir="$( cd -P "$( dirname "$0" )" && pwd )"

# make a temp directory
tempdir="$( mktemp -t php_XXXX )"
rm -rf $tempdir
mkdir -p $tempdir
pushd $tempdir

# download and extract php
curl -L https://github.com/php/php-src/archive/php-$PHP_VERSION.tar.gz -o php.tgz
tar xzvf php.tgz

cd php-src-php-$PHP_VERSION

./buildconf --force
./configure  --prefix=/app/vendor/php \
  --with-mysql \
  --with-pdo-mysql \
  --with-iconv \
  --with-gd \
  --with-curl=/usr/lib \
  --with-config-file-path=/app/vendor/php \
  --with-openssl \
  --enable-fpm \
  --with-zlib \
  --enable-mbstring \
  --disable-debug \
  --disable-rpath \
  --enable-gd-native-ttf \
  --enable-inline-optimization \
  --with-bz2 \
  --enable-pcntl \
  --enable-mbregex \
  --with-mhash \
  --enable-zip \
  --with-pcre-regex \
  --enable-libxml \
  --with-gettext \
  --with-jpeg-dir \
  --with-mysqli \
  --with-pcre-regex \
  --with-png-dir \
  --enable-ftp \
  --without-pdo-sqlite \
  --without-sqlite3 \
&& make install \
&& /app/vendor/php/bin/pear config-set php_dir /app/vendor/php \
&& yes '' | /app/vendor/php/bin/pecl install memcache

compiled_php_file=php-$PHP_VERSION-with-fpm-heroku.tar.gz
cd /app/vendor/php
tar -czvpf $tempdir/$compiled_php_file .

curl --upload-file $tempdir/$compiled_php_file $UPLOAD_TO/$compiled_php_file
