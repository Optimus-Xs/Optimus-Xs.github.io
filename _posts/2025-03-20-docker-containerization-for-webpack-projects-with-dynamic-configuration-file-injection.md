---
layout: post
title: WebPack 前端项目使用 Docker 容器化发布动态注入配置文件的方案
date: 2025-03-20 10:28 +0800
categories: [Software Development]
tags: [Docker, React, Webpack, 容器]
---

## 需求场景描述

**项目背景与痛点分析**

最近经手开发的一个 SaaS 平台需要为客户提供**云端生产系统**、**内网测试环境**以及多样化的**私有化部署服务**。我们的 React 前端项目需要依赖一系列后端接口地址，并且需要根据客户的授权和需求开启或关闭特定的子系统模块。

在项目具体发行部署的时候，我们面临的主要痛点是：

- **部署复杂性**： 每次部署到新的客户现场环境，如果 API 地址或启用的功能模块有变动，我们都需要修改代码中的环境变量（如 `.env` 文件），然后执行 `npm run build`，重新打包并创建新的 Docker 镜像。
- **镜像维护成本高**： 针对十几个私有化客户，我们实际上维护着十几个配置略有差异的镜像，这给运维带来了巨大的负担和出错风险。
- **现场实施滞后**： 很多配置项（如客户网络中的实际 IP 地址、是否启用某个新功能）只有在现场实施阶段才能最终确定，导致我们无法提前准备好“最终”的镜像。

**核心功能: 后端类似的动态配置文件**

为了解决上述问题，我们的核心目标是：将配置从前端项目的“**构建时（Build Time）”彻底转移到“运行时（Run Time）**”。

我们参照了后端微服务中 Spring Boot 的 `application.yml` 配置模式，期望前端也实现以下能力：

目标实现效果：

- 外部配置可插拔： React 应用的核心构建和 Docker 镜像应该是不包含任何环境敏感信息的“纯净”版本。
- 动态加载能力： 应用启动时，能自动或通过引导脚本，从外部指定的路径（例如容器内的 `/app/config/runtime.json`）加载一个配置文件。
- Docker Volume 支持： 部署时，运维人员可以通过 Docker Volume 机制 将客户现场特定的配置文件挂载到容器内，覆盖应用默认的配置。
- 配置项多样性： 这个配置文件必须能够承载所有的运行时变量，包括但不限于：
    - 后端服务地址（如 `API_BASE_URL`）
    - 启用/禁用子系统模块的列表 (`ENABLED_MODULES`)
    - 功能开关 (`FEATURE_TOGGLES`)

加载机制需求:

- 加载时机： 确保配置在 React 应用渲染任何组件之前完成加载和解析，避免出现组件获取不到配置而报错或白屏的情况。
- 数据结构： 配置文件的格式需要支持 JSON 或 YAML 这种层级结构，方便管理复杂的配置项。
- 统一访问： 在 React 代码中，开发者不能直接读取全局变量，而必须通过一个统一的配置服务（`ConfigService`），保证代码的健壮性和类型安全。

## 常见方案以及缺陷
### env 环境变量
这种方案依赖于在 CI/CD 流程中的构建阶段（Build Time）注入环境变量，针对每个环境打包生成一个独特的镜像。

**流程简介**:

- **准备阶段**： 针对不同的环境（如 `dev`、`prod`、`customerA`），创建不同的 `.env` 文件或在 CI/CD 脚本中设置不同的环境变量（例如 `REACT_APP_API_URL=...`）。
- **构建阶段（Build Time）**： 在执行 `npm run build` 或 `yarn build` 命令时，React 框架（通常是 Create React App 或 Webpack）将当前环境变量的值读取，并将它们硬编码（Hardcode） 进生成的静态 JavaScript 和 HTML 文件中。
- **部署阶段**： 将这个包含特定环境配置的静态文件打包成一个独立的 Docker 镜像，并使用特定的 Tag（如 `app:prod` 或 `app:customerA`）进行区分部署。

**缺点分析**:

- **镜像爆炸与管理复杂**: 这是最大的痛点。每个环境（云端生产、开发内网、客户A、客户B...）都需要一个独立的 Docker 镜像，通过不同的 Tag 来区分。维护成本呈线性增长。 一旦代码有更新，所有环境的镜像都需要重新构建一遍，增加了 CI/CD 流程的负担。
- **私有化部署僵化**: 无法应对客户现场的临时性、多样性配置。如果客户现场的网络 IP 在部署前一刻发生变化，或者需要临时开启/关闭一个功能，实施人员必须联系开发团队，重新构建镜像，这极大地延长了部署周期。
- **配置项锁定在构建时**: 所有的配置项，包括 API 地址、模块开关，都在 `npm run build` 时被硬编码（Hardcode）进了最终的静态文件中。这意味着配置项和代码的耦合度极高，完全失去了运行时的灵活性。
- **配置信息暴露**: 环境变量通常会被编译到最终的 JavaScript Bundle 文件中。虽然有一定的混淆，但配置信息仍然是静态可查阅的，不如外部配置文件灵活。

> `.env`的本质
> 
> 浏览器环境内部是没有环境变量这个东西的，我们现在使用的任何解决方案都不过是虚假的抽象，但是很多文档里面都有提及到`.env`文件，在代码中使用`process.env` 就可以使用环境变量了，但实际上`process`并不存在于浏览器环境中，它只存在于node环境中，webpack打包后`process.env`都会替换成给定的字符串，这就意味着前端的环境变量只能在构建前(中)配置，一旦构建完成后就无法更改。
{: .prompt-tip }

### 服务器远程配置
这种方案要求应用在启动时通过网络向一个中央配置服务（如 Spring Cloud Config、Apollo 或 Consul）请求配置信息。

**流程简介**:

- **配置中心部署**： 独立部署一个中央配置服务（如 Apollo、Consul 或 Spring Cloud Config）。所有环境的配置（dev、prod 等）都集中存储在这个服务中。
- **应用启动**： React 应用在启动时（通常是通过一个启动脚本或在 index.html 引导），向中央配置服务发起网络请求。
- **获取配置**： 配置服务根据请求的应用 ID 和环境标识，返回对应的 JSON/YAML 配置数据。
- **应用运行**： React 应用解析接收到的配置数据，并基于此数据初始化和运行。

**缺点分析**:

- **私有化部署受限（核心问题）**: 这是该方案在私有化场景中的致命缺陷。 很多私有化客户现场是内网环境，无法连接到我们提供的云端中央配置服务。如果要求每个客户现场都部署一套配置服务，又会大幅增加部署复杂度和维护成本。
- **启动依赖与性能风险**: 应用的启动流程必须强依赖中央配置服务。如果配置服务宕机或网络延迟高，将直接导致前端应用无法启动或启动缓慢。引入了额外的单点故障风险。
- **额外的架构复杂度**: 引入了一个新的关键外部依赖——配置中心。这增加了整个系统的架构复杂性、安全（访问控制）和维护负担。对于前端项目来说，这通常被认为是过度设计 (Over-engineering)。
- **缓存与实时性权衡**: 为了性能，配置需要被缓存。但缓存带来了配置实时更新的复杂性，需要额外的推送/拉取机制，增加了实现的难度。

### Nginx容器环境变量
此方案利用 Nginx 在启动容器后，通过环境变量和 `sub_filter` 或 `envsubst` 指令，在 `index.html` 被请求时进行文本替换，从而动态注入配置。

**流程简介**:

- 项目准备： React 项目在 `public/index.html` 文件中预留配置占位符，例如 :
    ```html
    <!doctype html>
    <html lang="en">
      <head>
        <script>
          window.SERVER_DATA = __SERVER_DATA__;
        </script>
    ```

    然后，在发送响应之前将 `__SERVER_DATA__` 替换为真实数据的 JSON。然后客户端代码可以读取 `window.SERVER_DATA` 来使用它
- 构建一次： 项目只构建一次，生成包含占位符的静态文件，然后将其打包进一个包含 Nginx 的 Docker 镜像中。
- 部署阶段： 部署时，通过 Docker 环境变量（如 `-e REACT_APP_API_URL=https://new.api.com`）向 Nginx 容器传递真实的配置值。
- 运行时替换： Nginx 在提供 `index.html` 文件服务时，利用 `sub_filter `或 `envsubst` 指令，将 HTML 文件中的 占位符字符串 (`%REACT_APP_API_URL%`) 替换成真实的环境变量值 (`https://new.api.com`)。

**缺点分析**:

- **配置项数量限制与复杂性**: Nginx 的 `sub_filter` 指令或 Docker 官方镜像提供的 `envsubst` 脚本通常针对少量配置项有效。如果配置项（如 API 地址、启用模块、功能开关等）数量过多或配置结构复杂，需要维护一个庞大且复杂的 `default.conf.template` 文件，并且为每一个配置项编写一个`sub_filter` 规则。
- **替换性能与范围**: `sub_filter` 是在 Nginx 响应处理阶段 对整个内容进行字符串替换。如果 `index.html` 文件较大，或者替换规则过多，可能会对首次加载的性能造成轻微影响。更重要的是，它只适用于替换 HTML 标签中的占位符，无法动态注入复杂的 JSON 结构。
- **非标准配置流程**: 这种方式将配置逻辑耦合进了 Web 服务器（Nginx）的配置和启动流程中。它不是一个标准的“应用启动”配置加载机制，需要依赖特定版本的 Nginx 容器（如 1.19+ 的 `docker-entrypoint.sh` 脚本），可移植性较差。
- **安全和 XSS 风险**: 在 Nginx 配置中进行字符串替换时，必须非常小心传递给 Nginx 环境变量的值，确保在将 JSON 发送到客户端之前对其进行序列化, 以避免将恶意脚本注入到最终的 `index.html` 中。

> 这三种传统的配置信息加载方案都不能完全满足我们的部署需求
> 
> - **env 环境变量**： 不符合只需要一个镜像（Build Once, Deploy Many）需求, 这个方案会导致镜像数量爆炸。
> - **服务器远程配置**： 依赖中央配置中心，部署常见中理想情况只需要一个本地可访问的文件，完美适应内网私有化部署。
> - **Nginx容器环境变量**： 配置文件需要可以加载结构化、复杂的 JSON/YAML 文件，而不受限于 Nginx 字符串替换的简单逻辑和复杂性。
{: .prompt-warning }

## 注入方案的实现原理
这个注入方案的核心逻辑是放弃所有的`.env`环境变量配置, 转而在App启动的时候在`index.html`中引用`config.js`, 通过`config.js`中的注入逻辑将**配置信息注入到全局的window对象**属性。后续在应用中需要使用配置信息的地方直接使用window属性即可。

在发布阶段只需要让Webpack独立处理 `config.js` 不参与react代码的编译打包, `config.js` 不存入 `npm build` 生成的 Bunlde 文件, 即可将完整的项目代码和配置文件分离

同时在Docker Build 构建镜像时生成的 Bunlde 文件将添加默认的`config.js` 放入 Nginx 的部署目录完成镜像打包, 默认的`config.js`也能保障没有配置`config.js`的情况下应用能正常启动

部署阶段只需要使用 Docker 的 volume 机制使用定制的 `config.js` 覆盖掉镜像内的默认 `config.js` 即可完成配置文件的替换, 项目启动的过程中会`index.html`中的引用会自动调用 `config.js` 并注入配置信息

> 这个注入方案主要针对客户端渲染（Client-Side Rendering, CSR）项目，它不能直接完整地应用于服务器端渲染（Server-Side Rendering, SSR）的场景
>
> SSR 应用首先在 Node.js 服务器环境 中执行 React 组件的渲染逻辑，生成首屏 HTML 字符串, 在 Node.js 服务器环境执行渲染时，它没有浏览器环境, 也没有 window 全局对象来接收配置。
>
> 在SSR的Node环境中也不必使用 `index.html` 引用 `config.js` 来加载数据, 直接使用 Node.js 的标准模块（如 `fs`）直接读取挂载的配置文件
> 
> 如果客户端需要使用配置信息中的内容来处理交互, 还需要将配置必须作为 HTML 的一部分传递到客户端
> 
> 通常是在服务器生成 HTML 字符串时，将配置数据序列化为 JSON 字符串，并通过一个 `<script>` 标签注入到 HTML 的头部，通常放在一个 `window` 属性上, 例如 `window.__INITIAL_CONFIG__`
>
> ```html
> <html>
>   <head>
>     <script>
>       window.__APP_CONFIG__ = ${JSON.stringify(serverConfig)};
>     </script>
>   </head>
>   <body>...</body>
> </html>
> ```
>
> 当浏览器加载这个 HTML 后，客户端 React 应用（在执行客户端 JS Bundle 前）首先检查 `window.__APP_CONFIG__`。如果存在，就使用它作为应用的初始配置, 而不是再次发起请求去加载 `config.js` 文件
{: .prompt-tip }

## 注入方案的实现流程
下面的示例代码使用一个标准的 Ant Design Pro 项目作为示例

### 项目中实现配置文件读取和注入
由于Ant Design Pro 使用 Umi 的开发预览服务器只会将 `/pubilc` 目录下的文件放入预览的web服务器托管, 根据项目结构为App提供配置信息的 `config.js` 我决定放入 `/config` 目录来保证项目结构语义

所以我们的配置文件注入实现需要分为开发环境和生产环境单独实现, 同时也能将开发环境使用配置和生产环境配置模板的 `config.js` 分割为 `app-config.js` 和 `app-config.local.js`

`app-config.local.js` 在默认情况下不存入到 Git, 优化了本地开发环境和 Git 中的配置模板使用同一个文件名的冲突和反复修改步骤

#### 开发环境注入实现
在 Ant Design Pro 项目中，`global.tsx` (或者 `global.ts`) 文件是一个全局脚本文件，用于在应用启动时执行全局配置和逻辑。

主要作用是：

- 执行全局副作用 (Side Effects)： 运行需要在应用启动前或初始化时执行一次的全局逻辑。
- 全局引入 (Global Imports)： 引入一些不需要在特定组件中使用的、但需要在全局生效的样式文件或库。
- polyfill 或全局配置： 例如，引入一些兼容性脚本 (polyfill) 或配置全局变量。

当浏览器加载应用时，`global.ts(x)` 中的代码会在**React 框架初始化**和**应用组件渲染**之前整个**应用生命周期的最前端**被执行。

根据这个特性, 在开发环境下我们可以在 `global.tsx` 手动读取 `app-config.local.js`, 将其中的配置信息注入到 `window` 对象

```ts
// 定义注入到 window 属性的类型
declare global {
  interface Window {
    appConfig: {
      apiUrl: string;
    };
  }
}

// 在开发环境下调用 app-config 注册应用的配置信息
if (process.env.NODE_ENV === 'development') {
  window.appConfig = appConfig;
}
```
{: file="src\global.tsx" }

```js
/**
 * 此文件仅供本地开发环境配置的应用配置文件，请勿加入VCS
 * */
const appConfig = {
  apiUrl: "http://localhost:8080",
}
export default appConfig
```
{: file="/config/app-config.local.js" }


#### 生产环境注入实现
在生产环境中我们则需要修改Webpack的配置, 在最终生成的`index.html`中引用`/app-config.js`, `index.html`在生产环境下作为整个应用的入口将会在应用启动阶段就加载`app-config.js`并注入配置到 `window` 对象

在`/config`目录下的`config.ts` 的`defineConfig`对象中添加 `{src: '/app-config.js', async: false}`: 

> 在 Ant Design Pro 项目中，`config/config.ts` 文件是整个项目的核心配置文件，它是 Umi 框架进行项目配置的约定文件。
> 
> 这个文件决定了 Umi 如何构建（`umi build`）和运行（`umi dev`）Ant Design Pro 应用。
{: .prompt-tip }

```js
export default defineConfig({
  /**
   * 其他配置项目
   */

  headScripts: [
    /**
     * 其他加载脚本
     */

    // 在 build 产物的 index.html 引入独立的配置js把配置信息注入到 window 对象, 供应用程序访问,
    // app-config.js 使用同步加载防止，保证在主程序前注入配置完成，解决加载顺序错误导致无法获取app-config的内容问题
    {src: '/app-config.js', async: false},
  ],
});
```
{: file="/config/config.ts"}

这样会在最终Build产物的`index.html` 的 `<header>` 里生成 `<script src="/app-config.js"></script>`, 加载应用的时候会自动请求 `https://example-app-host.com/app-config.js` 

```js
const appConfig = {
  apiUrl: 'http://192.168.1.4:8080',
};

// 加载 app-config.js 的时候的把 appConfig 的内容注入 window 对象
window.appConfig = appConfig;
```
{: file="/config/app-config.js"}

#### 配置信息的读取
在项目中如果需要访问项目配置信息使用下面的方法访问即可, 例如访问配置信息中的`apiUrl`:

```ts
// 如果网络故障导致app-config.js没加载成功, 
// 这个方法可以让 api 返回 ''空字符串, 防止应用崩溃
const api = window.appConfig?.apiUrl || '';

// 读取测试
if (process.env.NODE_ENV === 'development') {
  console.log('Request.ts 初始化获取到的配置',window.appConfig)
}
```

### 配置文件在Wenpack的独立处理
在执行 `npm build` 打包的时候我们需要直接将 `app-config.js` 输出到 `dist` 目录, 作为默认的启动配置文件, 最后和构建产物一起放入Nginx托管, 同时在 Docker 启动容器时给定制的 `app-config.js` 提供一个映射覆盖的地址

为了实现在Webpack打包的时候复制文件到输出目录, 我们需要安装一个`copy-webpack-plugin`插件, 将这个依赖加入`package.json` 的开发依赖后运行 `npm install` 安装即可

```json
{
  "devDependencies": {
    "copy-webpack-plugin": "^13.0.0",
  }
}
```
{: file="package.json" }

然后依然在`/config`目录下的`config.ts` 的`defineConfig`对象中添加针对`app-config.js`的单独处理, 让Webpack不打包`app-config.js`, 而是直接将其复制到`dist`输出目录

```ts
export default defineConfig({
  /**
   * 其他配置项目
   */

  /**
   * 配置 build 时候的配置文件使用 CopyWebpackPlugin 插件单独复制到dist目录，
   * 方便 docker 打包的时候动态修改配置文件
   * */
  chainWebpack(config) {
    config.plugin('copy').use(CopyWebpackPlugin, [
      {
        patterns: [
          {
            from: 'config/app-config.js', // 源文件路径
            to: 'app-config.js', // 目标路径
          },
          {
            from: 'public/scripts/loading.js', // 源文件路径
            to: 'loading.js', // 目标路径
          },
        ],
      },
    ]);
  },
});
```
{: file="/config/config.ts"}

### Dockerfile编写
在镜像的构建阶段, 我们使用多阶段构建, 先使用Node镜像build项目, 然后将生成产物复制到Nginx项目发布

```dockerfile
# 构建阶段
FROM node:20.18.0 as builder

WORKDIR /home/app

COPY package*.json ./
RUN npm install --registry=https://registry.npmmirror.com

COPY . .

RUN npm run build


# 部署阶段
FROM nginx:latest

COPY --from=builder /home/app/dist /usr/share/nginx/html/

COPY docker.nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

编写完Dockerfile后, 运行`docker build -t app:latest .`构建镜像

### 运行容器设置配置文件映射
在运行的时候只需要提前准备好定制的, `custom-app-config.js` 然后将其挂在到容器的 `/usr/share/nginx/html/app-config.js` 即可:

**Docker run 启动**

```bash
# 假设镜像名为 app:latest
# 假设定制的配置文件在当前目录，名为 custom-app-config.js

docker run -d \
  --name my-react-app \
  -p 80:80 \
  # 核心配置：使用 volume 挂载，将宿主机的 custom-app-config.js 
  # 覆盖到容器内 Nginx 托管目录下的 app-config.js 文件
  -v "$(pwd)/custom-app-config.js":/usr/share/nginx/html/app-config.js \
  app:latest
```

**Docker-compose启动**

```yml
version: '3.8'

services:
  frontend:
    image: app:latest
    container_name: react-app-frontend
    ports:
      - "80:80"
    volumes:
      # 核心配置：将位于 docker-compose.yml 文件同目录下的 custom-app-config.js 
      # 挂载到容器内的目标路径，覆盖默认配置
      - ./custom-app-config.js:/usr/share/nginx/html/app-config.js
    restart: always

# 如果还有后端服务
#  backend:
#    image: backend:latest
#    ...
```
{: file="docker-compose.yml" }

### 其他框架实现

如果使用Vue或者不使用Umi的其他react项目, 例如**Create React App (CRA)**, **Vue CLI**, **Vite**, 只需要根据不同框架的构建和配置特性，修改以下几个关键位置即可:

**配置文件的放置与读取**:

这步是确保 `config.js` 文件在开发和生产环境中都能被 Web 服务器访问到。

对于大多数非 Umi/Next.js 项目，`/public` 目录是存放静态文件（不经过 Webpack 处理）的标准位置。将`config.js`放入`/public`直接使用即可

**生产环境的 `index.html` 引用**:

目标是在最终构建产物的 `index.html` 文件中，添加 `<script>` 标签，同步引用 `/app-config.js`。

| 框架/工具        | 如何修改 index.html                          | 示例配置                                                                                                                                   |
| :--------------- | :------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------- |
| 标准 React (CRA) | 修改项目根目录下的 `/public/index.html` 文件。 | "在 `<head>` 或 `<body>` 开头添加：<br/> `<script src=""%PUBLIC_URL%/app-config.js"" async=false></script>`。 <br/> CRA 会自动替换 %PUBLIC_URL%。"           |
| Vue CLI          | 修改项目根目录下的 `/public/index.html` 文件。 | "在 `<head>` 或 `<body>` 开头添加：<br/> `<script src=""<%= BASE_URL %>app-config.js"" async=false></script>`。 <br/> Vue CLI 会自动替换 <%= BASE_URL %>。"  |
| Vite             | 修改项目根目录下的 `index.html` 文件。         | "在 `<head>` 或 `<body>` 开头添加：<br/> `<script src=""/app-config.js"" async=false></script>`。 <br/> Vite 在开发和生产环境中对根目录的引用都处理得很好。" |

**构建工具的独立文件处理**:

确保 `app-config.js` 文件不会被 Webpack/Rollup 打包进主 `JS Bundle`，而是被单独复制到最终的输出目录（如 `dist` 或 `build`）

只需要将 `app-config.js` 放在 `/public` 目录即可。**CRA** / **Vue CLI** / **Vite** 的构建流程会自动将 `/public` 目录下的所有文件复制到最终的 `build` 目录中。

**开发环境的模拟注入**:

在 Umi 中使用了 `global.tsx` 来读取 `app-config.local.js` 并注入到 window 对象，这是为了避免在本地开发时，应用去请求不存在的 `/app-config.js`

| 框架/项目类型            | 推荐的开发环境注入方式                                                                                   |
| :----------------------- | :------------------------------------------------------------------------------------------------------- |
| 标准 React (CRA/Webpack) | 在项目的 入口文件（如 `src/index.tsx` 或 `src/main.tsx`）的最顶部，<br/>在任何 React 渲染逻辑之前，执行配置注入。 |
| Vue (Vue CLI/Vite)       | 在项目的 入口文件（如 `src/main.js` 或 `src/main.ts`）的最顶部，<br/>在创建 Vue 实例之前，执行配置注入。          |


# 参考

- [前端项目 docker 化后动态注入环境变量](https://juejin.cn/post/7327613318741557283)
- [react打包配置动态环境变量](https://www.cnblogs.com/zilean/articles/17482304.html)
- [umi build打包时忽略指定文件](https://github.com/umijs/umi/issues/1120)
- [Umi 打包如何将配置文件单独分离出来](https://github.com/umijs/umi/discussions/11136#discussioncomment-7096978)
- [通过 Nginx 动态设置 React App 环境变量](https://7anshuai.js.org/blog/add-react-app-env-vars-by-nginx/)