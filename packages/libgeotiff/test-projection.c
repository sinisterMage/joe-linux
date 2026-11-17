/* Regression consumers for spherical method1024 versus ellipsoidal Mercator. */
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "geotiff.h"
#include "geo_normalize.h"
#include "geovalues.h"

static const double pi = 3.14159265358979323846;
static const double radius = 6378137.0;
static const double minor = 6356752.3142451793;

static void close_to(const char *label, double actual, double expected, double tolerance)
{
    if (!isfinite(actual) || fabs(actual - expected) > tolerance)
    {
        fprintf(stderr, "%s: got %.15g, expected %.15g\n", label, actual, expected);
        exit(1);
    }
}

static void init_defn(GTIFDefn *defn, short method)
{
    memset(defn, 0, sizeof(*defn));
    defn->DefnSet = 1;
    defn->Model = ModelTypeProjected;
    defn->PCS = method == 1024 ? 3857 : 3395;
    defn->GCS = GCS_WGS_84;
    defn->Ellipsoid = Ellipse_WGS_84;
    defn->SemiMajor = radius;
    defn->SemiMinor = minor;
    defn->UOMLength = Linear_Meter;
    defn->UOMLengthInMeters = 1.0;
    defn->UOMAngle = Angular_Degree;
    defn->UOMAngleInDegrees = 1.0;
    defn->Projection = method;
    defn->CTProjection = CT_Mercator;
    defn->ProjParm[4] = 1.0;
}

int main(void)
{
    GTIFDefn defn;
    const double eastings[] = {1000.0, -1000000.0, 0.0};
    const double northings[] = {2000.0, 2000000.0, 0.0};
    double x[3], y[3];
    init_defn(&defn, 1024);
    memcpy(x, eastings, sizeof(x));
    memcpy(y, northings, sizeof(y));
    if (!GTIFProj4ToLatLong(&defn, 3, x, y))
        return 1;
    for (int i = 0; i < 3; ++i)
    {
        close_to("pseudo-Mercator longitude", x[i], eastings[i] / radius * 180.0 / pi, 2e-10);
        close_to("pseudo-Mercator latitude", y[i], atan(sinh(northings[i] / radius)) * 180.0 / pi, 2e-10);
    }
    if (!GTIFProj4FromLatLong(&defn, 3, x, y))
        return 1;
    for (int i = 0; i < 3; ++i)
    {
        close_to("pseudo-Mercator easting roundtrip", x[i], eastings[i], 1e-5);
        close_to("pseudo-Mercator northing roundtrip", y[i], northings[i], 1e-5);
    }

    /* Operation method, not a special-cased EPSG CRS number, determines equations. */
    defn.PCS = KvUserDefined;
    defn.ProjParm[1] = 10.0;
    defn.ProjParm[5] = 100.0;
    defn.ProjParm[6] = -200.0;
    x[0] = 12.0;
    y[0] = 49.0;
    if (!GTIFProj4FromLatLong(&defn, 1, x, y))
        return 1;
    close_to("custom pseudo-Mercator easting", x[0], radius * 2.0 * pi / 180.0 + 100.0, 1e-5);
    close_to("custom pseudo-Mercator northing", y[0], radius * log(tan(pi / 4.0 + 49.0 * pi / 360.0)) - 200.0, 1e-5);

    /* Ordinary World Mercator must retain ellipsoidal equations. */
    init_defn(&defn, 9804);
    x[0] = 2.0;
    y[0] = 49.0;
    const double latitude = y[0] * pi / 180.0;
    const double eccentricity = sqrt(1.0 - minor * minor / (radius * radius));
    const double expected_y = radius * log(tan(pi / 4.0 + latitude / 2.0) *
        pow((1.0 - eccentricity * sin(latitude)) /
            (1.0 + eccentricity * sin(latitude)), eccentricity / 2.0));
    if (!GTIFProj4FromLatLong(&defn, 1, x, y))
        return 1;
    close_to("ellipsoidal Mercator easting", x[0], radius * 2.0 * pi / 180.0, 1e-5);
    close_to("ellipsoidal Mercator northing", y[0], expected_y, 1e-5);
    puts("Public GeoTIFF forward/inverse pseudo-Mercator and ellipsoidal Mercator consumers PASSED");
    return 0;
}
