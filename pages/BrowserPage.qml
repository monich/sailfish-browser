/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Vesa-Matti Hartikainen <vesa-matti.hartikainen@jollamobile.com>
**
****************************************************************************/


import QtQuick 1.1
import Sailfish.Silica 1.0
import QtWebKit 1.1

import "history.js" as History

Page {
    id: browserPage

    property alias url: webContent.url
    property bool ignoreStoreUrl: true
    property alias tabs: tabModel
    property int currentTab: 0

    function newTab() {
        tabModel.append({"thumbPath": "", "url": ""})
        currentTab = tabModel.count -1
    }

    ListModel {
        id: historyModel
        ListElement {title: "Jolla"; url: "http://www.jolla.com/"; icon: "image://theme/icon-m-region"}
        ListElement {title: "Sailfish OS"; url: "http://www.sailfishos.org/"; icon: "image://theme/icon-m-region"}
        ListElement {title: "Mer-project"; url: "http://www.merproject.org/"; icon: "image://theme/icon-m-region"}
        ListElement {title: "Twitter"; url: "http://www.twitter.com/"; icon: "image://theme/icon-m-region"}
        ListElement {title: "Google"; url: "http://www.google.com/"; icon: "image://theme/icon-m-region"}
        ListElement {title: "Facebook"; url: "http://www.facebook.com/"; icon: "image://theme/icon-m-region"}
    }

    ListModel {
        id:tabModel
        ListElement { thumbPath: ""; url: ""}
    }

    SilicaFlickable {
        clip: true
        contentHeight: webContent.height
        contentWidth: webContent.width
        interactive: true

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: tools.top
        }

        // Placeholder while we don't yet have gecko in images
        WebView {
            id: webContent
            url: Parameters.initialPage()
            transformOrigin: Item.TopLeft
            preferredHeight: browserPage.height - tools.height
            preferredWidth: browserPage.width
            opacity: status == WebView.Loading ? maxProgress : 1.0

            property double maxProgress: 0

            onLoadFinished: {
                if (!ignoreStoreUrl
                        && url !== historyModel.get(historyModel.count-1)
                        && url !== Parameters.homePage) {
                    History.addRow(url,webContent.title, "image://theme/icon-m-region")
                    historyModel.append({"url": url,
                                         "title": webContent.title,
                                         "icon:": "image://theme/icon-m-region"})
                }
                ignoreStoreUrl = false
                maxProgress = 0
            }

            onProgressChanged: {
                if (status == WebView.Loading) {
                    if (progress > maxProgress) {
                        maxProgress = progress
                    }
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    id: bouncebehavior
                    easing.type: Easing.InOutQuad
                    duration: 300
                }
            }
        }
    }

    Row {
        id: tools
        anchors {
            bottom: browserPage.bottom
            left: browserPage.left
            right: browserPage.right
        }

        IconButton {
            id:backIcon
            icon.source: "image://theme/icon-l-left"
            enabled: webContent.back.enabled

            onClicked: {
                ignoreStoreUrl = true
                webContent.back.trigger()
            }
        }

        Label {
            id: title
            text: webContent.status == WebView.Loading ? webContent.statusText : webContent.title
            width: browserPage.width - (backIcon.width + right.width)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter
            truncationMode: TruncationMode.Fade

            MouseArea {
                anchors.fill: parent
                onClicked:  {
                    var screenPath = BrowserTab.screenCapture()

                    tabModel.set(currentTab, {"thumbPath" : screenPath, "url" : webContent.url})

                    var component = Qt.createComponent("ControlPage.qml");
                    if (component.status === Component.Ready) {
                        var sendUrl = (webContent.url!=Parameters.homePage) ? webContent.url:""
                        pageStack.push(component, {historyModel : historyModel, url : sendUrl}, true);
                    } else {
                        console.log("Error loading component:", component.errorString());
                    }
                }
            }
        }

        Slider {
            anchors {
                bottom: tools.bottom
                horizontalCenter: tools.horizontalCenter
            }
            minimumValue: 0
            maximumValue: 1

            width: title.width
            height: 25

            enabled: false
            handleVisible: false

            visible: webContent.status == WebView.Loading
            value: visible ? webContent.progress : 0

        }

        IconButton {
            id: right
            icon.source: "image://theme/icon-l-right"
            enabled: webContent.forward.enabled
            onClicked: {
                ignoreStoreUrl = true
                webContent.forward.trigger()
            }
        }
    }

    Component.onCompleted: {
        History.loadModel(historyModel)
    }
}

