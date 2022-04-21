CREATE TABLE IF NOT EXISTS Entities (
    "id" TEXT NOT NULL PRIMARY KEY,
    "type" TEXT NOT NULL,
    "version" INT NOT NULL
);

CREATE TABLE IF NOT EXISTS Events (
    "entity" TEXT NOT NULL REFERENCES Entities(id),
    "name" TEXT NOT NULL,
    "details" TEXT NOT NULL,
    "actor" TEXT NOT NULL,
    "timestamp" REAL NOT NULL DEFAULT (julianday('now', 'utc')),
    "version" INT NOT NULL,
    "position" BIGINT NOT NULL
);
