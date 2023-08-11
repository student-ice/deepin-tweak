import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.7
import org.deepin.dtk 1.0

Popup {
    id: popup

    property ListModel listViewModel

    listViewModel: ListModel {
    }

    property int selectIndex: -1

    width: parent.width
    height: parent.height
    modal: true
    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            Item {
                Layout.fillWidth: true
            }

            Text {
                text: "添加开机启动项"
                Layout.alignment: Qt.AlignCenter
            }

            Item {
                Layout.fillWidth: true
            }
            // 关闭按钮

            WindowButton {
                id: btn

                Layout.alignment: Qt.AlignRight
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                icon.name: "window_close"
                icon.width: width
                icon.height: height
                onClicked: {
                    popup.close();
                }
            }

        }

        ListView {
            Layout.topMargin: 15
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 5
            model: popup.listViewModel

            delegate: ItemDelegate {
                width: listView.width - 20
                icon.name: model.iconName
                text: model.name
                onClicked: {
                    listView.currentIndex = index;
                }
            }

        }

        Button {
            id: addBtn

            text: "添加"
            Layout.fillWidth: true
            onClicked: {
                console.log(listViewModel.get(listView.currentIndex).path);
                startupManager.addStartupItem(listViewModel.get(listView.currentIndex).path, listView.currentIndex);
            }
        }

    }

}
