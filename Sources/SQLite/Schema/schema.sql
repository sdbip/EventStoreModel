CREATE TABLE IF NOT EXISTS "Entities" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "type" TEXT NOT NULL,
    "version" INT NOT NULL
);

CREATE TABLE IF NOT EXISTS "Events" (
    "entityId" TEXT NOT NULL,
    "entityType" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "details" TEXT NOT NULL,
    "actor" TEXT NOT NULL,
    "timestamp" DECIMAL(14, 7) NOT NULL DEFAULT (cast(julianday(CURRENT_TIMESTAMP) AS REAL)),
    "version" INT NOT NULL,
    "position" BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS "Properties" (
    "name" TEXT NOT NULL,
    "value" DATA NOT NULL
);

INSERT INTO "Properties" ("name", "value") SELECT 'next_position', 0
    WHERE NOT EXISTS (SELECT 1 FROM "Properties" WHERE "name" = 'next_position');
