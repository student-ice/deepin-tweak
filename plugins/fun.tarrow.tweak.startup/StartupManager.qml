import Nemo.DBus 2.0
import Qt.labs.platform 1.1
import QtQuick 2.15
import org.deepin.tweak 1.0

Item {
    id: startupManager

    // 模型用于存储启动项数据
    property ListModel startupItemsModel
    property ListModel noStartupItemsModel

    // 启动项加载完成的信号
    signal startupItemsLoaded()
    // 启动项移除成功的信号
    signal startupItemRemoved(int index)
    // 启动项添加成功的信号
    signal startupItemAdded(int index)
    // 未设置为启动项的App加载完成
    signal noStartupItemsLoaded()

    // 加载启动项列表
    function loadStartupItems() {
        applicationManager.call("AutostartList", [], function(result) {
            // 清空模型
            startupItemsModel.clear();
            result.forEach(function(item) {
                if (!(item.startsWith("/etc/xdg/autostart/"))) {
                    // 将名称和路径存储到模型中

                    let file = Tweak.newFile(item);
                    let open = file.open(FileMode.ReadOnly);
                    if (open) {
                        let fileContent = file.readAll();
                        let entryInfo = getDesktopEntryInfo(fileContent, item, true);
                        if (entryInfo.name)
                            startupItemsModel.append({
                            "name": entryInfo.name,
                            "path": entryInfo.path,
                            "iconName": entryInfo.iconName
                        });

                    }
                }
            });
            // 发送启动项加载完成的信号
            startupItemsLoaded();
        });
    }

    // 移除启动项
    function removeStartupItem(index) {
        let itemPath = startupItemsModel.get(index).path;
        applicationManager.call("RemoveAutostart", itemPath, function(result) {
            if (result == true) {
                // 发送启动项移除成功的信号
                startupItemRemoved(index);
                console.log('移除启动项' + itemPath + '成功');
            }
        });
    }

    // 添加启动项
    function addStartupItem(path, index) {
        applicationManager.call("AddAutostart", path, function(result) {
            if (result == true) {
                // 将名称和路径存储到模型中

                let file = Tweak.newFile(path);
                let open = file.open(FileMode.ReadOnly);
                if (open) {
                    let fileContent = file.readAll();
                    let entryInfo = getDesktopEntryInfo(fileContent, path, true);
                    if (entryInfo.name)
                        startupItemsModel.append({
                        "name": entryInfo.name,
                        "path": entryInfo.path,
                        "iconName": entryInfo.iconName
                    });

                }
                console.log("添加启动项：" + path + " 成功");
                startupItemAdded(index);
            }
        });
    }

    function loadApps() {
        noStartupItemsModel.clear();
        console.log("加载未添加的开机启动项");
        let desktopFiles = [];
        let addedPaths = [];
        for (let i = 0; i < startupItemsModel.count; i++) {
            addedPaths.push(startupItemsModel.get(i).path);
        }
        //console.log(addedPaths);
        launcher.call("GetAllItemInfos", [], function(result) {
            var userLocations = StandardPaths.standardLocations(StandardPaths.GenericDataLocation);
            var userLocationPath = userLocations[0].slice('files://'.length - 1) + '/applications';
            result.forEach(function(item) {
                // 将名称和路径存储到模型中

                // 判断 item[0] 是否已存在
                if (addedPaths.includes(item[0]) || item[0].startsWith(userLocationPath))
                    return ;

                let file = Tweak.newFile(item[0]);
                let open = file.open(FileMode.ReadOnly);
                if (open) {
                    let fileContent = file.readAll();
                    let entryInfo = getDesktopEntryInfo(fileContent, item[0], false);
                    if (entryInfo.name)
                        noStartupItemsModel.append({
                        "name": entryInfo.name,
                        "path": entryInfo.path,
                        "iconName": entryInfo.iconName
                    });

                }
            });
            noStartupItemsLoaded();
        });
    }

    // 获取 desktop 文件的名称、图标和执行命令信息
    function getDesktopEntryInfo(fileContent, item, isLoading) {
        let regex = /^\[Desktop Entry\][\s\S]*?^Name=(.*)$/m;
        let match = regex.exec(fileContent);
        let name = match && match.length > 1 ? match[1].trim() : "";
        let iconName;
        let fileName;
        let filePath;
        // 获取 desktop 文件的 Icon 字段值
        regex = /^\[Desktop Entry\][\s\S]*?^Icon=(.*)$/m;
        match = regex.exec(fileContent);
        iconName = match && match.length > 1 ? match[1].trim() : "";
        if (iconName.startsWith("/usr/share") || iconName.startsWith("/opt")) {
            iconName = iconName.substring(iconName.lastIndexOf("/") + 1);
            iconName = iconName.substring(0, iconName.lastIndexOf("."));
        }
        if (isLoading) {
            // 获取 desktop 文件的 Exec 字段值
            regex = /^\[Desktop Entry\][\s\S]*?^Exec=(.*)$/m;
            let execMatch = regex.exec(fileContent);
            if (execMatch && execMatch.length > 1) {
                let exec = execMatch[1].trim();
                if (exec.startsWith("ll-cli")) {
                    fileName = item.substring(item.lastIndexOf("/") + 1);
                    filePath = "/persistent/linglong/entries/share/applications/" + fileName;
                } else {
                    fileName = item.substring(item.lastIndexOf("/") + 1);
                    filePath = "/usr/share/applications/" + fileName;
                }
            }
        } else {
            filePath = item;
        }
        return {
            "name": name,
            "path": filePath,
            "iconName": iconName
        };
    }

    // DBus接口
    DBusInterface {
        id: applicationManager

        service: 'org.deepin.dde.Application1.Manager'
        iface: 'org.deepin.dde.Application1.Manager'
        path: '/org/deepin/dde/Application1/Manager'
    }

    DBusInterface {
        id: launcher

        service: 'org.deepin.dde.Application1.Manager'
        iface: 'org.deepin.dde.daemon.Launcher1'
        path: '/org/deepin/dde/daemon/Launcher1'
    }

    startupItemsModel: ListModel {
    }

    noStartupItemsModel: ListModel {
    }

}
