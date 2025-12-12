---
layout: post
title: Git 约定式提交规范
date: 2025-03-20 13:29 +0800
categories: [Software Development]
tags: [Git]
---

## Git 约定式提交规范是什么
约定式提交规范是一种基于提交信息的轻量级约定。 它提供了一组简单规则来创建清晰的提交历史； 这更有利于编写自动化工具。 通过在提交信息中描述功能、修复和破坏性变更

## 为什么使用约定式提交

- 自动化生成 `CHANGELOG`。
- 基于提交的类型，自动决定语义化的版本变更。
- 向其他使用者传达 `commit` 变化的性质。
- 触发构建和部署流程。

## 约定式提交消息格式
提交消息需要满足以下正则表达式

```
/^(revert: )?(feat|fix|docs|dx|style|refactor|perf|test|workflow|build|ci|chore|wip)(\(.+\))?: .{1,50}/
```
{: file='验证表达式'}

```text
[Emoji] <提交类型>[功能模块]: <提交内容描述>

[正文]

[脚注]
```
{: file='提交消息格式'}

- Emoji: `<可选值>` 一个emoji表情增加可读性, 与提交类型绑定, 具体值参考下面提交类型
- 提交类型: `<必选值>` 本次 commit 的类型
    
    可选类型如下:

    - 💥/🎉 feat: 新增特性（feature）。用于表示引入一个功能或者特性。最常用的
    - 🐛 fix: 修复缺陷（bug fix）。用于表示修复一个问题或错误。第二常用的
    - 📝 docs: 文档（documentation）。用于表示对文档的修改，包括 README、文档注释等。
    - ⌨️ dx: 开发体验（developer experience）。用于表示改善开发者的工作流程或开发工具的更新。
    - 🥰 style: 代码风格（style）。用于表示不影响代码运行的格式化或风格调整，例如空格、缩进、分号等。
    - 🏗️ refactor: 重构（refactor）。用于表示对现有代码的重构，没有新增功能也没有修复 bug；目的是提升代码质量。
    - ✈️ perf: 性能优化（performance improvement）。用于表示对代码的性能进行优化和改善。
    - 🔧 test: 测试（tests）。用于表示添加或修改测试代码，提升代码覆盖率或修复测试用例。
    - ☁️ workflow: 工作流程（workflow）。用于表示与工作流相关的更改，例如 CI/CD 配置文件的修改。
    - 📦️ build: 构建（build）。用于表示与项目构建过程相关的更改，例如 Gradle、npm 相关的修改。
    - ☁️ ci: 持续集成（continuous integration）。用于表示与持续集成相关的更改，例如 CI 配置文件的修改。
    - 🏰chore: 杂项（chore）。用于表示不属于上的任何类型的更改，通常用于例行任务的更新，例如依赖更新。
    - ⏸️ wip: 进行中的工作（work in progress）。用于表示一个正在进行中的功能或修复，可能尚未完成。
    - 🌷 ui: 用户界面(user interface) 。页面样式,结构等和UI相关的修改。
- 功能模块: `<可选值>` 本次提交改动设计涉及的功能模块
- 内容描述: `<必选值>` 本次提交包含的内容, 稍微具体一点, 需要说明包含的所有功能点
- 正文: `<可选值>`  本次更新相关的所有需要说明的信息, 一般也可以不写
- 脚注: `<可选值>`  本次更新相关的 issue, 标记版本, 或者Break Change等信息


## 约定式提交消息示例

```text
💥 feat(Backend): add 'comments' option
🐛 fix(compiler): fix some bug
📝 docs(DB): add some docs
🌷 UI(Frontend): better styles
🏰 chore(compiler): Made some changes to the scaffolding
🌐 locale(Localization): Made a small contribution to internationalization
```
{: file='参考Commit Message'}

# 参考

- [约定式提交](https://www.conventionalcommits.org/zh-hans/v1.0.0/)
- [Git Commit Message Convention](https://github.com/vuejs/core/blob/main/.github/commit-convention.md)
- [ant design pro v5 git commit时报ERROR invalid commit message format的解决方法](https://blog.csdn.net/Wai_Leung/article/details/123731787)
