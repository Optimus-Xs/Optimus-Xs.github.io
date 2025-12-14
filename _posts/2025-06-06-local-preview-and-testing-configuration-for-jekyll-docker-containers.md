---
layout: post
title: Jekyll 的本地预览和测试 Docker 容器配置
date: 2025-06-06 10:45 +0800
categories: [Tech Projects]
tags: [Docker, Jekyll, Ruby]
---

## Jekyll 简介
> Jekyll 是一个简单、博客形态的静态网站生成器（Static Site Generator, SSG）

核心特点:

- **静态网站生成器**: 它的核心功能是接收纯文本内容（例如 Markdown 或 Textile 格式的文件）以及模板（使用 Liquid 模板语言），然后通过处理这些文件，生成一个完整的、可发布的静态 HTML 网站。
- **无需数据库**: 与 WordPress 或 Drupal 等需要数据库和后端处理的动态网站系统不同，Jekyll 生成的网站是纯静态文件（HTML, CSS, JavaScript, 图像），因此部署简单、加载速度快、安全性高。
- **内容为中心**: 它鼓励专注于使用喜欢的标记语言撰写内容，而不是花费时间在复杂的配置和数据库维护上。
- **与 GitHub Pages 集成**: Jekyll 内置对 GitHub Pages 的支持。这意味着您可以将 Jekyll 网站的源代码托管在 GitHub 上，并利用 GitHub Pages 的服务免费发布您的网站、博客或项目页面。

## Jekyll 项目配置
下面的配置都以Jekyll的[Chirpy主题](https://github.com/cotes2020/jekyll-theme-chirpy)的启动模板[Chirpy-Starter](https://github.com/cotes2020/chirpy-starter)为例:

首先 Clone [Chirpy-Starter](https://github.com/cotes2020/chirpy-starter) 仓库到本地

```bash
git clone https://github.com/cotes2020/chirpy-starter.git
```

然后根据需求修改 `assets目录`, `_tab目录`, `_data目录`以及`_config.yml` 中的配置信息, 完成Jekyll的定制: 

- **assets目录**: 主要包括Chirpy主题运行所需的静态资源（库/插件/网页字体/网页图标等）
- **_tab目录**: 定制导航栏的信息
- **_data目录**: 网站内的外部分析链接以及联系方式信息的数据
- **_config.yml**: Jekyll 网站编译, 运行, 外部系统配置等全局配置文件

这里就已经完成了 Jekyll 项目配置, 常规情况下就可以直接在物理机安装依赖让后启动 Jekyll 预览了, 但是这里我们选择在后续步骤中在容器环境里完成项目的依赖安装和启动

## Docker 容器化配置
Jekyll 是一个使用Ruby开发的静态网站生成器, 所以它的项目结构也和标准的Ruby项目类似, 我们可以直接使用Ruby的基础镜像配置Jekyll的依赖环境并启动应用

但是考虑到我们在长期使用情况下, 一般只会修改`_post`目录下的文章信息, 而不会经常修改其他项目配置, 所以这里我们把容器化的应用划分为两个场景:

- **开发环境**: 针对调试Jekyll项目本身, 升级Jekyll以及主题版本, 增加插件, 修改网站生成配置的情况使用
- **生产环境**: 对开发环境调试完成的项目配置直接生成镜像, 后续写作过程中将`_post`目录映射到容器内并启动Jekyll预览服务器预览, 这个场景下只需要专注`_post`文章内容本身, 而不关系Jekyll的配置, 专注写作场景

### 开发环境容器配置
开发环境下, 我们需要关注的是Jekyll项目的配置信息, 依赖管理, 以及插件等

这个情况下我们可以直接使用 [Ruby](https://hub.docker.com/_/ruby) 作为基础镜像, 将项目的所以文件映射到容器内, 方便我们直接调试配置, 依赖, 并且能直接观察到针对网站本身的修改效果

启动容器的Docker compose 配置如下:

```yml
# dev env for Jekyll or theme upgrade
services:
  jekyll:
    image: ruby:3.3
    container_name: optimus-blog-dev
    volumes:
      - ./:/home/Optimus-Xs.github.io/
    ports:
      - "4000:4000" ## 预览端口
      - "35729:35729" ## 动态加载的调试端口
    entrypoint: [ "/bin/bash" ]
    stdin_open: true
    tty: true
```
{: file="docker-compose-dev.yml" }

这个时候容器已经启动, 但是Jekyll服务器本身还没有启动, 所以我们需要进入容器内部执行 Ruby 的依赖安装, Jekyll 服务器启动等操作

通过以下目录进入容器内部的终端: 

```bash
docker exec -it optimus-blog-dev bash
```

然后进入容器内的项目目录:

```bash
cd /home/Optimus-Xs.github.io/
```

这是就可以像普通物理机中一样的操作方法来处理 Jekyll 这个 Ruby 项目了:

安装 Jekyll 所需的 Ruby 项目依赖

```bash
# 1. 递归地将当前目录所有文件和子目录的权限设置为 777
chmod -R 777 .

# 2. 在更新依赖后需要删除 Gemfile.lock
#   先检查 Gemfile.lock 文件是否存在，如果存在则删除, 
if [ -f Gemfile.lock ]; then
    rm Gemfile.lock
fi

# 3. 安装 Ruby 项目依赖
bundle install
```

安装完成依赖后就可以启动 Jekyll 的预览服务器了

```bash
jekyll serve --watch --livereload --force_polling --trace --incremental --host 0.0.0.0
```

启动完成后就能在物理机中通过 `http:127.0.0.1:4000/` 预览到 Jekyll 生成的网站效果了

启动参数的含义如下:

- `jekyll serve` **核心命令**： 启动一个本地Web服务器，用于预览您的静态网站。它会先构建（build）网站，然后运行服务器。
- `--watch` **文件监控**： 启用对源文件（如 `_posts`、`_layouts` 等）的自动监控。当文件发生变化时，Jekyll 会自动重新生成网站内容。
- `--livereload` **浏览器热重载**： 结合 `--watch` 使用。当网站内容重新生成后，它会向浏览器发送信号，使浏览器自动刷新页面，无需手动操作。
- `--force_polling` **强制轮询**： 强制文件系统监控使用轮询（polling）而非系统事件（如 inotify）。在 Docker 或虚拟机等共享文件系统的环境中，系统事件经常无法正常工作，因此强制轮询是解决文件变动无法触发重新构建的常用方法。
- `--trace` **显示完整错误**： 在发生错误时，显示完整的 Ruby 堆栈跟踪（stack trace），这对于调试构建问题非常有用。
- `--incremental` **增量构建**： 启用增量构建。Jekyll 只会重新构建自上次生成以来发生变化的文件，可以显著加快构建速度，尤其适用于大型网站。
- `--host 0.0.0.0` **绑定地址**： 指定Web服务器绑定的IP地址。在 Docker 环境中，`0.0.0.0` 表示绑定到所有可用网络接口。这是必须的，否则服务器默认只会绑定到 `127.0.0.1`（`localhost`），外部（或宿主机）将无法访问容器内的服务。

> 如果需要增加其他的依赖, 或者想升级 Jekyll, 或者升级或者修改 Jekyll 主题, 只需要修改 `Gemfile` 然后按照需求修改项目内的配置
>
> 然后继续在容器内使用 `bundle install` 按照依赖然后重启 Jekyll 服务器就能在 `http:127.0.0.1:4000/` 预览到新的网站效果了
{: .prompt-tip }

### 生产环境容器配置
在开发环境完成了 Jekyll 项目的所有配置和依赖调整后, 我们就可以考虑构建标准镜像在写作的时候使用了

首先我们需要准备一个 Dockerfile 用于生成镜像, 和一个

```dockerfile
FROM ruby:3.3
WORKDIR /home/Optimus-Xs.github.io

COPY . .
RUN chmod -R 777 . && \
    [ -f Gemfile.lock ] && rm Gemfile.lock || true && \
    bundle install

EXPOSE 4000
EXPOSE 35729

CMD ["jekyll", "serve", "--watch", "--livereload", "--force_polling", "--trace", "--incremental", "--host", "0.0.0.0"]
```
{: file="dockerfile" }

然后我们可以使用 `docker build -t optimus-blog:latest .` 构建镜像, 或者在下面的Docker compose 配置文件中指定启动时自动构建镜像

```yml
# preview in local env while writing
services:
  jekyll:
    build: .
    image: optimus-blog
    container_name: optimus-blog
    volumes:
      # 这里仅需要映射 _post 目录到容器内, 其他项目文件使用build镜像导入的文件, 保证一致性
      - ./_posts:/home/Optimus-Xs.github.io/_posts 
    ports:
      - "4000:4000"
      - "35729:35729"
```
{: file="docker-compose.yml" }

以及一个 `.dockerignore` 用于过滤复制到容器内的项目文件, 提升预览过程中的编译效率

```docker
# hidden files
.*
!.git*
!.editorconfig
!.nojekyll
!.travis.yml

# bundler cache
_site
vendor
Gemfile.lock

# rubygem
*.gem

# npm dependencies
node_modules
package-lock.json

# custom
.git/
_site/
```
{: file=".dockerignore" }

后续在写作的时候, 在物理机的项目目录下直接使用, 即可启动 Jekyll 容器, 然后在 `http:127.0.0.1:4000/` 可以直接看到预览效果

```bash
docker compose up --force-recreate -d
```

## Github Action发布配置
在完成文章编写后, 最终我们需要将 Jekyll 编译生成的静态网站托管到 Github Page, 这里我们可以使用 Github Action 实现 CD/CI 自动部署

要启用 Github Action 在项目以下目录增加 `./.github/workflows/pages-deploy.yml` 配置文件

```yml
name: "Build and Deploy"
on:
  push:
    branches:
      - master
    paths-ignore:
      - .gitignore
      - README.md
      - LICENSE

  # Allows you to run this workflow manually from the Actions tab
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

# Allow one concurrent deployment
concurrency:
  group: "pages"
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Pages
        id: pages
        uses: actions/configure-pages@v4

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.3
          bundler-cache: true

      - name: Build site
        run: bundle exec jekyll b -d "_site${{ steps.pages.outputs.base_path }}"
        env:
          JEKYLL_ENV: "production"

      - name: Test site
        run: |
          bundle exec htmlproofer _site \
            \-\-disable-external \
            \-\-no-enforce-https \
            \-\-allow_missing_href \
            \-\-ignore-urls "/^http:\/\/127.0.0.1/,/^http:\/\/0.0.0.0/,/^http:\/\/localhost/"

      - name: Upload site artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: "_site${{ steps.pages.outputs.base_path }}"

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```
{: file="./.github/workflows/pages-deploy.yml" }

除了增加 GitHub Action 描述文件外, 我们还需要在 Github 仓库的`设置(Setting)` -> `Pages` -> `Build and deployment` 中将 `Source` 改为 `GitHub Action`, 让 Action 完成 Jekyll 编译后能成功部署的 Github Page

![Github Page 配置](https://cdn.jsdelivr.net/gh/Optimus-Xs/Blog-Images/2025-06-06-local-preview-and-testing-configuration-for-jekyll-docker-containers%2Fgithub-page-config.png)

完成以上配置后, 当有新的Commit 推送到 Github 后 Action 就能自动完成 Jekyll 编译, 并将生成的静态网站托管到 Github Page

## 发布前测试工具
在 Jekyll 的编译过程中会自动对 `_post` 内的Markdown文件执行语法校验, 为了保证Github Action的发布流程能成功执行, 我们可以在提交前在本地完成一次编译模拟, 确保推送到Github后能正确完成编译流程

下面两个脚本分别是用 Windows Batch (批处理) 和 Linux/macOS Shell (Bash) 编写的，分别在不同的系统下, 使用 Docker 容器, 在容器内完成边缘检测, 大致分为以下几步

- **构建（Build）**: 使用 `jekyll build` 命令将 Jekyll 源码转换成最终的静态 HTML 文件，输出到 `_site` 目录 (JEKYLL_DEST_DIR)。
- **质量检查**: 使用 `htmlproofer` 工具对生成的 `_site` 目录进行链接检查和结构验证
- **环境隔离**: 利用 `docker compose exec -it %SERVICE_NAME% bash -c "..."` 或 `docker compose exec -it "${SERVICE_NAME}" bash -c "..."`，确保所有命令都在 Docker 容器的隔离环境中运行，避免本地环境依赖问题。
- **环境变量**: 设置 `JEKYLL_ENV="production"`，确保 Jekyll 以生产模式构建（例如，可能启用压缩、禁用草稿等）。

**Windows下测试脚本**

```bat
@echo off
SETLOCAL

SET SERVICE_NAME=jekyll
SET JEKYLL_DEST_DIR=_site

echo Starting Jekyll build and HTML Proofer checks within the Docker container...

docker compose exec -it %SERVICE_NAME% bash -c "JEKYLL_ENV=\"production\" bundle exec jekyll build -d \"%JEKYLL_DEST_DIR%\" && bundle exec htmlproofer %JEKYLL_DEST_DIR% --disable-external --no-enforce-https --allow_missing_href --ignore-urls \"/^http://127.0.0.1/,/^http://0.0.0.0/,/^http://localhost/\""

IF %ERRORLEVEL% NEQ 0 (
    echo Error: Command failed.
    EXIT /B %ERRORLEVEL%
)

echo Site build and test process finished successfully.
ENDLOCAL
```
{: file="build_test.bat" }

**Linux下测试脚本**

```bash
# Exit immediately if a command exits with a non-zero status.
set -e

# Define variables for better readability
SERVICE_NAME="jekyll"
JEKYLL_DEST_DIR="_site"
HTMLPROOFER_OPTS=(
    "--disable-external"
    "--no-enforce-https"
    "--allow_missing_href"
    "--ignore-urls" "/^http://127.0.0.1/,/^http://0.0.0.0/,/^http://localhost/"
)

echo "Starting Jekyll build within the Docker container..."

# Execute Jekyll build command
docker compose exec -it "${SERVICE_NAME}" bash -c \
    "JEKYLL_ENV=\"production\" bundle exec jekyll build -d \"${JEKYLL_DEST_DIR}\""

echo "Jekyll build completed. Running HTML Proofer checks..."

# Execute HTML Proofer command
docker compose exec -it "${SERVICE_NAME}" bash -c \
    "bundle exec htmlproofer ${JEKYLL_DEST_DIR} ${HTMLPROOFER_OPTS[*]}"

echo "HTML Proofer checks completed."
echo "Site build and test process finished successfully."
```
{: file="build_test.bash" }


# 参考
- [Filesystem watchers like libinotify do not work](https://github.com/microsoft/WSL/issues/216)
- [Set enforce_https to false on the CLI](https://github.com/gjtorikian/html-proofer/issues/727)
- [Jekyll 语法简单笔记](https://github.tiankonguse.com/blog/2014/11/10/jekyll-study.html)