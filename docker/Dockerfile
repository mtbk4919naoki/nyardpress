FROM wordpress:php8.2-apache

RUN apt-get update \
    && apt-get -y install default-mysql-client \
    # EWWW Image Optimizer用の画像圧縮ツールをインストール
    && apt-get -y install jpegoptim optipng gifsicle webp libjpeg-turbo-progs \
    # PHP画像処理拡張機能をインストール（GDのみ）
    && apt-get -y install libfreetype6-dev libjpeg62-turbo-dev libpng-dev libwebp-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) gd \
    && rm -rf /var/lib/apt/lists/* \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer --version

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \
    && wp --info || echo "wp check skipped"

# ComposerでCarbon Fieldsをインストールできるように設定
# wpackagistリポジトリをグローバルに設定（WordPressプラグイン/テーマ用）
RUN composer global config repositories.wpackagist composer https://wpackagist.org || true

# binディレクトリ内のすべてのスクリプトをコピー
COPY docker/bin/ /usr/docker/bin/
RUN chmod +x /usr/docker/bin/*

# PATHを設定
ENV PATH=$PATH:/usr/docker/bin

# 開発環境用: PHPエラーログを標準出力にも出力するように設定
# php.iniの設定を変更（開発環境用）
RUN echo "log_errors = On" >> /usr/local/etc/php/conf.d/docker-php-debug.ini && \
    echo "error_log = /proc/self/fd/2" >> /usr/local/etc/php/conf.d/docker-php-debug.ini && \
    echo "display_errors = On" >> /usr/local/etc/php/conf.d/docker-php-debug.ini && \
    echo "display_startup_errors = On" >> /usr/local/etc/php/conf.d/docker-php-debug.ini && \
    echo "error_reporting = E_ALL" >> /usr/local/etc/php/conf.d/docker-php-debug.ini

# アップロードファイルサイズの上限を1024MBに設定
RUN echo "upload_max_filesize = 1024M" >> /usr/local/etc/php/conf.d/docker-php-upload.ini && \
    echo "post_max_size = 1024M" >> /usr/local/etc/php/conf.d/docker-php-upload.ini && \
    echo "max_execution_time = 300" >> /usr/local/etc/php/conf.d/docker-php-upload.ini && \
    echo "max_input_time = 300" >> /usr/local/etc/php/conf.d/docker-php-upload.ini && \
    echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/docker-php-upload.ini

# カスタムエントリーポイントを設定
ENTRYPOINT ["/usr/docker/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
