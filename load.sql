DROP TABLE IF EXISTS uk_rail_locations;
DROP TABLE IF EXISTS uk_rail_trains;
DROP TABLE IF EXISTS uk_rail_stops_stg;
DROP TABLE IF EXISTS uk_rail_stops;
CREATE TABLE uk_rail_locations (
    "tiploc"            VARCHAR(7)    PRIMARY KEY,
    "atoc_code"         VARCHAR(3)    NOT NULL,
    "station_name"      VARCHAR(26)   NULL
);
CREATE TABLE uk_rail_trains (
    "train_id"          INTEGER       PRIMARY KEY,
    "trans_typ"         VARCHAR(1)    NOT NULL DEFAULT '',
    "uid"               VARCHAR(6)    NOT NULL DEFAULT '',
    "start_date"        DATE          NULL,
    "end_date"          DATE          NULL,
    "mon"               TINYINT       NOT NULL DEFAULT 0,
    "tue"               TINYINT       NOT NULL DEFAULT 0,
    "wed"               TINYINT       NOT NULL DEFAULT 0,
    "thu"               TINYINT       NOT NULL DEFAULT 0,
    "fri"               TINYINT       NOT NULL DEFAULT 0,
    "sat"               TINYINT       NOT NULL DEFAULT 0,
    "sun"               TINYINT       NOT NULL DEFAULT 0,
    "toc_code"          VARCHAR(2)    NULL
);
CREATE TABLE uk_rail_stops_stg (
    "train_id"          INTEGER       NOT NULL,
    "line_num"          SMALLINT      NOT NULL,
    "tiploc"            VARCHAR(7)    NOT NULL DEFAULT '',
    "sched_arr"         VARCHAR(4)    NULL,
    "sched_dep"         VARCHAR(4)    NULL,
    PRIMARY KEY("train_id", "line_num")
);
CREATE TABLE uk_rail_stops (
    "train_id"          INTEGER       NOT NULL,
    "line_num"          SMALLINT      NOT NULL,
    "tiploc"            VARCHAR(7)    NOT NULL DEFAULT '',
    "sched_arr"         TIME          NULL,
    "sched_dep"         TIME          NULL,
    PRIMARY KEY("train_id", "line_num")
);
WbImport -file=./locations.csv
         -type=text
         -table=uk_rail_locations
         -encoding="UTF-8"
         -header=true
         -decode=false
         -delimiter=','
         -fileColumns=tiploc,atoc_code,station_name
         -quoteCharEscaping=none
         -ignoreIdentityColumns=false
         -deleteTarget=false
         -continueOnError=false
         -batchSize=10000;
WbImport -file=./trains.csv
         -type=text
         -table=uk_rail_trains
         -encoding="UTF-8"
         -header=true
         -decode=false
         -dateFormat=yyMMdd
         -delimiter=','
         -decimal=.
         -fileColumns=train_id,trans_typ,uid,start_date,end_date,mon,tue,wed,thu,fri,sat,sun,toc_code
         -quoteCharEscaping=none
         -ignoreIdentityColumns=false
         -deleteTarget=false
         -continueOnError=false
         -batchSize=50000;
WbImport -file=./stops.csv
         -type=text
         -table=uk_rail_stops_stg
         -encoding="UTF-8"
         -header=true
         -decode=false
         -dateFormat=yyMMdd
         -delimiter=','
         -decimal=.
         -fileColumns=train_id,line_num,tiploc,sched_arr,sched_dep
         -quoteCharEscaping=none
         -ignoreIdentityColumns=false
         -deleteTarget=false
         -continueOnError=false
         -batchSize=50000;
INSERT INTO uk_rail_stops
SELECT
    train_id,
    line_num,
    tiploc,
    TIME(LEFT(sched_arr, 2) || ':' || RIGHT(sched_arr, 2)) AS "sched_arr",
    TIME(LEFT(sched_dep, 2) || ':' || RIGHT(sched_dep, 2)) AS "sched_dep"
FROM uk_rail_stops_stg;
DROP TABLE IF EXISTS uk_rail_stops_stg;


DROP TABLE IF EXISTS uk_rail_tocs;
CREATE TABLE uk_rail_tocs (
    "toc_code"      VARCHAR(2)  PRIMARY KEY,
    "toc_name"      VARCHAR(50) NULL
);
INSERT INTO uk_rail_tocs VALUES
('C', 'Central Services'),
('D', 'Railfreight Distribution'),
('E', 'Train Operating Companies'),
('G', 'British Rail International'),
('H', 'Train Operating Companies'),
('J', 'Other Businesses'),
('K', 'BREL and Level 5 Depots'),
('L', 'Train Operating Companies'),
('P', 'Train Operating Companies'),
('Q', 'British Rail Headquarters'),
('R', 'British Rail Infrastructure Services'),
('T', 'NRCC'),
('U', 'Ex-British Rail (now privatised)'),
('V', 'Ex-British Rail (now privatised)'),
('W', 'DB Cargo UK'),
('X', 'Private owners'),
('Y', 'Private owners'),
('Z', 'Other businesses'),
-- Network Rail
('QA', 'HQ Functions'),
('QB', 'Sussex'),
('QC', 'Wessex'),
('QD', 'Western'),
('QE', 'Central'),
('QF', 'North West'),
('QG', 'North East'),
('QH', 'Anglia'),
('QI', 'East Coast'),
('QJ', 'Eastern'),
('QK', 'Southern'),
('QL', 'Scotland'),
('QM', 'Kent'),
('QN', 'WCML South'),
('QQ', 'High Speed 1'),
('QR', 'North West & Central'),
('QS', 'Scotland'),
('QU', 'Wales & Western'),
('QV', 'East Midlands'),
('QW', 'Wales'),
-- Non-Network Rail
('AR', 'Alliance Rail'),
('AW', 'Transport for Wales'),
('CC', 'c2c'),
('CH', 'Chiltern Railways'),
('CS', 'Caledonian Sleeper'),
('EM', 'East Midlands Railway'),
('ES', 'Eurostar'),
('FC', 'First Capital Connect'),
('FS', 'Fishbone Solutions'),
('GC', 'Grand Central'),
('GN', 'Govia Thameslink Railway (Great Northern)'),
('GR', 'London North Eastern Railway'),
('GW', 'Great Western Railway'),
('GX', 'Gatwick Express'),
('HC', 'Heathrow Connect'),
('HT', 'Hull Trains'),
('HX', 'Heathrow Express'),
('IL', 'Island Lines'),
('LD', 'Lumo'),
('LE', 'Greater Anglia'),
('LF', 'Grand Union Trains'),
('LM', 'West Midlands Trains'),
('LO', 'London Overground'),
('LR', 'Network Rail (On-Track Machines)'),
('LS', 'Locomotive Services'),
('LT', 'London Underground'),
('ME', 'Merseyrail'),
('NT', 'Northern Trains'),
('NY', 'North Yorkshire Moors Railway'),
('PX', 'Europhoenix'),
('SE', 'Southeastern'),
('SJ', 'South Yorkshire Supertram'),
('SN', 'Southern'),
('SP', 'Swanage Railway'),
('SR', 'ScotRail'),
('SW', 'South Western Railway'),
('TL', 'Thameslink'),
('TP', 'TransPennine Express'),
('TW', 'Nexus (Tyne & Wear Metro)'),
('TY', 'Vintage Trains'),
('VT', 'Avanti West Coast'),
('WR', 'West Coast Railways'),
('WS', 'Wrexham and Shropshire'),
('XC', 'CrossCountry'),
('XR', 'Elizabeth line')
;
WITH params AS ( -- Sample illustrating usage
    SELECT
        TIME('19:15') AS "dep_time",
        TIME(NULL) AS "arr_time",
        VARCHAR('GLYNDE') AS "orig",
        VARCHAR('BRGHTN') AS "dest",
        DATE(NULL) AS "trv_date"
)
, score AS (
    SELECT
        trn.train_id,
        MAX(
            5 * GREATEST(0, CASE                -- Up to 25 points for departing target origin at target dep time
                WHEN params.dep_time IS NULL THEN 0
                WHEN stp.sched_dep   IS NULL THEN 0
                WHEN params.orig IS NOT NULL AND params.orig != stp.tiploc AND params.orig != stn.station_name THEN 0
                ELSE 5 - ABS(LEAST(
                    TIMESTAMPDIFF(MINUTES, GREATEST(params.dep_time, stp.sched_dep), LEAST(params.dep_time, stp.sched_dep)),
                    TIMESTAMPDIFF(MINUTES, LEAST(params.dep_time, stp.sched_dep), GREATEST(params.dep_time, stp.sched_dep)) + 1440
                    ))                          -- Three points if the period in question is covered
                    + IF(IFNULL(params.trv_date, CURRENT_DATE) BETWEEN trn.start_date AND trn.end_date, 3, 0)
                END
            ) +
            5 * GREATEST(0, CASE                -- Up to 25 points for arriving at target destination at target arr time
                WHEN params.arr_time IS NULL THEN 0
                WHEN stp.sched_arr   IS NULL THEN 0
                WHEN params.dest IS NOT NULL AND params.dest != stp.tiploc AND params.dest != stn.station_name THEN 0
                ELSE 5 - ABS(LEAST(
                    TIMESTAMPDIFF(MINUTES, GREATEST(params.arr_time, stp.sched_arr), LEAST(params.arr_time, stp.sched_arr)),
                    TIMESTAMPDIFF(MINUTES, LEAST(params.arr_time, stp.sched_arr), GREATEST(params.arr_time, stp.sched_arr)) + 1440
                    ))                          -- Three points if the period in question is covered
                    + IF(IFNULL(params.trv_date, CURRENT_DATE) BETWEEN trn.start_date AND trn.end_date, 3, 0)
                END
            )
         ) AS "train_score"
    FROM uk_rail_trains AS trn
    CROSS JOIN params
    JOIN uk_rail_stops AS stp ON stp.train_id = trn.train_id
    JOIN uk_rail_locations AS stn ON stn.tiploc = stp.tiploc
    WHERE CASE -- Require it operates on the specified date
        WHEN params.trv_date IS NULL THEN 1
        WHEN DOW(params.trv_date) = 'Mon' THEN trn.mon
        WHEN DOW(params.trv_date) = 'Tue' THEN trn.tue
        WHEN DOW(params.trv_date) = 'Wed' THEN trn.wed
        WHEN DOW(params.trv_date) = 'Thu' THEN trn.thu
        WHEN DOW(params.trv_date) = 'Fri' THEN trn.fri
        WHEN DOW(params.trv_date) = 'Sat' THEN trn.sat
        WHEN DOW(params.trv_date) = 'Sun' THEN trn.sun
        ELSE 0 END = 1
    AND CASE
        WHEN params.dep_time IS NULL THEN 1
        WHEN ABS(stp.sched_dep - params.dep_time) < 3 THEN 1
        ELSE 0 END = 1
    AND CASE
        WHEN params.arr_time IS NULL THEN 1
        WHEN ABS(stp.sched_arr - params.arr_time) < 3 THEN 1
        ELSE 0 END = 1
    AND EXISTS ( -- Require that origin or destination is on this train route
        SELECT 1
        FROM uk_rail_stops AS spec
        WHERE spec.train_id = trn.train_id
        AND spec.tiploc IN (params.orig, params.dest)
    )
    GROUP BY 1
)
, targs AS (
    SELECT
        train_id,
        train_score,
        DENSE_RANK() OVER (ORDER BY train_score DESC) AS "rnk"
    FROM score
    WHERE train_score > 0
)
SELECT FIRST 200
    targs.train_id
    targs.train_score,
    trn.toc_code,
    IFNULL(toc.toc_name, 'Unknown') AS "toc",
    trn.uid,
    stp.line_num,
    CASE
        WHEN params.orig IS NULL      THEN ''
        WHEN params.orig = stp.tiploc THEN 'O'
        WHEN params.dest = stp.tiploc THEN 'D'
        ELSE '' END AS "relevance",
    stn.atoc_code,
    stn.station_name,
    stp.sched_arr,
    stp.sched_dep,
    trn.start_date,
    trn.end_date
FROM targs
CROSS JOIN params
JOIN uk_rail_trains AS trn ON trn.train_id = targs.train_id
JOIN uk_rail_stops AS stp ON stp.train_id = trn.train_id
JOIN uk_rail_locations AS stn ON stn.tiploc = stp.tiploc
LEFT JOIN uk_rail_tocs AS toc ON toc.toc_code = trn.toc_code
WHERE targs.rnk = 1
ORDER BY targs.train_score DESC, targs.train_id ASC, stp.line_num ASC
