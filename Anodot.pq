section Anodot;

//
// Definition
// Data Source Kind description
Anodot = [
    Authentication = [
        Key = [
            KeyLabel = "Anodot API key",
            Label = "Anodot API key"
        ]
    ],
    Label = "Anodot API connector"
];

// Data Source UI publishing description
Anodot.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = {"Anodot API connector", "Visit anodot.com for more info"}
];

//
// Implementation
//
BaseUrl = ".anodot.com/api/v2/";
apiKey = Extension.CurrentCredential()[Key];

[DataSource.Kind = "Anodot", Publish = "Anodot.Publish"]
shared Anodot.Contents = (domain as text) => AnodotNavTable("https://" & domain & BaseUrl, domain) as table;

AnodotNavTable = (url as text, domain as text) as table =>
    let
        source = #table(
            {"Name", "Data", "ItemKind", "ItemName", "IsLeaf"},
            {
                {"Measures", GetMetricsNamesTable(url), "Folder", "Folder", false},
                {"Alerts", GetAlertsTable(url), "Table", "Table", true},
                {"Anomalies", GetAnomaliesTable(url), "Table", "Table", true},
                //  { "Metrics", "n4", GetMetricsTable(url), "Table", "Metrics", true },
                {"GetAlerts", Anodot.GetAnyAlerts(url), "Function", "Function", true},
                {"GetAnomalies", Anodot.GetAnyAnomalies(url), "Function", "Function", true}
            }
        ),
        navTable = Table.ToNavigationTableRoot(source, {"Name"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in
        navTable;

GetDefaultRequestHeaders = (url as text) as record =>
    let
    refreshToken = Extension.CurrentCredential()[Key],
    authJson     = Json.Document(
                     Web.Contents(
                       url & "access-token/?responseformat=JSON",
                       [
                         Headers = [ #"Content-Type"  = "application/json" ],
                         Content = Json.FromValue([ refreshToken = refreshToken ])
                       ]
                     )
                   ),
    accessToken  = authJson[token],
        headers = [
            #"Authorization" = "Bearer " & accessToken,
            #"Content-Type" = "application/json"
        ]
    in
        headers;

GetMetricsNamesTable = (url as text) as table =>
    let
        postData = Json.FromValue([properties = {"what"}, expression = "", filter = {}, size = 500]),
        source = Web.Contents(
            url & "search/metrics/props",
            [
                Headers = GetDefaultRequestHeaders(url),
                Content = postData,
                ManualCredentials = true
            ]
        ),
        metricsNames = Json.Document(source)[propertyValues],
        entitiesAsTable = Table.FromRecords(metricsNames, type table [value = Text.Type]),
        renamed = Table.RenameColumns(entitiesAsTable, {{"value", "MetricName"}}),
        // Add Data as a calculated column
        withData = Table.AddColumn(renamed, "Data", each MeasureFunctionsTable([MetricName], url), type table),
        // Add ItemKind and ItemName as fixed text values
        withItemKind = Table.AddColumn(withData, "ItemKind", each "Folder", type text),
        withItemName = Table.AddColumn(withItemKind, "ItemName", each "Folder", type text),
        // Indicate that the node should not be expandable
        result = Table.AddColumn(withItemName, "IsLeaf", each false, type logical),
        navTable = Table.ToNavigationTable(
            result, {"MetricName"}, "MetricName", "Data", "ItemKind", "ItemName", "IsLeaf"
        )
    in
        navTable;

MeasureFunctionsTable = (measureName as text, url as text) as table =>
    let
        source = #table(
            {"Name", "Data", "ItemKind", "ItemName", "IsLeaf"},
            {
            // { "GetMetrics", Anodot.GetAnomaliesFn(measureName, url), "Function", "Function", true},
            {"GetAnomalies", Anodot.GetNamedAnomalies(measureName, url), "Function", "Function", true}}
        ),
        navTable = Table.ToNavigationTable(source, {"Name"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in
        navTable;

GetMetricsTable = (url as text) as table =>
    let
        postData = Json.FromValue([
            composite = []
        ]),
        // TODO: add correct payload
        source = Web.Contents(
            url & "metrics/composite/execute",
            [
                Headers = GetDefaultRequestHeaders(url),
                Query = [fromDate = "1649629416", toDate = "1650129416"],
                Content = postData,
                ManualCredentials = true
            ]
        ),
        metrics = Json.Document(source)[metrics],
        metricsTable = Table.FromRecords(metrics)
    in
        metricsTable;

GetAlertsTable = (url as text, optional query) as table =>
    let
        source = Web.Contents(
            url & "alerts/triggered", [Headers = GetDefaultRequestHeaders(url), Query = query, ManualCredentials = true]
        ),
        alerts = Json.Document(source)[alertGroups],
        alertsTable = Table.FromRecords(alerts)
    in
        alertsTable;

shared Anodot.GetAnyAlerts = (url) => (optional queryParams as record) => GetAlertsTable(url, queryParams);

GetAnomaliesTable = (url as text, optional query) as table =>
    let
        source = Web.Contents(
            url & "anomalies", [Headers = GetDefaultRequestHeaders(url), Query = query, ManualCredentials = true]
        ),
        json = Json.Document(source)[anomalies],
        anomaliesTable = Table.FromRecords(json)
    in
        anomaliesTable;

shared Anodot.GetAnyAnomalies = (url) =>
    (measureName as text, optional queryParams as record) => GetAno(measureName, url, queryParams);
shared Anodot.GetNamedAnomalies = (measureName as text, url as text) =>
    (optional queryParams as record) => GetAno(measureName, url, queryParams);

GetAno = (measureName as text, url as text, optional queryParams as record) =>
    let
        qParams = if queryParams = null then [] else queryParams,
        query = Record.Combine({[q = MakeExpression(measureName)], qParams}),
        res = GetAnomaliesTable(url, query)
    in
        res;

Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta [
            NavigationTable.NameColumn = nameColumn,
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn,
            // Preview.DelayColumn = itemNameColumn,
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;

Table.ToNavigationTableRoot = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta [
            NavigationTable.NameColumn = nameColumn,
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn,
            Preview.DelayColumn = itemNameColumn,
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;

MakeExpression = (measureName as text) =>
    let
        //generate string "{ "expression": [ {type:"property", "key":"what","value":"API-RPM","isExact":true}]}
        prop = [ype = "property", key = "what", value = measureName, isExact = true],
        expression = [expression = {prop}],
        txt = Text.FromBinary(Json.FromValue(expression)),
        res = Text.Insert(txt, 17, "t")
        // As we can't setreserved "type" property
    in
        res;

Anodot.Icons = [
    Icon16 = {
        Extension.Contents("Anodot16.png"),
        Extension.Contents("Anodot20.png"),
        Extension.Contents("Anodot24.png"),
        Extension.Contents("Anodot32.png")
    },
    Icon32 = {
        Extension.Contents("Anodot32.png"),
        Extension.Contents("Anodot40.png"),
        Extension.Contents("Anodot48.png"),
        Extension.Contents("Anodot64.png")
    }
];
