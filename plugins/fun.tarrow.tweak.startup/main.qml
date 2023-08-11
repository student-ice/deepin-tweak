import Nemo.DBus 2.0
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.7
import org.deepin.dtk 1.0
import org.deepin.tweak 1.0

Frame {
    id: frame

    property string displayName: qsTr("Startup Manager")
    property string description: qsTr("Manage user startup items")
    property string version: "0.0.1"
    property string author: "ice"
    property string icon: "icon.png"

    StartupManager {
        id: startupManager

        onStartupItemsLoaded: {
            // 更新列表视图的数据
            listView.model = startupManager.startupItemsModel;
        }
        onStartupItemRemoved: {
            // 从列表视图中移除已删除的启动项
            listView.model.remove(index);
            startupManager.startupItemsModel = listView.model;
        }
        onStartupItemAdded: {
            dialogLoader.item.listViewModel.remove(index);
        }
        onNoStartupItemsLoaded: {
            dialogLoader.item.listViewModel = startupManager.noStartupItemsModel;
        }
    }

    ColumnLayout {
        anchors.fill: parent

        ListView {
            id: listView

            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 5
            Component.onCompleted: {
                //loadAutostartItems();
                // 加载启动项列表
                startupManager.loadStartupItems();
            }

            model: ListModel {
            }

            delegate: ItemDelegate {
                width: listView.width
                icon.name: model.iconName
                text: model.name
                onClicked: {
                    listView.currentIndex = index;
                }

                RowLayout {
                    anchors.fill: parent

                    Button {
                        id: rmBtn

                        property int itemIndex: index

                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 30
                        Layout.rightMargin: 2
                        text: "删除"
                        Layout.alignment: Qt.AlignRight
                        onClicked: {
                            startupManager.removeStartupItem(itemIndex);
                        }
                    }

                }

            }

        }

        RowLayout {
            Layout.leftMargin: 5
            Layout.rightMargin: 5
            Layout.bottomMargin: 5
            Layout.alignment: Qt.AlignBottom

            Button {
                id: addBtn

                text: "添加"
                Layout.fillWidth: true
                onClicked: {
                    // 设置对话框的可见性为true，显示对话框
                    dialogLoader.item.visible = true;
                    startupManager.loadApps();
                }
            }

        }

    }

    Loader {
        id: dialogLoader

        anchors.fill: parent
        source: "./Dialog.qml"
    }

}
