// Apps shown in the search overlay before anything is typed (Desktop design:
// SEARCH, five results with an empty query): the dock's pinned apps, then
// the launcher's usual first apps when the dock has fewer than five.
#pragma once

#include <QObject>
#include <QVariantList>

class Controller : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.aedwen.Search")
    Q_PROPERTY(QVariantList suggestions READ suggestions NOTIFY suggestionsChanged)

public:
    explicit Controller(QObject *parent = nullptr);

    QVariantList suggestions() const { return m_suggestions; }

    // Starts an application by desktop file id ("org.kde.dolphin").
    Q_INVOKABLE void launch(const QString &desktopId);

public Q_SLOTS:
    // D-Bus (org.aedwen.search /Search): show the overlay, pre-filled with
    // `query`; toggle() shows it empty, or hides it when it's open.
    Q_SCRIPTABLE void query(const QString &query);
    Q_SCRIPTABLE void toggle();
    void refresh();

Q_SIGNALS:
    void suggestionsChanged();
    void showRequested(const QString &query);
    void toggleRequested();

private:
    QVariantList m_suggestions;
};
