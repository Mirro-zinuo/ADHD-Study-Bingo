# ADHD Study Bingo

这是一个使用 SwiftUI 与 SwiftData 构建的学习任务管理小应用。应用通过 Bingo 棋盘的形式，把当天学习任务游戏化，帮助用户按天安排任务、追踪完成情况，并查看历史完成记录。

## View 梳理

项目中的自定义界面相关类型主要分为三类：页面级 View、弹窗 Sheet View、以及局部复用组件。

### 页面级 View

#### `ContentView`
- 文件：[`ADHD Study Bingo/Views/ContentView.swift`](ADHD%20Study%20Bingo/Views/ContentView.swift)
- 作用：应用主容器，不直接承载具体业务页面内容，而是负责组织底部标签页结构。
- 界面描述：
  - 使用 `TabView` 展示 3 个主页面。
  - 底部标签分别为 `Home`、`Tasks`、`History`。
  - 进入页面时会刷新当天计划与 Bingo 状态。

#### `HomePageView`
- 文件：[`ADHD Study Bingo/Views/HomePageView.swift`](ADHD%20Study%20Bingo/Views/HomePageView.swift)
- 作用：首页 / Bingo 主界面。
- 界面描述：
  - 顶部显示应用标题 `ADHD Study Bingo`。
  - 标题下方显示副标题 `Turn your tasks into a game`。
  - 中间有日期切换区域，支持前一天、后一天和 `Back to Today`。
  - 主要内容是一个 3x3 的 Bingo 任务格。
  - 每个格子显示任务标题和计划分钟数。
  - 用户可点击格子切换任务完成状态。
  - 完成 Bingo 后会出现提示文案，如 `Bingo! You completed X lines.`。
  - 页面底部会显示当天已安排任务数量，或提示先去任务列表添加当天任务。

#### `TaskListPageView`
- 文件：[`ADHD Study Bingo/Views/TaskListPageView.swift`](ADHD%20Study%20Bingo/Views/TaskListPageView.swift)
- 作用：任务列表页，用于管理学习任务与当天计划。
- 界面描述：
  - 页面标题为 `Task List`。
  - 页面主体分成 `Active Tasks` 和 `Completed Tasks` 两个区域。
  - 每个任务卡片会显示：
    - 任务名称。
    - 截止日期，例如 `Deadline 2026-04-27` 这种格式。
    - 剩余分钟数、已完成分钟数、剩余天数。
    - `Recommended Today` 今日推荐学习时长。
    - 两条进度条：剩余时间进度、完成进度。
  - 对未加入当天计划的任务，可点击 `+` 加入。
  - 对已加入当天计划的任务，可点击铅笔编辑计划，或点击垃圾桶移除。
  - 每个任务卡片右侧还有 `...` 更多操作菜单，可编辑或删除任务。
  - 右上角工具栏有 `Add Task` 按钮，用于新增任务。

#### `HistoryPageView`
- 文件：[`ADHD Study Bingo/Views/HistoryPageView.swift`](ADHD%20Study%20Bingo/Views/HistoryPageView.swift)
- 作用：历史记录页，用于查看每日完成记录。
- 界面描述：
  - 页面标题为 `Daily Completion History`。
  - 如果没有历史记录，显示 `No history yet. Completed daily tasks will appear here.`。
  - 如果有历史记录，会按日期分组展示。
  - 每条记录显示：
    - 任务名称。
    - 完成分钟数，例如 `Completed 30 min`。
    - 完成时间，例如 `14:30`。

### 弹窗 / Sheet View

#### `AddTaskSheetView`
- 文件：[`ADHD Study Bingo/Views/AddTaskSheetView.swift`](ADHD%20Study%20Bingo/Views/AddTaskSheetView.swift)
- 作用：新增任务弹窗。
- 界面描述：
  - 使用表单布局。
  - 分组标题为 `Task Info`。
  - 包含任务名称输入框 `Task Name`。
  - 包含小时与分钟滚轮选择器。
  - 包含截止日期选择器 `Deadline`。
  - 顶部标题为 `Add Task`。
  - 左上角是 `Cancel`，右上角是 `Save`。

#### `EditTaskSheetView`
- 文件：[`ADHD Study Bingo/Views/EditTaskSheetView.swift`](ADHD%20Study%20Bingo/Views/EditTaskSheetView.swift)
- 作用：编辑已有任务弹窗。
- 界面描述：
  - 整体结构与新增任务弹窗相似。
  - 分组标题为 `Edit Task Info`。
  - 顶部标题为 `Edit Task`。
  - 表单内可修改任务名、总时长和截止日期。
  - 左上角是 `Cancel`，右上角是 `Save`。

#### `DailyPlanSheetView`
- 文件：[`ADHD Study Bingo/Views/DailyPlanSheetView.swift`](ADHD%20Study%20Bingo/Views/DailyPlanSheetView.swift)
- 作用：设置任务当天计划时长的弹窗。
- 界面描述：
  - 使用简化表单布局。
  - 分组标题为 `Daily Planned Time`。
  - 只有一个分钟数字输入框 `Minutes`。
  - 顶部标题为 `Add to Daily Tasks`。
  - 左上角是 `Cancel`，右上角是 `Save`。

### 组件级 View

#### `TaskBarsView`
- 文件：[`ADHD Study Bingo/Views/Components/TaskBarsView.swift`](ADHD%20Study%20Bingo/Views/Components/TaskBarsView.swift)
- 作用：任务进度条组件，在任务卡片内部复用。
- 界面描述：
  - 显示两条进度条。
  - 第一条对应 `Remaining Time Progress`。
  - 第二条对应 `Completion Progress`。
  - 颜色会随进度从偏红逐渐过渡到偏绿。

#### `BingoCelebrationOverlay`
- 文件：[`ADHD Study Bingo/Views/Components/BingoCelebrationOverlay.swift`](ADHD%20Study%20Bingo/Views/Components/BingoCelebrationOverlay.swift)
- 作用：Bingo 达成后的庆祝遮罩层。
- 界面描述：
  - 页面上方覆盖一层半透明暗色背景。
  - 中间显示一个圆角白色弹框。
  - 弹框主标题为 `🎉 BINGO!`。
  - 副标题为 `Awesome! X lines completed`。
  - 用于在首页达成 Bingo 时进行反馈展示。

#### `ConfettiEmitterView`
- 文件：[`ADHD Study Bingo/Views/Components/ConfettiEmitterView.swift`](ADHD%20Study%20Bingo/Views/Components/ConfettiEmitterView.swift)
- 作用：彩带动画组件。
- 界面描述：
  - 本身不承载文字信息。
  - 在 Bingo 庆祝遮罩层展示时触发粒子彩带动画。
  - 属于视觉增强效果组件。

## 其他界面相关类型

#### `ADHD_Study_BingoApp`
- 文件：[`ADHD Study Bingo/ADHD_Study_BingoApp.swift`](ADHD%20Study%20Bingo/ADHD_Study_BingoApp.swift)
- 作用：应用入口。
- 说明：
  - 负责初始化 `ModelContainer` 与 `AppModel`。
  - 启动时将 `ContentView` 挂载为主窗口内容。
  - 严格来说它不是 `View`，而是 SwiftUI App 生命周期入口。

#### `ConfettiEmitterContainerView`
- 文件：[`ADHD Study Bingo/Views/Components/ConfettiEmitterView.swift`](ADHD%20Study%20Bingo/Views/Components/ConfettiEmitterView.swift)
- 作用：`ConfettiEmitterView` 底层使用的 UIKit 容器视图。
- 说明：
  - 它不是 SwiftUI `View`。
  - 仅负责承载 `CAEmitterLayer` 并执行彩带喷射动画。


## 个性化代码

### 参考一
#### 包含顺序、选择和循环的算法的过程
```swift
func recalculatePlan(
    tasks: [StudyTask],
    todayActualMinutes: Int,
    focusedTaskID: UUID?,
    currentDate: Date = Date()
) -> [StudyTask] {

    // 顺序 1：先更新每个任务的剩余天数
    for index in tasks.indices {
        tasks[index].daysLeft = calculateDaysLeft(from: currentDate, to: tasks[index].deadlineDate)
    }

    // 选择：仅在用户指定了焦点任务时，给该任务增加今天实际学习时长
    if let focusedTaskID,
        let index = tasks.firstIndex(where: { $0.id == focusedTaskID })
    {
        let safeMinutes = max(todayActualMinutes, 0)
        tasks[index].completedMinutes = min(
            tasks[index].completedMinutes + safeMinutes,
            tasks[index].totalMinutes
        )
    }

    // 顺序 2 + 循环：基于最新进度重新计算每个任务的日目标
    for index in tasks.indices {
        let remaining = max(tasks[index].totalMinutes - tasks[index].completedMinutes, 0)
        if remaining == 0 { // 选择：完成任务时日目标为 0
            tasks[index].dailyTargetMinutes = 0
        } else {
            tasks[index].dailyTargetMinutes = Double(remaining) / Double(max(tasks[index].daysLeft, 1))
        }
    }

    return tasks
}
```

#### 过程被调用的地方
- `ContentView`：在 `onAppear` 和日期变化时触发重算，保证首页统计实时更新。
- `HomePageView`：页面出现时重算计划，确保展示的日目标是最新值。
- `TaskListPageView`：记录学习时长、新增任务、切换日期后都会调用重算。
- `AddTaskSheetView`：创建新任务后立即重算，避免目标值滞后。

#### 过程说明（输入、处理、输出）
- 输入：任务列表 `tasks`、当天实际学习分钟 `todayActualMinutes`、当前聚焦任务 `focusedTaskID`、当前日期 `currentDate`。
- 处理：先更新每个任务 `daysLeft`，再按条件累加聚焦任务进度，最后循环重算 `dailyTargetMinutes`。
- 输出：返回更新后的任务数组，用于刷新界面与后续排序/紧急度计算。


### 参考二

#### 程序数据如何存储在列表中
```swift
@Model
final class StudyTask: Identifiable {
    var id: UUID
    var title: String
    var totalMinutes: Int
    var completedMinutes: Int
    var daysLeft: Int
    var deadlineDate: Date
    var initialDays: Int
    var dailyTargetMinutes: Double

    @Relationship(deleteRule: .cascade, inverse: \DailyTaskAssignment.task)
    var dailyAssignments: [DailyTaskAssignment] = []

    init(
        id: UUID = UUID(),
        title: String,
        totalMinutes: Int,
        completedMinutes: Int = 0,
        deadlineDate: Date,
        today: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.totalMinutes = totalMinutes
        self.completedMinutes = completedMinutes
        self.deadlineDate = deadlineDate

        let calculatedDays = Self.daysLeft(from: today, to: deadlineDate)
        self.daysLeft = calculatedDays
        self.initialDays = calculatedDays

        let remaining = max(totalMinutes - completedMinutes, 0)
        self.dailyTargetMinutes = Double(remaining) / Double(max(calculatedDays, 1))
    }
}

@Query private var tasks: [StudyTask]
```

- `StudyTask` 是列表元素的数据结构，每个对象就是一个学习任务。
- `@Query private var tasks: [StudyTask]` 会从 SwiftData 自动取回任务集合，形成程序中的“列表”。
- 当新增、修改任务后，SwiftData 会持久化这些数据，应用重启后仍能恢复。

#### 列表中的数据是如何被使用的（界面渲染）
```swift
private var pendingTasks: [StudyTask] {
    appModel.sortByUrgency(tasks.filter { $0.remainingMinutes > 0 })
}

ForEach(pendingTasks) { task in
    VStack(alignment: .leading, spacing: 10) {
        Text(task.title)
        Text("Remaining \(task.remainingMinutes) min | Completed \(task.completedMinutes) min | Days Left \(task.daysLeft)")
        Text("Recommended Today: \(max(Int(ceil(task.dailyTargetMinutes)), 1)) min")
        TaskBarsView(task: task)
    }
}
```

- 页面先将任务列表排序（按紧急度），再交给 `ForEach` 逐项渲染。
- `ForEach` 会把列表中的每个 `StudyTask` 映射成一行 UI（任务名、进度、日目标等）。
- 当列表数据变化（例如记录学习时长或新增任务）时，SwiftUI 会自动刷新对应界面。
