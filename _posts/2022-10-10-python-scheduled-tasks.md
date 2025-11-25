---
layout: post
title: Python 定时任务
date: 2022-10-10 00:00 +0800
categories: [Software Development] 
tags: [Python]
---

## 使用 Sleep() 函数

第一种办法是最简单又最暴力。那就是在一个死循环中，使用线程睡眠函数 `sleep()`。

```python
from datetime import datetime
import time

'''
每个 10 秒打印当前时间。
'''
def timedTask():
    while True:
        print(datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
        time.sleep(10)

if __name__ == '__main__':
    timedTask()
```

这种方法能够执行固定间隔时间的任务。在 sleep 期间，主线程/进程会被完全阻塞。这会使得`timedTask()`一直占有 CPU 资源，不能执行其他任务。仅适用于单次简单延迟或主程序可以等待的简单脚本

## 使用 Timer 类实现定时

Python 标准库 threading 中有个 Timer 类。它会新启动一个线程来执行定时任务，所以它是非阻塞函式, 它允许你在指定的延时后只执行一次函数。

这个案例将演示如何设置一个任务在 5 秒后 运行，并且主程序不会被阻塞。

```python
import threading
import time
import datetime

def scheduled_task():
    """
    这是我们希望在延迟后执行的任务函数。
    """
    current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"\n✅ 任务执行了！时间: {current_time}")
    print("--- 定时器任务完成 ---")

# 设定延迟时间（秒）
DELAY_SECONDS = 5

print(f"🕒 主程序启动。")
print(f"⏳ 正在设置一个 {DELAY_SECONDS} 秒后执行的任务...")

# 1. 创建 Timer 对象
# 参数：延迟时间 (秒), 要执行的函数
timer = threading.Timer(DELAY_SECONDS, scheduled_task)

# 2. 启动 Timer
# 这一步是非阻塞的，主程序会立即继续往下执行
timer.start()

print(f"🔄 主程序继续执行其他工作...")

# 模拟主程序继续执行其他工作
for i in range(1, DELAY_SECONDS + 3):
    # 检查任务是否仍在等待执行（如果已经执行，is_alive() 会返回 False）
    status = "等待中" if timer.is_alive() else "已完成"
    print(f"   - 主程序工作 {i} 秒... (任务状态: {status})")
    time.sleep(1)

# 注意：如果任务是周期性的，你需要在 scheduled_task 内部再次启动一个新的 Timer。
# 因为这个 Timer 运行一次后就会自行销毁。
```

运行结果（示例）

```
🕒 主程序启动。
⏳ 正在设置一个 5 秒后执行的任务...
🔄 主程序继续执行其他工作...
   - 主程序工作 1 秒... (任务状态: 等待中)
   - 主程序工作 2 秒... (任务状态: 等待中)
   - 主程序工作 3 秒... (任务状态: 等待中)
   - 主程序工作 4 秒... (任务状态: 等待中)
   - 主程序工作 5 秒... (任务状态: 等待中)

✅ 任务执行了！时间: 2022-10-10 13:34:02  (这个时间是 5 秒后执行的)
--- 定时器任务完成 ---
   - 主程序工作 6 秒... (任务状态: 已完成)
   - 主程序工作 7 秒... (任务状态: 已完成)
```

`threading.Timer` 的特点

- 非阻塞 (`timer.start()`): 当调用 `timer.start()` 时，它会立即返回，并启动一个独立的线程来管理这个延迟。主程序可以继续执行 `for` 循环中的工作，不会被暂停。
- 一次性任务: `threading.Timer` 专为一次性延迟执行设计。一旦 `scheduled_task` 运行完成，这个 Timer 线程就会退出。
- 取消任务 (`timer.cancel()`): 如果在 5 秒延迟到达之前，你改变主意不想执行任务了，可以调用 `timer.cancel()` 来阻止任务的执行

## 使用定时任务模块 Scheduler 

schedule 是一个非常流行的轻量级库，用于进程内的简单任务调度。是 Python 中实现定时任务最简单、最优雅的第三方库之一。它以接近自然语言的方式定义任务，非常容易上手。

schedule 可通过下面的命令安装

```shell
pip install schedule
```

### 使用案例

下面是一个完整的代码示例，展示了如何定义不同类型的定时任务，并让它们运行起来。

```python
import schedule
import time
import datetime

# --- 任务函数定义 ---

def job_once_a_day():
    """定义一个每天特定时间执行的任务"""
    current_time = datetime.datetime.now().strftime("%H:%M:%S")
    print(f"⏰ 【每日任务】执行了！时间：{current_time}")

def job_per_second():
    """定义一个每隔 N 秒执行的任务"""
    current_time = datetime.datetime.now().strftime("%S")
    print(f"⏱️ 【每5秒任务】执行了！当前秒数：{current_time}")

def job_weekend_morning():
    """定义一个特定星期执行的任务"""
    print("📅 【周六任务】周末早上起来打扫房间！")

def job_with_args(name, location):
    """定义一个带参数的任务"""
    print(f"⚙️ 【带参任务】开始处理 {name} 在 {location} 的报告。")


# --- 任务调度定义（最核心的部分）---

# 1. 间隔调度 (Interval Scheduling)

# 每隔 10 分钟执行一次
schedule.every(10).minutes.do(job_once_a_day)

# 每隔 1 小时执行一次
schedule.every().hour.do(job_once_a_day)

# 每隔 5 秒执行一次 (用于演示)
schedule.every(5).seconds.do(job_per_second) 

# 2. 精确时间调度 (Time-of-day Scheduling)

# 每天的 10:30 执行
# 注意：如果要确保每天只执行一次，不要与其他间隔任务混淆。
# schedule.every().day.at("10:30").do(job_once_a_day) 

# 3. 特定星期调度 (Day-of-week Scheduling)

# 每周一执行
schedule.every().monday.do(job_once_a_day)

# 每周三的 13:15 执行
schedule.every().wednesday.at("13:15").do(job_once_a_day)

# 每周六的早上 9 点执行
schedule.every().saturday.at("09:00").do(job_weekend_morning)

# 4. 带参数的任务
schedule.every(30).seconds.do(job_with_args, name='张三', location='上海')


# --- 运行调度器 (Running the Scheduler) ---

print("=== 调度器已启动 ===")
print("注意：每5秒任务 和 每30秒任务 会持续打印日志。")
print(f"当前时间: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print("====================")

while True:
    # 检查所有待定的任务，并执行那些已经到达执行时间的任务
    schedule.run_pending()
    
    # 暂停 1 秒钟，避免 CPU 空转过高
    time.sleep(1)
```

### API
#### 定义任务执行频率
使用 `schedule.every()` 配合链式调用来定义任务的频率, 例如:

- `schedule.every(5).seconds`：每隔 5 秒。
- `schedule.every().hour`：每小时。
- `schedule.every().day.at("08:00")`：每天早上 8 点。
- `schedule.every().monday.at("14:00")`：每周一 14:00。

最后使用 `.do(your_function, *args, **kwargs)` 来指定要执行的函数。

`schedule.every()` 后面可以接的频率和时间单位非常丰富。以下是主要的 API 及其组合方式：

**1. 基础时间单位 (Time Units)**

| API                        | 描述 | 示例                                 | 含义       |
| :------------------------- | :--- | :----------------------------------- | :--------- |
| `.second()` / `.seconds()` | 秒   | `schedule.every(5).seconds.do(...)`  | 每 5 秒    |
| `.minute()` / `.minutes()` | 分钟 | `schedule.every(15).minutes.do(...)` | 每 15 分钟 |
| `.hour()` / `.hours()`     | 小时 | `schedule.every(2).hours.do(...)`    | 每 2 小时  |
| `.day()` / `.days()`       | 天   | `schedule.every(1).day.do(...)`      | 每天       |
| `.week()` / `.weeks()`     | 周   | `schedule.every(4).weeks.do(...)`    | 每 4 周    |

> 注意： 当使用 `schedule.every()` 且不指定数字时，默认数字为 1。例如：`schedule.every().hour.do(...)` 等价于 `schedule.every(1).hour.do(...)`。
{: .prompt-tip }

**2. 精确到小时/日期的 API (Day/Time Specific)**

当你想在某个时间单位内的特定时刻执行任务时，使用这些 API。

**例如: 定位到“天”内的某个时刻：`.at(time_str)`**

这个方法必须跟在 `.day()` 或特定的星期之后。

| API                 | 描述                     | 示例                                              | 含义                   |
| :------------------ | :----------------------- | :------------------------------------------------ | :--------------------- |
| `.day.at(time_str)` | 每天在精确时间执行       | "`schedule.every().day.at(""10:30"").do(...)`"    | 每天早上 10:30:00 执行 |
| `time_str` 格式     | 必须是 HH:MM 或 HH:MM:SS | "`schedule.every().day.at(""14:20:05"").do(...)`" | 每天 14:20:05 执行     |

**或者: 定位到“周”内的某个日子：`.monday()` 到 `.sunday()`**

你可以指定一周中的某一天，并结合 `.at()` 来精确时间。

| API          | 描述   | 示例                                                 | 含义                               |
| :----------- | :----- | :--------------------------------------------------- | :--------------------------------- |
| `.monday()`  | 每周一 | "`schedule.every().monday.do(...)`"                  | 每周一的任意时刻执行（通常是午夜） |
| `.tuesday()` | 每周二 | "`schedule.every().tuesday.at(""09:00"").do(...)`"   | 每周二早上 9 点执行                |
| ...          | ...    | ...                                                  | ...                                |
| `.sunday()`  | 每周日 | "`schedule.every().sunday.at(""23:59:59"").do(...)`" | 每周日午夜前一秒执行               |

**3. 限制执行范围的 API**

这些 API 用于在时间间隔内，指定任务的开始时间或结束时间。

**例如: 限制时间范围：`.from(time_str)` 和 `.to(time_str)`**

这两个方法常用于定义“在某个时间段内，每隔 N 分钟执行一次”。

| API            | 描述             | 示例                                                                | 含义                                             |
| :------------- | :--------------- | :------------------------------------------------------------------ | :----------------------------------------------- |
| `.from().to()` | 限制执行的时间段 | "`schedule.every(5).minutes.from(""09:00"").to(""17:00"").do(...)`" | 只在每天的 9 点到 17 点之间，每隔 5 分钟执行一次 |

**4. 最终执行 API**

所有调度链的最后一步都是 `.do()`，它接受你希望执行的函数。

| API                           | 描述             | 示例                                                      | 含义                                                       |
| :---------------------------- | :--------------- | :-------------------------------------------------------- | :--------------------------------------------------------- |
| "`.do(job, *args, **kwargs)`" | 指定要执行的函数 | "`schedule.every().hour.do(report_generator, 'monthly')`" | 每小时执行 `report_generator` 函数，并传递参数 '`monthly`' |
| "`.do(job)`"                  | 不带参数的函数   | "`schedule.every(5).seconds.do(heartbeat)`"               | 每 5 秒执行 `heartbeat` 函数                               |


以下是一些结合了多种 API 的复杂任务频率调度示例：

| 调度需求                                       | 组合 API 示例                                                                                                        |
| :--------------------------------------------- | :------------------------------------------------------------------------------------------------------------------- |
| 每 2 到 4 小时执行                             | "`schedule.every(2).to(4).hours.do(job)`"                                                                            |
| 周一到周五的下午 3 点执行                      | "`schedule.every().monday.at(""15:00"").do(job)  schedule.every().tuesday.at(""15:00"").do(job)`  ...以此类推到周五" |
| 每天早上 6:00 到 8:00 之间，每 15 分钟执行一次 | "`schedule.every(15).minutes.from(""06:00"").to(""08:00"").do(job)`"                                                 |
| 每 30 秒执行一次                               | "`schedule.every(30).seconds.do(job)`"                                                                               |

#### 启动任务

schedule 库本身并不是一个守护进程或后台服务，它依赖于你来驱动它

```python
while True:
    # 关键函数：检查并执行所有到期的任务
    schedule.run_pending() 
    
    # 必须有：让主程序暂停一小段时间，然后再去检查任务
    time.sleep(1)
```

这段 while True 循环是 schedule 的心脏。它会不断循环：

1. 每 1 秒醒来一次。
2. 调用 `schedule.run_pending()`。
3. `run_pending()` 检查所有你设置的任务，看它们的下一个执行时间是否已经到了。
4. 如果到期，任务就会在主线程中执行。
5. 任务执行完毕后，schedule 会自动计算这个任务的下一次执行时间。

取消任务：

```python
# 将任务赋值给一个变量
my_job = schedule.every(5).seconds.do(job_per_second)
# 停止任务
schedule.cancel_job(my_job) 
# 或者取消所有任务
schedule.clear()
```

获取下一个执行时间：

```python
next_time = schedule.next_run()
# 也可以获取所有任务列表
all_jobs = schedule.get_jobs()
```


## 使用 APScheduler 定时任务调度框架

APScheduler（Advanced Python Scheduler）是 Python 中一个功能更强大、更高级的任务调度库。它与 schedule 库相比，提供了更复杂、更可靠的调度能力，尤其适用于需要持久化、多种触发方式和并发控制的中大型应用。

APScheduler 是一个灵活且功能丰富的 Python 库，用于在后台运行计划任务。它的核心特点在于其模块化设计，主要由以下三个组件构成：

- **调度器 (Schedulers)**: 这是 APScheduler 的核心，它负责启动任务，并决定何时以及如何运行这些任务。它支持多种运行环境（如阻塞、后台、集成到框架中）。
- **作业存储 (Job Stores)**: 负责存储调度器中计划的作业（任务）。它可以将作业存储在内存、数据库（如 SQLAlchemy、MongoDB、Redis 等）中，从而实现任务的持久化。
- **触发器 (Triggers)**: 定义了任务执行的时间规则，支持三种核心类型：date、interval 和 cron。

安装 APScheduler 命令如下

```shell
pip install APScheduler
```

### APScheduler 的核心优势

APScheduler 的优势体现在其三大触发器和执行器上：

1. 强大的触发器 (Triggers)
   1. **date**: 在一个特定且唯一的日期/时间点执行一次任务。
   2. **interval**: 固定时间间隔执行任务，类似于 schedule。
   3. **cron**: 使用强大的 Cron 表达式 定义规则，能表达极其复杂的定时需求。
2. 多种执行器 (Executors)
   1. **ThreadPoolExecutor**： 使用线程池并发运行任务。
   2. **ProcessPoolExecutor**： 使用进程池并发运行任务，适合 CPU 密集型任务，可以避免 GIL 限制。

### 使用案例

这个案例会启动一个后台调度器，并定义两个任务：一个每 3 秒执行一次，另一个使用 Cron 表达式

```python
import time
import datetime
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger

# --- 任务函数定义 ---

def job_interval():
    """使用 interval 触发器，每隔 N 秒执行的任务"""
    current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"⏱️ 【间隔任务】执行了！每 3 秒一次。时间：{current_time}")

def job_cron():
    """使用 cron 触发器，定义复杂的调度规则的任务"""
    current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"⏰ 【Cron任务】执行了！每分钟的 05, 15, 25, 35, 45, 55 秒执行。时间：{current_time}")

# --- 调度器设置 ---

# 1. 创建 BackgroundScheduler 实例
# BackgroundScheduler 会在一个独立的线程中运行，不会阻塞主程序
scheduler = BackgroundScheduler()

# 2. 添加任务 (Job)

# 任务 A: 使用 interval 触发器 (每 3 秒执行一次)
scheduler.add_job(
    func=job_interval, 
    trigger='interval', 
    seconds=3,
    id='interval_job_3s', # 唯一标识符，方便管理
    name='每三秒任务'
)

# 任务 B: 使用 cron 触发器 (每分钟的 5, 15, 25, 35, 45, 55 秒执行)
# Cron 表达式格式：(second, minute, hour, day, month, day_of_week)
scheduler.add_job(
    func=job_cron, 
    trigger='cron', 
    second='5,15,25,35,45,55',
    id='cron_job_specific',
    name='特定秒数任务'
)

# 3. 启动调度器
print(f"=== APScheduler 调度器已启动 ===")
print(f"主程序开始运行 (不会被阻塞)... 当前时间: {datetime.datetime.now().strftime('%H:%M:%S')}")
print("-" * 30)

try:
    scheduler.start()

    # 主程序可以在这里执行其他任务，或等待用户输入/事件
    while True:
        # 打印状态信息，证明主程序是非阻塞的
        print(f"主程序正在运行... (线程 ID: {threading.current_thread().name})")
        time.sleep(5)
        
except (KeyboardInterrupt, SystemExit):
    # 接收到中断信号 (如 Ctrl+C) 时，关闭调度器
    print("\n\n=== 收到中断信号，正在关闭调度器 ===")
    scheduler.shutdown()
    print("调度器已停止。程序退出。")
```

运行结果（示例）

```
=== APScheduler 调度器已启动 ===
主程序开始运行 (不会被阻塞)... 当前时间: 06:20:41
------------------------------
主程序正在运行... (线程 ID: MainThread)
⏱️ 【间隔任务】执行了！每 3 秒一次。时间：2025-11-25 06:20:44
⏱️ 【间隔任务】执行了！每 3 秒一次。时间：2025-11-25 06:20:47
主程序正在运行... (线程 ID: MainThread)
⏰ 【Cron任务】执行了！每分钟的 05, 15, 25, 35, 45, 55 秒执行。时间：2025-11-25 06:20:55
⏱️ 【间隔任务】执行了！每 3 秒一次。时间：2025-11-25 06:20:50
⏱️ 【间隔任务】执行了！每 3 秒一次。时间：2025-11-25 06:20:53
⏱️ 【间隔任务】执行了！每 3 秒一次。时间：2025-11-25 06:20:56
... (持续运行，直到按下 Ctrl+C)
```

### 调度器介绍

#### APScheduler 的主要调度器类型

APScheduler 的调度器主要根据它们如何与应用程序的主执行流交互来区分

| 类型名称 | 类名                  | 核心特点                                                                | 适用场景                                                                                             |
| :------- | :-------------------- | :---------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------- |
| 阻塞式   | `BlockingScheduler`   | 阻塞主线程。调用 `start()` 后，主线程被接管，直到调度器关闭。           | 简单的独立脚本、命令行工具、只需要跑定时任务且不需要执行其他代码的应用。                             |
| 后台式   | `BackgroundScheduler` | 非阻塞式。在一个独立的后台线程中运行。调用 `start()` 后主程序继续执行。 | "大多数 Web 应用 (Flask、Django 等) 的简单集成、桌面 GUI 应用、或任何需要在后台运行定时任务的应用。" |
| 异步集成 | `AsyncIOScheduler`    | 与 Python 的 asyncio 事件循环集成。                                     | 基于 asyncio 的高性能应用、I/O 密集型协程任务。                                                      |
| 框架集成 | `GeventScheduler`     | 与 Gevent 框架集成。                                                    | 基于 Gevent 构建的高并发应用。                                                                       |
| 框架集成 | `TornadoScheduler`    | 与 Tornado Web 框架集成。                                               | 基于 Tornado 构建的 Web 服务。                                                                       |

#### 如何选择合适的调度器？

- **场景一：独立、单功能脚本（最简单）**
  - 选择： `BlockingScheduler`
  - 原因： 如果你的 Python 脚本唯一的目的就是运行定时任务，并且不需要在任务运行期间执行其他代码，那么阻塞式是最简单且直接的选择。它能确保任务在主进程中被驱动。

- **场景二：Web 应用后端或后台服务（最常见）**
  - 选择： `BackgroundScheduler`
  - 原因： 这是最常用的选择。Web 服务（如 Flask/Django）或任何需要同时处理用户请求/事件的应用，不能被定时任务阻塞。BackgroundScheduler 在独立线程中运行，不干扰主线程处理 Web 请求或其他事件。

- **场景三：高性能异步应用**
  - 选择： `AsyncIOScheduler`
  - 原因： 如果你的项目是基于 asyncio 事件循环构建的（例如使用 FastAPI 或 uvicorn），则必须使用 `AsyncIOScheduler`。它可以将调度任务作为协程执行，避免创建过多线程，提升性能和兼容性。

- **场景四：特定 Web 框架或环境**
  - 选择： 相应的框架集成调度器 (`TornadoScheduler`, `GeventScheduler`)
  - 原因： 如果你的应用运行在特定的事件驱动框架（如 Tornado 或 Gevent）下，使用其对应的调度器可以确保 APScheduler 的任务调度与框架的事件循环机制完美同步，避免冲突。

#### 调度器的基本配置方法

配置调度器主要分为三个步骤：导入、初始化和启动。

示例 1：`BackgroundScheduler`（最常用）

```python
from apscheduler.schedulers.background import BackgroundScheduler
import time
import datetime

def my_job():
    print(f"任务执行 @ {datetime.datetime.now().strftime('%H:%M:%S')}")

# 1. 初始化调度器
scheduler = BackgroundScheduler()

# 2. 添加作业
# 使用 'interval' 触发器，每 2 秒执行一次
scheduler.add_job(my_job, 'interval', seconds=2)

# 3. 启动调度器
print("Starting BackgroundScheduler...")
scheduler.start()

# 4. 主程序继续执行其他逻辑 (非阻塞)
while True:
    print("Main program is running...")
    time.sleep(5)
```

示例 2：BlockingScheduler（独立脚本）

```python
from apscheduler.schedulers.blocking import BlockingScheduler
import datetime

def my_job():
    print(f"任务执行 @ {datetime.datetime.now().strftime('%H:%M:%S')}")

# 1. 初始化调度器
scheduler = BlockingScheduler()

# 2. 添加作业
scheduler.add_job(my_job, 'interval', seconds=5)

# 3. 启动调度器
print("Starting BlockingScheduler... (This will block the console)")
try:
    # 启动后，程序会停在这里，直到外部中断 (Ctrl+C)
    scheduler.start()
except (KeyboardInterrupt, SystemExit):
    scheduler.shutdown()
```


### 作业存储处理

作业存储（Job Store）的核心作用是存储和管理所有已定义的定时作业（Job）。

作业存储的主要职责是：

- **持久化（Persistence）**： 将定时任务的配置（如函数名、参数、触发器规则、下次执行时间等）写入持久性存储介质（如数据库或文件），确保程序重启后任务不会丢失。
- **作业管理**： 允许调度器检索、添加、修改和删除存储中的作业。
- **多进程/分布式支持（有限）**： 不同的调度器实例可以连接到同一个持久化存储（例如数据库），从而共享任务列表。

#### APScheduler 支持的作业存储类型

| 类型名称           | 存储介质                                            | 优点                                                                     | 缺点                               |
| :----------------- | :-------------------------------------------------- | :----------------------------------------------------------------------- | :--------------------------------- |
| `MemoryJobStore`     | 内存 (RAM)                                          | 速度极快，无需配置。                                                     | 非持久化，程序重启任务全部丢失。   |
| `SQLAlchemyJobStore` | 关系型数据库 (MySQL, PostgreSQL, SQLite, Oracle 等) | 最常用，高度可靠，支持事务，任务永久持久化。                             | 需要配置数据库连接，速度比内存慢。 |
| `MongoDBJobStore`    | MongoDB                                             | 适合非关系型数据库用户，部署简单。                                       | 数据库维护略复杂。                 |
| `RedisJobStore`      | Redis                                               | 速度很快，基于内存的存储，适合对速度有要求且不一定需要永久持久化的场景。 | 依赖 Redis 的持久化配置。          |

#### 作业存储的使用和配置案例

这是一个使用 `BackgroundScheduler` 和 `SQLAlchemyJobStore`（持久化）的更复杂的 APScheduler 案例。它演示了如何对调度器中的任务进行动态管理（查看、添加、修改、删除和关闭）。

这个例子中需要的第三方库如下

```shell
pip install apscheduler sqlalchemy
```

```python
import time
import datetime
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.jobstores.sqlalchemy import SQLAlchemyJobStore
from apscheduler.triggers.cron import CronTrigger

# --- 任务函数定义 ---

def simple_task(job_id, message):
    """一个简单的任务函数，打印消息和当前时间"""
    current_time = datetime.datetime.now().strftime("%H:%M:%S")
    print(f"[{job_id}] 运行中: {message} @ {current_time}")

# --- 配置调度器和存储 ---

# 使用 SQLite 进行持久化存储
jobstores = {
    'default': SQLAlchemyJobStore(url='sqlite:///complex_jobs.sqlite')
}

# 初始化 BackgroundScheduler
scheduler = BackgroundScheduler(jobstores=jobstores)

# --- 动态管理函数 ---

def initialize_jobs():
    """初始化任务：添加两个初始任务"""
    print("--- 1. 初始化任务 ---")
    
    # 任务 A: 每 5 秒执行一次 (将成为被修改的目标)
    scheduler.add_job(
        simple_task, 
        'interval', 
        seconds=5, 
        id='job_a_5s', 
        name='A-原始任务',
        args=['job_a_5s', '我是原始任务 A，每 5 秒执行。']
    )
    
    # 任务 B: 每 10 秒执行一次 (将成为被删除的目标)
    scheduler.add_job(
        simple_task, 
        'interval', 
        seconds=10, 
        id='job_b_10s', 
        name='B-删除目标',
        args=['job_b_10s', '我是任务 B，每 10 秒执行。']
    )
    
    print(f"已添加 'job_a_5s' 和 'job_b_10s' 到调度器。")

def list_jobs():
    """获取并打印当前所有的 Job 列表"""
    print("\n--- 2. 当前 Job 列表 ---")
    jobs = scheduler.get_jobs()
    if jobs:
        for job in jobs:
            print(f"  ID: {job.id:<15} Name: {job.name:<15} Next Run: {job.next_run_time.strftime('%H:%M:%S')}")
    else:
        print("  当前没有任务。")

def modify_job():
    """修改 'job_a_5s' 的执行频率和名称"""
    print("\n--- 3. 修改任务：job_a_5s ---")
    
    # 将 job_a_5s 从每 5 秒改为每 3 秒执行，并修改名称和参数
    scheduler.modify_job(
        job_id='job_a_5s', 
        func=simple_task,
        name='A-已修改任务',
        args=['job_a_5s', '我是修改后的任务 A，现在每 3 秒执行！']
    )
    
    # 修改其触发器 (这里是重新设置 interval)
    scheduler.reschedule_job(
        job_id='job_a_5s', 
        trigger='interval', 
        seconds=3
    )
    
    print("任务 'job_a_5s' 已修改为每 3 秒执行。")
    list_jobs()

def add_new_job():
    """添加一个新的 Cron 任务"""
    print("\n--- 4. 添加新任务：job_c_cron ---")
    
    # 添加一个使用 Cron 表达式的新任务，每分钟的 05, 35 秒执行
    scheduler.add_job(
        simple_task, 
        CronTrigger(second='5,35'), 
        id='job_c_cron', 
        name='C-新Cron任务',
        args=['job_c_cron', '我是新的 Cron 任务 C，只在特定秒执行。']
    )
    
    print("已添加新的 Cron 任务 'job_c_cron'。")
    list_jobs()

def remove_job():
    """删除任务 'job_b_10s'"""
    print("\n--- 5. 删除任务：job_b_10s ---")
    
    # 删除任务 B
    scheduler.remove_job('job_b_10s')
    
    print("任务 'job_b_10s' 已删除。")
    list_jobs()

def pause_and_resume_job():
    """暂停并恢复任务 'job_a_5s'"""
    print("\n--- 6. 暂停和恢复任务：job_a_5s ---")
    
    # 暂停任务 A (它将不再运行，但配置仍然存在)
    scheduler.pause_job('job_a_5s')
    print("任务 'job_a_5s' 已暂停。")
    time.sleep(4)
    
    # 恢复任务 A
    scheduler.resume_job('job_a_5s')
    print("任务 'job_a_5s' 已恢复。")
    time.sleep(4)
    list_jobs()


# --- 主程序流程 ---

try:
    # 启动调度器
    scheduler.start()
    print("调度器启动成功，开始执行初始化和动态管理流程...")
    
    # 1. 初始化任务
    initialize_jobs()
    time.sleep(1) # 稍等，让任务开始执行
    
    # 2. 打印 Job 列表
    list_jobs()
    time.sleep(6) # 观察 job_a_5s 和 job_b_10s 运行
    
    # 3. 修改任务
    modify_job()
    time.sleep(6) # 观察 job_a_5s 的新频率 (3 秒)
    
    # 4. 添加新任务
    add_new_job()
    time.sleep(6) # 观察新任务运行
    
    # 5. 删除任务
    remove_job()
    time.sleep(6) # 确认 job_b_10s 不再运行
    
    # 6. 暂停和恢复任务
    pause_and_resume_job()
    
    print("\n流程结束。调度器将在后台继续运行 5 秒...")
    time.sleep(5)
    
except (KeyboardInterrupt, SystemExit):
    pass # 忽略中断信号，我们要在 finally 块中安全关闭

finally:
    # 7. 关闭调度器 (Shutdown)
    print("\n\n--- 7. 安全关闭调度器 ---")
    # shutdown(wait=False) 可以立即关闭，不等候正在运行的任务
    scheduler.shutdown(wait=True) 
    print("调度器已安全停止。")
```

运行这个脚本时，你会观察到以下动态变化：

1. 初始阶段： `job_a_5s` (5s 一次) 和 job_b_10s (10s 一次) 都在运行。
2. 修改阶段： `job_a_5s` 的执行频率变快，变为 3 秒一次。
3. 新增阶段： `job_c_cron` 开始运行，仅在每分钟的特定秒数执行。
4. 删除阶段： `job_b_10s` 不再打印输出。
5. 暂停/恢复阶段： `job_a_5s` 在暂停期间停止打印，恢复后继续打印。
6. 最后关闭： 所有任务线程安全退出。

由于使用了 SQLAlchemyJobStore，即使你在流程中间强制中断程序，重启后，APScheduler 也会从 `complex_jobs.sqlite` 文件中恢复 `job_a_5s` 和 `job_c_cron` 的最新状态（已修改、已添加）。

### 触发器配置
#### Date Trigger（日期触发器）

在未来的某一时刻执行且仅执行一次任务。一旦任务执行完毕，该 Job 就会被移除。

| 参数     | 必填 | 描述                                                                                 | 示例值                |
| :------- | :--- | :----------------------------------------------------------------------------------- | :-------------------- |
| `run_date` | 是   | 指定执行任务的精确日期和时间。可以是一个 datetime 对象或一个 ISO 8601 格式的字符串。 | '2025-12-31 23:59:59' |
| `timezone` | 否   | 指定 run_date 所在的时区。                                                           | 'Asia/Shanghai'       |

使用示例

```python
from apscheduler.schedulers.background import BackgroundScheduler
import datetime

# 设定一个 10 秒后执行的精确时间点
run_time = datetime.datetime.now() + datetime.timedelta(seconds=10)

def fireworks():
    print("🚀 Date 任务执行：新年倒计时结束！")

scheduler = BackgroundScheduler()

# 配置：在 run_time 这个精确时间点执行一次 fireworks 函数
scheduler.add_job(
    func=fireworks, 
    trigger='date', 
    run_date=run_time, 
    id='one_time_fireworks',
    name='一次性任务'
)
```

#### Interval Trigger（间隔触发器）

按照固定的时间间隔（如每 5 分钟、每 2 小时）周期性地执行任务。

| 参数       | 必填 | 描述                       | 示例值                |
| :--------- | :--- | :------------------------- | :-------------------- |
| `weeks`      | 否   | 间隔的周数。               | 2                     |
| `days`       | 否   | 间隔的天数。               | 1                     |
| `hours`      | 否   | 间隔的小时数。             | 3                     |
| `minutes`    | 否   | 间隔的分钟数。             | 30                    |
| `seconds`    | 否   | 间隔的秒数。               | 15                    |
| `start_date` | 否   | 任务开始执行的日期和时间。 | '2025-01-01 00:00:00' |
| `end_date`   | 否   | 任务停止执行的日期和时间。 | '2025-12-31 23:59:59' |

使用示例

```python
# ... 导入同上 ...

def status_report():
    print("⏳ Interval 任务执行：每 10 秒报告一次状态。")

# 配置：每 10 秒执行一次
scheduler.add_job(
    func=status_report, 
    trigger='interval', 
    seconds=10, 
    id='status_interval',
    name='间隔报告'
)

# 配置：每 3 小时执行一次，并限定时间范围
scheduler.add_job(
    func=status_report,
    trigger='interval',
    hours=3,
    start_date='2025-01-01 08:00:00', # 从 8 点开始
    end_date='2025-12-31 22:00:00',   # 到 22 点结束
    id='daily_interval'
)
```

#### Cron Trigger（Cron 触发器）

提供最强大的灵活性，用于定义复杂的、基于日历的执行规则，与 Unix/Linux 的 Crontab 表达式相似。

| 参数        | 描述 | 示例值           | 含义                                     |
| :---------- | :--- | :--------------- | :--------------------------------------- |
| `year`        | 年份 | 2025             | 仅在 2025 年                             |
| `month`       | 月份 | "1-6 或 1,3,5"   | 1 月到 6 月 或 1、3、5 月                |
| `day`         | 日期 | 15               | 每月的 15 号                             |
| `week`        | 周数 | 1-4              | 每月的第一到第四周                       |
| `day_of_week` | 星期 | "mon,fri 或 0-4" | "每周一和周五 或 周日到周四 (0=日,6=六)" |
| `hour`        | 小时 | "9,17"           | 早上 9 点和下午 5 点                     |
| `minute`      | 分钟 | */15             | "每 15 分钟（0, 15, 30, 45）"            |
| `second`      | 秒   | 0                | 每分钟的第 0 秒                          |

使用示例

```python
# ... 导入同上 ...
from apscheduler.triggers.cron import CronTrigger

def business_report(day):
    print(f"💰 Cron 任务执行：生成 {day} 业务报告。")

# 示例 1: 每天的早上 9 点 30 分执行
scheduler.add_job(
    func=business_report, 
    trigger='cron', 
    hour=9, 
    minute=30,
    id='daily_report',
    args=['每日']
)

# 示例 2: 每周一到周五，每小时的第 15 分钟执行一次
scheduler.add_job(
    func=business_report, 
    trigger=CronTrigger(minute=15, day_of_week='mon-fri'), # 可以用 CronTrigger 类实例化
    id='weekday_hourly',
    args=['工作日']
)

# 示例 3: 每月 1 号和 15 号的午夜执行
scheduler.add_job(
    func=business_report,
    trigger='cron',
    day='1,15',
    hour=0,
    minute=0,
    id='monthly_billing',
    args=['月度']
)
```

在选择触发器时，请遵循以下原则：

| 触发器   | 触发次数         | 最佳用途                                                                |
| :------- | :--------------- | :---------------------------------------------------------------------- |
| `Date`     | 仅一次           | 延迟执行、未来一次性事件（如系统维护、发送一次性通知）。                |
| `Interval` | 周期性，固定间隔 | 简单的周期性任务（如心跳、日志清理、轮询数据）。                        |
| `Cron`     | 周期性，基于日历 | 复杂的、精确到日期/星期的商业任务（如每日报表、每月结算、工作日备份）。 |


### 配置执行器

#### 两种执行器区别

APScheduler 中的执行器（Executor）是负责真正运行调度器提交的任务的组件。它决定了任务是在线程中运行还是在进程中运行。

APScheduler 主要提供了两种执行器：

- `ThreadPoolExecutor` (线程池执行器)
- `ProcessPoolExecutor` (进程池执行器)

选择哪种执行器，关键在于要执行的任务类型是 I/O 密集型 还是 CPU 密集型。

| 特性       | ThreadPoolExecutor (线程池)                    | ProcessPoolExecutor (进程池)                       |
| :--------- | :--------------------------------------------- | :------------------------------------------------- |
| 任务类型   | I/O 密集型 (I/O Bound)                         | CPU 密集型 (CPU Bound)                             |
| 典型任务   | 网络请求、数据库查询、文件读写、发送邮件等。   | 数据处理、复杂的数学计算、图像处理、加密解密等。   |
| Python GIL | 受 GIL（全局解释器锁）限制，不能真正并行计算。 | 不受 GIL 限制，能实现真正的多核并行计算。          |
| 内存/资源  | 线程开销小，创建速度快，共享主进程内存。       | 进程开销大，创建速度慢，每个进程有独立的内存空间。 |
| 稳定性     | 线程崩溃会影响主程序（如果处理不当）。         | 进程间隔离，一个子进程崩溃不会影响主调度器。       |
| 数据传递   | 任务函数可以直接访问和修改主进程变量。         | 任务函数的参数需要序列化，返回结果也需要序列化。   |

💡 选择建议

- **绝大多数场景 (I/O 密集型为主)**： 默认选择 `ThreadPoolExecutor`。它的开销小、响应快，并且对于 I/O 操作（Python 释放 GIL）能表现出很好的并发性。
- **涉及大量计算的场景 (CPU 密集型)**： 必须选择 `ProcessPoolExecutor`。这是在 Python 中实现多核并行计算的唯一有效方式，可以绕过 GIL 限制。
- **两者兼有**： APScheduler 允许你同时配置两种执行器，并将不同的任务分配给不同的执行器。


#### 执行器的配置和使用

执行器的配置是通过初始化调度器时的 `executors` 字典参数完成的。

```python
from apscheduler.schedulers.background import BackgroundScheduler
import time
import datetime
import threading
import multiprocessing
import os

# --- 任务函数定义 ---

def io_bound_task():
    """I/O 密集型任务：模拟网络延迟"""
    # 线程执行器会更高效处理
    time.sleep(0.5) 
    print(f"[Thread Pool]: I/O 任务完成 @ {datetime.datetime.now().strftime('%H:%M:%S')} | Thread ID: {threading.current_thread().name}")

def cpu_bound_task():
    """CPU 密集型任务：模拟大量计算"""
    # 进程执行器会实现真正的并行计算
    x = 0
    for i in range(10**6):  # 执行耗时计算
        x += i
    print(f"[Process Pool]: CPU 任务完成 @ {datetime.datetime.now().strftime('%H:%M:%S')} | Process ID: {os.getpid()}")

# --- 配置执行器和调度器 ---

# 1. 定义 Executors 配置字典
executors = {
    # 默认执行器：使用线程池，最大线程数 10
    'default': {'type': 'threadpool', 'max_workers': 10}, 
    
    # 另一个执行器：使用进程池，最大进程数 5
    'processpool': {'type': 'processpool', 'max_workers': 5}
}

# 2. 初始化调度器，传入配置
scheduler = BackgroundScheduler(executors=executors)

# 3. 添加任务并指定执行器

# 任务 A: I/O 密集型，使用默认线程池
scheduler.add_job(
    func=io_bound_task, 
    trigger='interval', 
    seconds=1, 
    id='io_job',
    executor='default' # 明确指定使用 'default' 执行器
)

# 任务 B: CPU 密集型，使用进程池
scheduler.add_job(
    func=cpu_bound_task, 
    trigger='interval', 
    seconds=3, 
    id='cpu_job',
    executor='processpool' # 明确指定使用 'processpool' 执行器
)

# --- 启动调度器 ---

try:
    print("调度器启动成功，I/O 任务使用线程池，CPU 任务使用进程池。")
    print("-" * 60)
    scheduler.start()
    
    # 主程序持续运行
    while True:
        time.sleep(1)
        
except (KeyboardInterrupt, SystemExit):
    print("\n\n安全关闭调度器...")
    scheduler.shutdown()
```

配置关键点

- 配置字典 (`executors`)：
  - 键名（如 `default` 和 `processpool`）是你在 add_job 中用来指定执行器的名称。
  - 值是配置字典，必须包含 `type`（指定 `threadpool` 或 `processpool`）和 `max_workers`（并发数）。
- 任务分配 (`executor='...'`)：
  - 在 `scheduler.add_job()` 中，通过 `executor='执行器名称'` 参数来指定该任务将由哪个执行器负责运行。
  - 如果不指定 `executor` 参数，任务将默认使用键名为 '`default` 的执行器。
- 观察输出： 运行代码时，你会发现 I/O 任务打印的是线程 ID，而 CPU 任务打印的是进程 ID，这证明它们使用了不同的执行环境。

# 参考 

- [Python中如何优雅的使用定时任务？](https://blog.csdn.net/smilehappiness/article/details/117265531)