// Click behaviour for an entry of a TaskManager.TasksModel, shared by the
// dock and anything else that lists apps/windows:
//   launcher           -> start it
//   one window         -> activate, or minimise if it is already active
//   group of windows   -> bring the group forward, then cycle through it
import QtQuick
import org.kde.taskmanager as TaskManager

QtObject {
    required property TaskManager.TasksModel model

    function role(index, r) { return model.data(index, r) }

    function activate(row, modifiers) {
        const index = model.makeModelIndex(row)
        if (modifiers & Qt.ShiftModifier) {
            model.requestNewInstance(index)
            return
        }
        if (role(index, TaskManager.AbstractTasksModel.IsGroupParent)) {
            const n = model.rowCount(index)
            const children = []
            for (let i = 0; i < n; ++i)
                children.push(model.makeModelIndex(row, i))
            const active = children.findIndex(c => role(c, TaskManager.AbstractTasksModel.IsActive))
            if (active >= 0) {
                model.requestActivate(children[(active + 1) % n])
            } else {
                // most recently used window of the group
                let best = children[0], bestTime = 0
                for (const c of children) {
                    const t = role(c, TaskManager.AbstractTasksModel.LastActivated)
                    if (t && t.getTime && t.getTime() > bestTime) { best = c; bestTime = t.getTime() }
                }
                model.requestActivate(best)
            }
            return
        }
        if (role(index, TaskManager.AbstractTasksModel.IsLauncher)
                || role(index, TaskManager.AbstractTasksModel.IsStartup)) {
            model.requestActivate(index)
            return
        }
        if (role(index, TaskManager.AbstractTasksModel.IsActive)
                || role(index, TaskManager.AbstractTasksModel.IsMinimized))
            model.requestToggleMinimized(index)
        else
            model.requestActivate(index)
    }

    function isPinned(url) { return model.launcherPosition(url) !== -1 }
    function togglePin(url) {
        if (isPinned(url)) model.requestRemoveLauncher(url)
        else model.requestAddLauncher(url)
    }
}
