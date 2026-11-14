// The disks `dave install-system --list --json` reports, for the disk page.
#pragma once

#include <QAbstractListModel>
#include <QJsonArray>
#include <QList>
#include <QString>
#include <QtQml/qqmlregistration.h>

struct Disk {
    QString path;       // what is passed as --disk
    QString device;
    qint64 size = 0;
    QString model;
    QString transport;
    bool removable = false;
    bool usable = false;
    QString reason;     // why it cannot be used
    QStringList contents; // "Windows (ntfs, 512 GB)", ...
    QVariantList segments; // {label, fraction} per file system, for the disk strip
};

class DiskModel : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("provided by Backend")
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(int usableCount READ usableCount NOTIFY countChanged)

public:
    enum Role {
        PathRole = Qt::UserRole + 1,
        DeviceRole,
        NameRole,
        SizeTextRole,
        TransportTextRole,
        RemovableRole,
        UsableRole,
        ReasonRole,
        ContentsRole,
        SegmentsRole,
    };

    using QAbstractListModel::QAbstractListModel;

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setDisks(const QJsonArray &disks);
    int usableCount() const;
    Q_INVOKABLE int indexOfPath(const QString &path) const;
    Q_INVOKABLE QVariantMap get(int row) const;

    static QString sizeText(qint64 bytes);

signals:
    void countChanged();

private:
    QList<Disk> m_disks;
};
