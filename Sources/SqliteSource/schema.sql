CREATE TABLE IF NOT EXISTS Entities (
    "id" TEXT PRIMARY KEY,
    "type" TEXT,
    "version" INT
);

CREATE TABLE IF NOT EXISTS Events (
    "entity" TEXT REFERENCES Entities(id),
    "name" TEXT,
    "details" TEXT,
    "actor" TEXT,
    "timestamp" REAL NOT NULL DEFAULT (julianday('now', 'utc')),
    "version" INT,
    "position" BIGINT
);
