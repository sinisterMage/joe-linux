#include "diskmodel.h"

#include <algorithm>

#include <QJsonObject>

int DiskModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : int(m_disks.size());
}

// Sizes as disks are sold: decimal units.
QString DiskModel::sizeText(qint64 bytes)
{
    const double gb = double(bytes) / 1e9;
    if (gb >= 1000)
        return QStringLiteral("%1 TB").arg(gb / 1000, 0, 'f', gb >= 10000 ? 0 : 1);
    if (gb >= 10)
        return QStringLiteral("%1 GB").arg(qRound(gb));
    return QStringLiteral("%1 GB").arg(gb, 0, 'f', 1);
}

static QString transportText(const QString &tran, bool removable)
{
    if (tran == QLatin1String("nvme"))
        return QStringLiteral("NVMe");
    if (tran == QLatin1String("sata") || tran == QLatin1String("ata"))
        return QStringLiteral("SATA");
    if (tran == QLatin1String("usb"))
        return QStringLiteral("USB");
    if (tran == QLatin1String("mmc"))
        return QStringLiteral("Memory card");
    if (tran.isEmpty())
        return removable ? QStringLiteral("removable") : QString();
    return tran.toUpper();
}

static QString displayName(const Disk &d)
{
    if (!d.model.isEmpty())
        return d.model;
    return d.device.section(QLatin1Char('/'), -1);
}

QVariant DiskModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_disks.size())
        return {};
    const Disk &d = m_disks.at(index.row());
    switch (role) {
    case PathRole: return d.path;
    case DeviceRole: return d.device;
    case NameRole: return displayName(d);
    case SizeTextRole: return sizeText(d.size);
    case TransportTextRole: return transportText(d.transport, d.removable);
    case RemovableRole: return d.removable;
    case UsableRole: return d.usable;
    case ReasonRole: return d.reason;
    case ContentsRole: return d.contents;
    case SegmentsRole: return d.segments;
    }
    return {};
}

QHash<int, QByteArray> DiskModel::roleNames() const
{
    return {
        {PathRole, "path"},
        {DeviceRole, "device"},
        {NameRole, "name"},
        {SizeTextRole, "sizeText"},
        {TransportTextRole, "transportText"},
        {RemovableRole, "removable"},
        {UsableRole, "usable"},
        {ReasonRole, "reason"},
        {ContentsRole, "contents"},
        {SegmentsRole, "segments"},
    };
}

void DiskModel::setDisks(const QJsonArray &disks)
{
    beginResetModel();
    m_disks.clear();
    for (const QJsonValue &v : disks) {
        const QJsonObject o = v.toObject();
        Disk d;
        d.path = o.value(QLatin1String("path")).toString();
        d.device = o.value(QLatin1String("device")).toString();
        d.size = qint64(o.value(QLatin1String("size")).toDouble());
        d.model = o.value(QLatin1String("model")).toString();
        d.transport = o.value(QLatin1String("transport")).toString();
        d.removable = o.value(QLatin1String("removable")).toBool();
        d.usable = o.value(QLatin1String("usable")).toBool();
        d.reason = o.value(QLatin1String("reason")).toString();
        for (const QJsonValue &c : o.value(QLatin1String("contents")).toArray()) {
            const QJsonObject co = c.toObject();
            const QString label = co.value(QLatin1String("label")).toString();
            const QString fstype = co.value(QLatin1String("fstype")).toString();
            const QString size = sizeText(qint64(co.value(QLatin1String("size")).toDouble()));
            d.contents << (label.isEmpty() ? QStringLiteral("an unnamed %1 partition (%2)").arg(fstype, size)
                                           : QStringLiteral("%1 (%2, %3)").arg(label, fstype, size));
            if (d.size > 0) {
                d.segments << QVariantMap{
                    {QStringLiteral("label"), label.isEmpty() ? fstype : label},
                    {QStringLiteral("fraction"), co.value(QLatin1String("size")).toDouble() / double(d.size)},
                };
            }
        }
        m_disks << d;
    }
    // Disks that can be used first, the largest first: the likely choice is
    // at the top.
    std::stable_sort(m_disks.begin(), m_disks.end(), [](const Disk &a, const Disk &b) {
        if (a.usable != b.usable)
            return a.usable;
        return a.size > b.size;
    });
    endResetModel();
    emit countChanged();
}

int DiskModel::usableCount() const
{
    return int(std::count_if(m_disks.begin(), m_disks.end(), [](const Disk &d) { return d.usable; }));
}

int DiskModel::indexOfPath(const QString &path) const
{
    for (int i = 0; i < m_disks.size(); ++i) {
        if (m_disks.at(i).path == path || m_disks.at(i).device == path)
            return i;
    }
    return -1;
}

QVariantMap DiskModel::get(int row) const
{
    QVariantMap map;
    if (row < 0 || row >= m_disks.size())
        return map;
    const QModelIndex i = index(row);
    const auto roles = roleNames();
    for (auto it = roles.begin(); it != roles.end(); ++it)
        map.insert(QString::fromLatin1(it.value()), data(i, it.key()));
    return map;
}
