# anodot-powerbi

https://docs.microsoft.com/en-us/power-query/installingsdk

This repo contains the code needed to create a Power Query and Power BI custom connector for Anodot API, as well as the instructions to build and enable it. 

## setting up based on existing conenctor

1. Create the folder _Documents/Power BI Desktop/Custom Connectors_ and put the _.mez_ (unsigned version) or _.pqx_ (signed version)  file of the data connector in that folder (Works for Windows Only)
 
2. In PowerBI Desktop seettings, change the security settings as below and restart PowerBI ([More details](https://docs.microsoft.com/en-us/power-bi/connect-data/desktop-connector-extensibility) for these steps)

![security](https://github.com/anodot/anodot-powerbi/blob/main/images/power-bi-image-1.png)

3. Press 'Get Data' and search for the Anodot Connector

![get data](https://github.com/anodot/anodot-powerbi/blob/main/images/power-bi-image-2.png)

4. Set the anodot domain you are using, e.g. _app_ (For more details on which URL you should use, see [here](https://support.anodot.com/hc/en-us/articles/360010385120-Login-and-API-URLs)) 

![domain](https://github.com/anodot/anodot-powerbi/blob/main/images/power-bi-image-3.png)

5. Insert the Anodot API token (For more details on getting a token, see [here](https://support.anodot.com/hc/en-us/articles/360002631114-Token-Management-))

![token](https://github.com/anodot/anodot-powerbi/blob/main/images/power-bi-image-4.png)

6. You can see the navigation table. Anomalies and Alerts are just the common lists without any filters.
   You can use GetAlerts or GetAnomalies functions which accept the measure name and additional query parameters to get more specified list of records. Use "Transform Data" to be able to edit the query.
   
Example for Alerts query:
   ```
    [ order = "desc", sort = "updatedTime", size = "100", index = "0", startTime = "1650288623", "constRange" = "d1", startBucketMode = "true", starredBy = "5f22d003c394f4000e32eb7a" ]
   ```
Example for Anomalies query:
   ```
    [ anomalyType = "transient", bookmark = "5f22d003c394f4000e32eb7a", delta = "0", deltaType = "absolute", durationUnit = "minutes", durationValue = "5", endDate = "1650410817", index = "0", order = "desc", resolution = "medium", score = "0.72", size = "10", sort = "delta", startBucketMode = "true", startDate = "1649806017", state = "both", valueDirection = "both" ]
   ```

![filter](https://github.com/anodot/anodot-powerbi/blob/main/images/power-bi-image-5.png)

7. There is a folder of existing measures. You can use nested functions bind to this measureNames with the queryParameters you need.

![filter](https://github.com/anodot/anodot-powerbi/blob/main/images/power-bi-image-6.png)

