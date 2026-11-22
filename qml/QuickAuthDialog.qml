/*  This file is part of the KDE project
    SPDX-FileCopyrightText: 2021 Aleix Pol Gonzalez <aleixpol@kde.org>
    SPDX-FileCopyrightText: 2023 Devin Lin <devin@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtMultimedia

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.sounds
import org.kde.polkitkde

Kirigami.AbstractApplicationWindow {
    id: root
    title: i18n("User Account Control") //i18n("Authentication Required")

    // 1. Detect if dark mode / Fusion dark is active
    readonly property bool isDarkMode: Qt.styleHints.colorScheme === Qt.ColorScheme.Dark || isFusionStyle

    maximumHeight: intendedWindowHeight
    minimumHeight: intendedWindowHeight
    minimumWidth: intendedWindowWidth
    maximumWidth: intendedWindowWidth
    width: intendedWindowWidth
    height: intendedWindowHeight

    property alias password: passwordField.text
    property alias identitiesModel: identitiesCombo.model
    property alias identitiesCurrentIndex: identitiesCombo.currentIndex
    property alias selectedIdentity: identitiesCombo.currentValue

    property bool waitingForAuthentication: false

    // passed in by QuickAuthDialog.cpp
    property string mainText
    property string subtitle
    property string descriptionString
    property string descriptionActionId
    property string descriptionVendorName
    property string descriptionVendorUrl
    property string descriptionIcon

    property bool sevenLike: true

    // 2. Define your Light and Dark color blocks
    readonly property var lightColors: ({
        windowBg: "#ffffff",
        footerBg: "#f0f0f0",
        borderColor: "#d9d9d9",
        primaryText: "#000000",
        secondaryText: "#4d4d4d"
    })

    readonly property var darkColors: ({
        windowBg: "#1e1e1e",
        footerBg: "#262626",
        borderColor: "#3a3a3a",
        primaryText: "#ffffff",
        secondaryText: "#b0b0b0"
    })

    readonly property var colors: isDarkMode ? darkColors : lightColors

    signal accept()
    signal reject()
    signal userSelected()

    onSelectedIdentityChanged: userSelected()

    onAccept: {
        waitingForAuthentication = true;
        // disable password field while password is being checked
        if (passwordField.text !== "") {
            passwordField.enabled = false;
        }
    }

    color: root.colors.windowBg

    Shortcut {
        sequence: StandardKey.Cancel
        onActivated: root.reject()
    }

    function rejectPassword() {
        passwordField.clear()
        passwordField.enabled = true
        passwordField.focus = true
        waitingForAuthentication = false;
    }

    function authenticationFailure() {
        authenticationError.visible = true;
        rejectPassword()
    }

    function request() {
        if (passwordField.text !== "" && waitingForAuthentication) {
            rejectPassword()
        }
    }

    readonly property real intendedWindowWidth: (Kirigami.Units.largeSpacing * 76) 
    readonly property real intendedWindowHeight: mainContent.implicitHeight + bottomControls.height + (Kirigami.Units.largeSpacing * 2)

    onActiveChanged: {
        if (active) {
            // immediately focus on password field when window is focused
            passwordField.forceActiveFocus();
        }
    }

    onVisibleChanged: {
        if (visible) {
            // immediately focus on password field on load
            passwordField.forceActiveFocus();
        } else {
            // reject on close
            root.reject();
        }
    }

    // select user combobox, we are displaying its popup
    property QQC2.ComboBox selectIdentityCombobox: QQC2.ComboBox {
        id: identitiesCombo
        visible: false
        textRole: "display"
        valueRole: "userRole"
        enabled: count > 0
        model: IdentitiesModel {
            id: identitiesModel
        }
    }

    Column {
        id: mainContent

        anchors.fill: parent

        spacing: 16

        Rectangle {
            id: header

            property bool isUnknown: descriptionActionId == "org.freedesktop.policykit.exec"

            anchors {
                right: parent.right
                left: parent.left
            }

            implicitHeight: root.sevenLike ? 52 : 40

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 1.0; color: header.isUnknown ? "#ffcd4a" : "#137798"}
                GradientStop { position: 0.0; color: header.isUnknown ? "#f4b200" : "#073f6e"}
            }

            RowLayout {
                spacing: Kirigami.Units.largeSpacing

                anchors {
                    fill: parent
                    leftMargin: Kirigami.Units.largeSpacing
                    rightMargin: Kirigami.Units.largeSpacing
                }

                Kirigami.Icon {
                    Layout.alignment: Qt.AlignVCenter

                    implicitWidth: Kirigami.Units.iconSizes.medium
                    implicitHeight: Kirigami.Units.iconSizes.medium

                    source: header.isUnknown ? "firewall-applet-panic" : "dialog-password"
                }

                Kirigami.Heading {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    level: 2
                    text: root.mainText
                    wrapMode: Text.Wrap
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    color: header.isUnknown ? "black" : "white"
                }
            }
        }

        ColumnLayout {
            id: contentItem

            anchors {
                right: parent.right
                left: parent.left
                margins: 20
            }

            spacing: root.sevenLike ? Kirigami.Units.smallSpacing + Kirigami.Units.largeSpacing : Kirigami.Units.largeSpacing

            RowLayout {
                id: content

                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: 50

                spacing: Kirigami.Units.largeSpacing * 3

                Kirigami.Icon {
                    implicitWidth: Kirigami.Units.iconSizes.medium
                    implicitHeight: Kirigami.Units.iconSizes.medium

                    Layout.alignment: Qt.AlignTop

                    source: descriptionIcon == "" ? "application-default-icon" : descriptionIcon
                }
                ColumnLayout {
                    spacing: 0
                    Row {
                        spacing: 4

                        QQC2.Label {
                            text: i18n("ID:")
                            visible: root.sevenLike
                        }

                        QQC2.Label {
                            text: descriptionActionId
                        }
                    }
                    Row {
                        spacing: 4

                        visible: descriptionVendorName !== ""

                        QQC2.Label {
                            text: i18n("Vendor:")
                            visible: root.sevenLike
                        }

                        QQC2.Label {
                            text: descriptionVendorName
                            font.bold: true

                            Kirigami.UrlButton {
                                anchors.left: parent.right

                                width: Kirigami.Units.iconSizes.small
                                height: parent.height

                                text: " "
                                url: descriptionVendorUrl
                                font.underline: false
                            }
                        }
                    }
                    Row {
                        spacing: 4

                        QQC2.Label {
                            text: i18n("Action:")
                            visible: root.sevenLike
                        }

                        QQC2.Label {
                            text: descriptionString
                        }
                    }
                }
            }

            ColumnLayout {
                spacing: Kirigami.Units.largeSpacing

                Rectangle {
                    id: sep

                    Layout.fillWidth: true
                    Layout.rightMargin: root.sevenLike ? -4 : 0
                    Layout.leftMargin: root.sevenLike ? -4 : 0

                    implicitHeight: 1

                    color: root.colors.borderColor
                }

                LayoutItemProxy { target: sep; visible: root.sevenLike }

                QQC2.Label {
                    Layout.fillWidth: true

                    wrapMode: Text.WordWrap
                    text: i18n("To continue, type an administrator password, and then click OK.")
                }

                LayoutItemProxy { target: sep; visible: !root.sevenLike }
            }

            Column {
                id: authenticationPrompt

                Layout.fillWidth: true

                spacing: Kirigami.Units.largeSpacing

                Item {
                    id: user

                    anchors {
                        right: parent.right
                        left: parent.left
                    }

                    height: 76

                    Row {
                        anchors.fill: parent

                        Item {
                                width: 64
                                height: 86
                                

                                // 1. User Avatar behind the frame
                                Image {
                                    anchors.centerIn: parent
                                    width: 48
                                    height: 48
                                    source: "file://" + identitiesModel.iconForIndex(identitiesCombo.currentIndex)
                                    smooth: true
                                }

                                // 2. Background-colored rectangle with a transparent circular hole
                                Canvas {
                                    id: roundCutout
                                    anchors.fill: parent
                                    antialiasing: true

                                    // Repaint automatically if the theme color changes
                                    property color frameColor: root.colors.windowBg
                                    property color ringColor: root.colors.borderColor
                                    onFrameColorChanged: requestPaint()
                                    onRingColorChanged: requestPaint()

                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();

                                        var cx = width / 2;
                                        var cy = height / 2;
                                        var r = 24; // Half of the 48x48 avatar size

                                        // Fill the entire square with the dialog's background color
                                        ctx.fillStyle = frameColor;
                                        ctx.fillRect(0, 0, width, height);

                                        // Punch a transparent circle in the center
                                        ctx.globalCompositeOperation = "destination-out";
                                        ctx.beginPath();
                                        ctx.arc(cx, cy, r, 0, Math.PI * 2, false);
                                        ctx.fill();

                                        // Optional: Draw a subtle border ring around the circular cutout
                                        ctx.globalCompositeOperation = "source-over";
                                        ctx.strokeStyle = ringColor;
                                        ctx.lineWidth = 1.5;
                                        ctx.beginPath();
                                        ctx.arc(cx, cy, r, 0, Math.PI * 2, false);
                                        ctx.stroke();
                                    }
                                }
                            }

                        ColumnLayout {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: 2

                            spacing: 9

                            RowLayout {
                                Kirigami.Heading {
                                    level: 2
                                    text: identitiesCombo.currentText
                                }
                                Kirigami.LinkButton {
                                    Layout.alignment: Qt.AlignVCenter
                                    id: switchButton
                                    text: i18n("Switch…")
                                    visible: identitiesCombo.count > 1
                                    onClicked: {
                                        identitiesCombo.popup.parent = switchButton;
                                        identitiesCombo.popup.open();
                                    }
                                }
                            }

                            Kirigami.PasswordField {
                                id: passwordField
                                Layout.alignment: Qt.AlignLeft
                                Layout.preferredHeight: 25
                                Layout.preferredWidth: 225
                                onAccepted: root.accept()
                                placeholderText: i18n("Password…")
                            }
                        }
                    }
                }

                Row {
                    id: authenticationError
                    visible: false
                    spacing: Kirigami.Units.smallSpacing
                    Kirigami.Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        source: "dialog-error"
                    }
                    Text {
                        color: root.colors.primaryText
                        anchors.verticalCenter: parent.verticalCenter
                        text: i18n("Authentication failure, please try again.")
                    }
                }
            }
        }
    }

    Rectangle {
        id: bottomControls

        anchors {
            bottom: parent.bottom
            right: parent.right
            left: parent.left
            margins: -1
        }

        height: 43

        border.width: 1
        border.color: root.colors.borderColor
        color: root.colors.footerBg

        RowLayout {
            anchors.fill: parent
            anchors.margins: 1
            anchors.rightMargin: 12

            spacing: 8

            Item { Layout.fillWidth: true }

            QQC2.Button {
                id: okButton
                implicitWidth: 73
                implicitHeight: 21
                bottomPadding: 2
                topPadding: 0
                onClicked: root.accept()
                contentItem: Text {
                    color: root.colors.primaryText
                    text: i18n("OK")
                    font: parent.font
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    radius: 2
                    border.width: okButton.hovered ? 1.5 : 0
                    border.color: "#1b4f9c" // Navy blue (or "#1b4f9c" for a softer Vista/7 blue)
                }
            }
            QQC2.Button {
                id: cancelButton
                implicitWidth: 73
                implicitHeight: 21
                bottomPadding: 2
                topPadding: 0
                onClicked: root.reject()
                contentItem: Text {
                    color: root.colors.primaryText
                    text: i18n("Cancel")
                    font: parent.font
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    radius: 2
                    border.width: cancelButton.hovered ? 1.5 : 0
                    border.color: "#1b4f9c" // Navy blue (or "#1b4f9c" for a softer Vista/7 blue)
                }
            }
        }
    }
    //Component.onCompleted: executable.exec("kreadconfig6 --file ~/.config/kdeglobals --group Sounds --key Theme");
}
