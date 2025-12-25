FROM wordpress:php8.2-apache

RUN apt-get update \
    && apt-get -y install vim zip unzip default-mysql-client \
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

# カスタムエントリーポイントを設定
ENTRYPOINT ["/usr/docker/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
