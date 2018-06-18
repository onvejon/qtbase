/****************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the plugins of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 3 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL3 included in the
** packaging of this file. Please review the following information to
** ensure the GNU Lesser General Public License version 3 requirements
** will be met: https://www.gnu.org/licenses/lgpl-3.0.html.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 2.0 or (at your option) the GNU General
** Public license version 3 or any later version approved by the KDE Free
** Qt Foundation. The licenses are as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL2 and LICENSE.GPL3
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-2.0.html and
** https://www.gnu.org/licenses/gpl-3.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

#include "qnswindowdelegate.h"
#include "qcocoahelpers.h"
#include "qcocoawindow.h"
#include "qcocoascreen.h"

#include <QDebug>
#include <QtCore/private/qcore_mac_p.h>
#include <qpa/qplatformscreen.h>
#include <qpa/qwindowsysteminterface.h>

static QRegExp whitespaceRegex = QRegExp(QStringLiteral("\\s*"));

@implementation QNSWindowDelegate {
    QCocoaWindow *m_cocoaWindow;
}

- (instancetype)initWithQCocoaWindow:(QCocoaWindow *)cocoaWindow
{
    if ((self = [self init]))
        m_cocoaWindow = cocoaWindow;
    return self;
}

- (BOOL)windowShouldClose:(NSNotification *)notification
{
    Q_UNUSED(notification);
    if (m_cocoaWindow) {
        return m_cocoaWindow->windowShouldClose();
    }

    return YES;
}
/*!
    Overridden to ensure that the zoomed state always results in a maximized
    window, which would otherwise not be the case for borderless windows.
*/
- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)proposedFrame
{
    Q_UNUSED(proposedFrame);
    Q_ASSERT(window == m_cocoaWindow->nativeWindow());

    // We compute the maximized state based on the maximum size, and
    // the current position of the window. This may result in the window
    // geometry falling outside of the current screen's available geometry,
    // e.g. when there is not maximize size set, but this is okey, AppKit
    // will then shift and possibly clip the geometry for us.
    const QWindow *w = m_cocoaWindow->window();
    QRect maximizedRect = QRect(w->framePosition(), w->maximumSize());

    // QWindow::maximumSize() refers to the client size,
    // but AppKit expects the full frame size.
    maximizedRect.adjust(0, 0, 0, w->frameMargins().top());

    return QCocoaScreen::mapToNative(maximizedRect);
}

- (BOOL)window:(NSWindow *)window shouldPopUpDocumentPathMenu:(NSMenu *)menu
{
    Q_UNUSED(window);
    Q_UNUSED(menu);

    // Only pop up document path if the filename is non-empty. We allow whitespace, to
    // allow faking a window icon by setting the file path to a single space character.
    return !whitespaceRegex.exactMatch(m_cocoaWindow->window()->filePath());
}

- (BOOL)window:(NSWindow *)window shouldDragDocumentWithEvent:(NSEvent *)event from:(NSPoint)dragImageLocation withPasteboard:(NSPasteboard *)pasteboard
{
    Q_UNUSED(window);
    Q_UNUSED(event);
    Q_UNUSED(dragImageLocation);
    Q_UNUSED(pasteboard);

    // Only allow drag if the filename is non-empty. We allow whitespace, to
    // allow faking a window icon by setting the file path to a single space.
    return !whitespaceRegex.exactMatch(m_cocoaWindow->window()->filePath());
}
@end
