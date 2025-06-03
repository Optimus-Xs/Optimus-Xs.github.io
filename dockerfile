FROM ruby:3.3
WORKDIR /home/Optimus-Xs.github.io

COPY . .
RUN chmod -R 777 . && \
    [ -f Gemfile.lock ] && rm Gemfile.lock || true && \
    bundle install

EXPOSE 4000
EXPOSE 35729

CMD ["jekyll", "serve", "--watch", "--livereload", "--force_polling", "--trace", "--incremental", "--host", "0.0.0.0"]