resource "azurerm_resource_group" "SC0" {
  location = "australiasoutheast"
  name     = "sitecounter"
}
resource "azurerm_cosmosdb_account" "SC1" {
  location            = "australiasoutheast"
  name                = "countertable"
  offer_type          = "Standard"
  resource_group_name = "sitecounter"
  tags = {
    defaultExperience       = "Azure Table"
    hidden-cosmos-mmspecial = ""
  }
  consistency_policy {
    consistency_level = "BoundedStaleness"
  }
  geo_location {
    failover_priority = 0
    location          = "australiasoutheast"
  }
  depends_on = [
    azurerm_resource_group.SC0,
  ]
}
resource "azurerm_cosmosdb_table" "SC2" {
  account_name        = "countertable"
  name                = "visitcount"
  resource_group_name = "sitecounter"
  depends_on = [
    azurerm_cosmosdb_account.SC1,
  ]
}
resource "azurerm_logic_app_workflow" "SC3" {
  location = "australiasoutheast"
  name     = "slackconnector"
  parameters = {
    "$connections" = "{\"slack_1\":{\"connectionId\":\"/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.Web/connections/slack\",\"connectionName\":\"slack\",\"id\":\"/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/providers/Microsoft.Web/locations/australiasoutheast/managedApis/slack\"}}"
  }
  resource_group_name = "sitecounter"
  workflow_parameters = {
    "$connections" = "{\"defaultValue\":{},\"type\":\"Object\"}"
  }
  depends_on = [
    azurerm_resource_group.SC0,
  ]
}
resource "azurerm_log_analytics_workspace" "SC4" {
  location            = "australiasoutheast"
  name                = "workspace-sitecounter"
  resource_group_name = "sitecounter"
  depends_on = [
    azurerm_resource_group.SC0,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC5" {
  category                   = "General Exploration"
  display_name               = "All Computers with their most recent data"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_General|AlphabeticallySortedComputers"
  query                      = "search not(ObjectName == \"Advisor Metrics\" or ObjectName == \"ManagedSpace\") | summarize AggregatedValue = max(TimeGenerated) by Computer | limit 500000 | sort by Computer asc\r\n// Oql: NOT(ObjectName=\"Advisor Metrics\" OR ObjectName=ManagedSpace) | measure max(TimeGenerated) by Computer | top 500000 | Sort Computer // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PTT: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC6" {
  category                   = "General Exploration"
  display_name               = "Stale Computers (data older than 24 hours)"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_General|StaleComputers"
  query                      = "search not(ObjectName == \"Advisor Metrics\" or ObjectName == \"ManagedSpace\") | summarize lastdata = max(TimeGenerated) by Computer | limit 500000 | where lastdata < ago(24h)\r\n// Oql: NOT(ObjectName=\"Advisor Metrics\" OR ObjectName=ManagedSpace) | measure max(TimeGenerated) as lastdata by Computer | top 500000 | where lastdata < NOW-24HOURS // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PTT: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC7" {
  category                   = "General Exploration"
  display_name               = "Which Management Group is generating the most data points?"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_General|dataPointsPerManagementGroup"
  query                      = "search * | summarize AggregatedValue = count() by ManagementGroupName\r\n// Oql: * | Measure count() by ManagementGroupName // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PTT: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC8" {
  category                   = "General Exploration"
  display_name               = "Distribution of data Types"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_General|dataTypeDistribution"
  query                      = "search * | extend Type = $table | summarize AggregatedValue = count() by Type\r\n// Oql: * | Measure count() by Type // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PTT: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC9" {
  category                   = "Log Management"
  display_name               = "All Events"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|AllEvents"
  query                      = "Event | sort by TimeGenerated desc\r\n// Oql: Type=Event // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PTT: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC10" {
  category                   = "Log Management"
  display_name               = "All Syslogs"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|AllSyslog"
  query                      = "Syslog | sort by TimeGenerated desc\r\n// Oql: Type=Syslog // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PTT: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC11" {
  category                   = "Log Management"
  display_name               = "All Syslog Records grouped by Facility"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|AllSyslogByFacility"
  query                      = "Syslog | summarize AggregatedValue = count() by Facility\r\n// Oql: Type=Syslog | Measure count() by Facility // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PTT: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC12" {
  category                   = "Log Management"
  display_name               = "All Syslog Records grouped by ProcessName"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|AllSyslogByProcessName"
  query                      = "Syslog | summarize AggregatedValue = count() by ProcessName\r\n// Oql: Type=Syslog | Measure count() by ProcessName // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PTT: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC13" {
  category                   = "Log Management"
  display_name               = "All Syslog Records with Errors"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|AllSyslogsWithErrors"
  query                      = "Syslog | where SeverityLevel == \"error\" | sort by TimeGenerated desc\r\n// Oql: Type=Syslog SeverityLevel=error // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PTT: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC14" {
  category                   = "Log Management"
  display_name               = "Average HTTP Request time by Client IP Address"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|AverageHTTPRequestTimeByClientIPAddress"
  query                      = "search * | extend Type = $table | where Type == W3CIISLog | summarize AggregatedValue = avg(TimeTaken) by cIP\r\n// Oql: Type=W3CIISLog | Measure Avg(TimeTaken) by cIP // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PEF: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC15" {
  category                   = "Log Management"
  display_name               = "Average HTTP Request time by HTTP Method"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|AverageHTTPRequestTimeHTTPMethod"
  query                      = "search * | extend Type = $table | where Type == W3CIISLog | summarize AggregatedValue = avg(TimeTaken) by csMethod\r\n// Oql: Type=W3CIISLog | Measure Avg(TimeTaken) by csMethod // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PEF: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC16" {
  category                   = "Log Management"
  display_name               = "Count of IIS Log Entries by Client IP Address"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|CountIISLogEntriesClientIPAddress"
  query                      = "search * | extend Type = $table | where Type == W3CIISLog | summarize AggregatedValue = count() by cIP\r\n// Oql: Type=W3CIISLog | Measure count() by cIP // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PEF: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC17" {
  category                   = "Log Management"
  display_name               = "Count of IIS Log Entries by HTTP Request Method"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|CountIISLogEntriesHTTPRequestMethod"
  query                      = "search * | extend Type = $table | where Type == W3CIISLog | summarize AggregatedValue = count() by csMethod\r\n// Oql: Type=W3CIISLog | Measure count() by csMethod // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PEF: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC18" {
  category                   = "Log Management"
  display_name               = "Count of IIS Log Entries by HTTP User Agent"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|CountIISLogEntriesHTTPUserAgent"
  query                      = "search * | extend Type = $table | where Type == W3CIISLog | summarize AggregatedValue = count() by csUserAgent\r\n// Oql: Type=W3CIISLog | Measure count() by csUserAgent // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PEF: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC19" {
  category                   = "Log Management"
  display_name               = "Count of IIS Log Entries by Host requested by client"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|CountOfIISLogEntriesByHostRequestedByClient"
  query                      = "search * | extend Type = $table | where Type == W3CIISLog | summarize AggregatedValue = count() by csHost\r\n// Oql: Type=W3CIISLog | Measure count() by csHost // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PEF: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC20" {
  category                   = "Log Management"
  display_name               = "Count of IIS Log Entries by URL for the host \"www.contoso.com\" (replace with your own)"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|CountOfIISLogEntriesByURLForHost"
  query                      = "search csHost == \"www.contoso.com\" | extend Type = $table | where Type == W3CIISLog | summarize AggregatedValue = count() by csUriStem\r\n// Oql: Type=W3CIISLog csHost=\"www.contoso.com\" | Measure count() by csUriStem // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PEF: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC21" {
  category                   = "Log Management"
  display_name               = "Count of IIS Log Entries by URL requested by client (without query strings)"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|CountOfIISLogEntriesByURLRequestedByClient"
  query                      = "search * | extend Type = $table | where Type == W3CIISLog | summarize AggregatedValue = count() by csUriStem\r\n// Oql: Type=W3CIISLog | Measure count() by csUriStem // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PEF: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC22" {
  category                   = "Log Management"
  display_name               = "Count of Events with level \"Warning\" grouped by Event ID"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|CountOfWarningEvents"
  query                      = "Event | where EventLevelName == \"warning\" | summarize AggregatedValue = count() by EventID\r\n// Oql: Type=Event EventLevelName=warning | Measure count() by EventID // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PTT: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC23" {
  category                   = "Log Management"
  display_name               = "Shows breakdown of response codes"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|DisplayBreakdownRespondCodes"
  query                      = "search * | extend Type = $table | where Type == W3CIISLog | summarize AggregatedValue = count() by scStatus\r\n// Oql: Type=W3CIISLog | Measure count() by scStatus // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PEF: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC24" {
  category                   = "Log Management"
  display_name               = "Count of Events grouped by Event Log"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|EventsByEventLog"
  query                      = "Event | summarize AggregatedValue = count() by EventLog\r\n// Oql: Type=Event | Measure count() by EventLog // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PTT: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC25" {
  category                   = "Log Management"
  display_name               = "Count of Events grouped by Event Source"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|EventsByEventSource"
  query                      = "Event | summarize AggregatedValue = count() by Source\r\n// Oql: Type=Event | Measure count() by Source // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PTT: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC26" {
  category                   = "Log Management"
  display_name               = "Count of Events grouped by Event ID"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|EventsByEventsID"
  query                      = "Event | summarize AggregatedValue = count() by EventID\r\n// Oql: Type=Event | Measure count() by EventID // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PTT: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC27" {
  category                   = "Log Management"
  display_name               = "Events in the Operations Manager Event Log whose Event ID is in the range between 2000 and 3000"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|EventsInOMBetween2000to3000"
  query                      = "Event | where EventLog == \"Operations Manager\" and EventID >= 2000 and EventID <= 3000 | sort by TimeGenerated desc\r\n// Oql: Type=Event EventLog=\"Operations Manager\" EventID:[2000..3000] // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PTT: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC28" {
  category                   = "Log Management"
  display_name               = "Count of Events containing the word \"started\" grouped by EventID"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|EventsWithStartedinEventID"
  query                      = "search in (Event) \"started\" | summarize AggregatedValue = count() by EventID\r\n// Oql: Type=Event \"started\" | Measure count() by EventID // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PTT: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC29" {
  category                   = "Log Management"
  display_name               = "Find the maximum time taken for each page"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|FindMaximumTimeTakenForEachPage"
  query                      = "search * | extend Type = $table | where Type == W3CIISLog | summarize AggregatedValue = max(TimeTaken) by csUriStem\r\n// Oql: Type=W3CIISLog | Measure Max(TimeTaken) by csUriStem // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PEF: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC30" {
  category                   = "Log Management"
  display_name               = "IIS Log Entries for a specific client IP Address (replace with your own)"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|IISLogEntriesForClientIP"
  query                      = "search cIP == \"192.168.0.1\" | extend Type = $table | where Type == W3CIISLog | sort by TimeGenerated desc | project csUriStem, scBytes, csBytes, TimeTaken, scStatus\r\n// Oql: Type=W3CIISLog cIP=\"192.168.0.1\" | Select csUriStem,scBytes,csBytes,TimeTaken,scStatus // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PEF: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC31" {
  category                   = "Log Management"
  display_name               = "All IIS Log Entries"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|ListAllIISLogEntries"
  query                      = "search * | extend Type = $table | where Type == W3CIISLog | sort by TimeGenerated desc\r\n// Oql: Type=W3CIISLog // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PEF: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC32" {
  category                   = "Log Management"
  display_name               = "How many connections to Operations Manager's SDK service by day"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|NoOfConnectionsToOMSDKService"
  query                      = "Event | where EventID == 26328 and EventLog == \"Operations Manager\" | summarize AggregatedValue = count() by bin(TimeGenerated, 1d) | sort by TimeGenerated desc\r\n// Oql: Type=Event EventID=26328 EventLog=\"Operations Manager\" | Measure count() interval 1DAY // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PTT: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC33" {
  category                   = "Log Management"
  display_name               = "When did my servers initiate restart?"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|ServerRestartTime"
  query                      = "search in (Event) \"shutdown\" and EventLog == \"System\" and Source == \"User32\" and EventID == 1074 | sort by TimeGenerated desc | project TimeGenerated, Computer\r\n// Oql: shutdown Type=Event EventLog=System Source=User32 EventID=1074 | Select TimeGenerated,Computer // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PTT: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC34" {
  category                   = "Log Management"
  display_name               = "Shows which pages people are getting a 404 for"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|Show404PagesList"
  query                      = "search scStatus == 404 | extend Type = $table | where Type == W3CIISLog | summarize AggregatedValue = count() by csUriStem\r\n// Oql: Type=W3CIISLog scStatus=404 | Measure count() by csUriStem // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PEF: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC35" {
  category                   = "Log Management"
  display_name               = "Shows servers that are throwing internal server error"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|ShowServersThrowingInternalServerError"
  query                      = "search scStatus == 500 | extend Type = $table | where Type == W3CIISLog | summarize AggregatedValue = count() by sComputerName\r\n// Oql: Type=W3CIISLog scStatus=500 | Measure count() by sComputerName // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PEF: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC36" {
  category                   = "Log Management"
  display_name               = "Total Bytes received by each Azure Role Instance"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|TotalBytesReceivedByEachAzureRoleInstance"
  query                      = "search * | extend Type = $table | where Type == W3CIISLog | summarize AggregatedValue = sum(csBytes) by RoleInstance\r\n// Oql: Type=W3CIISLog | Measure Sum(csBytes) by RoleInstance // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PEF: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC37" {
  category                   = "Log Management"
  display_name               = "Total Bytes received by each IIS Computer"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|TotalBytesReceivedByEachIISComputer"
  query                      = "search * | extend Type = $table | where Type == W3CIISLog | summarize AggregatedValue = sum(csBytes) by Computer | limit 500000\r\n// Oql: Type=W3CIISLog | Measure Sum(csBytes) by Computer | top 500000 // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PEF: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC38" {
  category                   = "Log Management"
  display_name               = "Total Bytes responded back to clients by Client IP Address"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|TotalBytesRespondedToClientsByClientIPAddress"
  query                      = "search * | extend Type = $table | where Type == W3CIISLog | summarize AggregatedValue = sum(scBytes) by cIP\r\n// Oql: Type=W3CIISLog | Measure Sum(scBytes) by cIP // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PEF: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC39" {
  category                   = "Log Management"
  display_name               = "Total Bytes responded back to clients by each IIS ServerIP Address"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|TotalBytesRespondedToClientsByEachIISServerIPAddress"
  query                      = "search * | extend Type = $table | where Type == W3CIISLog | summarize AggregatedValue = sum(scBytes) by sIP\r\n// Oql: Type=W3CIISLog | Measure Sum(scBytes) by sIP // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PEF: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC40" {
  category                   = "Log Management"
  display_name               = "Total Bytes sent by Client IP Address"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|TotalBytesSentByClientIPAddress"
  query                      = "search * | extend Type = $table | where Type == W3CIISLog | summarize AggregatedValue = sum(csBytes) by cIP\r\n// Oql: Type=W3CIISLog | Measure Sum(csBytes) by cIP // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PEF: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC41" {
  category                   = "Log Management"
  display_name               = "All Events with level \"Warning\""
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|WarningEvents"
  query                      = "Event | where EventLevelName == \"warning\" | sort by TimeGenerated desc\r\n// Oql: Type=Event EventLevelName=warning // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PTT: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC42" {
  category                   = "Log Management"
  display_name               = "Windows Firewall Policy settings have changed"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|WindowsFireawallPolicySettingsChanged"
  query                      = "Event | where EventLog == \"Microsoft-Windows-Windows Firewall With Advanced Security/Firewall\" and EventID == 2008 | sort by TimeGenerated desc\r\n// Oql: Type=Event EventLog=\"Microsoft-Windows-Windows Firewall With Advanced Security/Firewall\" EventID=2008 // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PTT: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_log_analytics_saved_search" "SC43" {
  category                   = "Log Management"
  display_name               = "On which machines and how many times have Windows Firewall Policy settings changed"
  log_analytics_workspace_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  name                       = "LogManagement(workspace-sitecounter)_LogManagement|WindowsFireawallPolicySettingsChangedByMachines"
  query                      = "Event | where EventLog == \"Microsoft-Windows-Windows Firewall With Advanced Security/Firewall\" and EventID == 2008 | summarize AggregatedValue = count() by Computer | limit 500000\r\n// Oql: Type=Event EventLog=\"Microsoft-Windows-Windows Firewall With Advanced Security/Firewall\" EventID=2008 | measure count() by Computer | top 500000 // Args: {OQ: True; WorkspaceId: 00000000-0000-0000-0000-000000000000} // Settings: {PTT: True; SortI: True; SortF: True} // Version: 0.1.122"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_storage_account" "SC508" {
  account_kind             = "Storage"
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = "australiasoutheast"
  min_tls_version          = "TLS1_0"
  name                     = "sitecounter13405f"
  resource_group_name      = "sitecounter"
  depends_on = [
    azurerm_resource_group.SC0,
  ]
}
resource "azurerm_storage_container" "SC510" {
  name                 = "azure-webjobs-hosts"
  storage_account_name = "sitecounter13405f"
}
resource "azurerm_storage_container" "SC511" {
  name                 = "azure-webjobs-secrets"
  storage_account_name = "sitecounter13405f"
}
resource "azurerm_storage_container" "SC512" {
  name                 = "scm-releases"
  storage_account_name = "sitecounter13405f"
}
resource "azurerm_storage_share" "SC514" {
  name                 = "sitecounterbca0"
  quota                = 5120
  storage_account_name = "sitecounter13405f"
}
resource "azurerm_storage_share" "SC515" {
  name                 = "sitecounterde0cbe"
  quota                = 5120
  storage_account_name = "sitecounter13405f"
}
resource "azurerm_storage_table" "SC518" {
  name                 = "mctable"
  storage_account_name = "sitecounter13405f"
}
resource "azurerm_storage_account" "SC519" {
  account_kind                    = "Storage"
  account_replication_type        = "LRS"
  account_tier                    = "Standard"
  default_to_oauth_authentication = true
  location                        = "australiasoutheast"
  name                            = "sitecounterbc97"
  resource_group_name             = "sitecounter"
  depends_on = [
    azurerm_resource_group.SC0,
  ]
}
resource "azurerm_storage_container" "SC521" {
  name                 = "azure-webjobs-hosts"
  storage_account_name = "sitecounterbc97"
}
resource "azurerm_storage_container" "SC522" {
  name                 = "azure-webjobs-secrets"
  storage_account_name = "sitecounterbc97"
}
resource "azurerm_storage_container" "SC523" {
  name                 = "scm-releases"
  storage_account_name = "sitecounterbc97"
}
resource "azurerm_storage_share" "SC525" {
  name                 = "datwebcounter8332"
  quota                = 5120
  storage_account_name = "sitecounterbc97"
}
resource "azurerm_api_connection" "SC528" {
  managed_api_id      = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/providers/Microsoft.Web/locations/australiasoutheast/managedApis/slack"
  name                = "slack"
  resource_group_name = "sitecounter"
  depends_on = [
    azurerm_resource_group.SC0,
  ]
}
resource "azurerm_service_plan" "SC529" {
  location            = "australiasoutheast"
  name                = "ASP-sitecounter-b15d"
  os_type             = "Linux"
  resource_group_name = "sitecounter"
  sku_name            = "Y1"
  depends_on = [
    azurerm_resource_group.SC0,
  ]
}
resource "azurerm_linux_function_app" "SC530" {
  app_settings = {
    MyStorageConnectionAppSetting = "DefaultEndpointsProtocol=https;AccountName=countertable;AccountKey=yAdNunpDc8cdjbf8tOP4QluUemhLMWbgUtOlULRUW5ZS69WFUL6wV4dMX5gEllTc9xiL6lSf0vKxACDbQ3sFqA==;TableEndpoint=https://countertable.table.cosmos.azure.com:443/;"
  }
  builtin_logging_enabled    = false
  client_certificate_mode    = "Required"
  https_only                 = true
  location                   = "australiasoutheast"
  name                       = "datwebcounter"
  resource_group_name        = "sitecounter"
  service_plan_id            = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.Web/serverfarms/ASP-sitecounter-b15d"
  storage_account_access_key = "wClr8L6HoqxlTmJT8pR0lZZztad/FzNPzotbKKlFJ09uEiHHtPgarSyq/3S2Hvv6HAM4MBXuB9qq+ASt/ksG4Q=="
  storage_account_name       = "sitecounterbc97"
  tags = {
    "hidden-link: /app-insights-conn-string"         = "InstrumentationKey=3f880410-7199-408a-a1c0-4173c995ba83;IngestionEndpoint=https://australiasoutheast-0.in.applicationinsights.azure.com/;LiveEndpoint=https://australiasoutheast.livediagnostics.monitor.azure.com/"
    "hidden-link: /app-insights-instrumentation-key" = "3f880410-7199-408a-a1c0-4173c995ba83"
    "hidden-link: /app-insights-resource-id"         = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/microsoft.insights/components/datwebcounter"
  }
  site_config {
    application_insights_connection_string = "InstrumentationKey=3f880410-7199-408a-a1c0-4173c995ba83;IngestionEndpoint=https://australiasoutheast-0.in.applicationinsights.azure.com/;LiveEndpoint=https://australiasoutheast.livediagnostics.monitor.azure.com/"
    application_insights_key               = "3f880410-7199-408a-a1c0-4173c995ba83"
    ftps_state                             = "FtpsOnly"
    application_stack {
      python_version = "3.10"
    }
    cors {
      allowed_origins = ["*"]
    }
  }
  depends_on = [
    azurerm_service_plan.SC529,
  ]
}
resource "azurerm_function_app_function" "SC534" {
  config_json     = "{\"bindings\":[{\"authLevel\":\"anonymous\",\"direction\":\"in\",\"methods\":[\"get\",\"post\"],\"name\":\"req\",\"type\":\"httpTrigger\"},{\"direction\":\"out\",\"name\":\"$return\",\"type\":\"http\"},{\"connection\":\"MyStorageConnectionAppSetting\",\"direction\":\"out\",\"name\":\"out\",\"tableName\":\"visitcount\",\"type\":\"table\"},{\"connection\":\"MyStorageConnectionAppSetting\",\"direction\":\"in\",\"name\":\"messageJSON\",\"partitionKey\":\"count\",\"tableName\":\"visitcount\",\"type\":\"table\"}]}"
  function_app_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.Web/sites/datwebcounter"
  name            = "HttpTrigger2"
  depends_on = [
    azurerm_linux_function_app.SC530,
  ]
}
resource "azurerm_app_service_custom_hostname_binding" "SC535" {
  app_service_name    = "datwebcounter"
  hostname            = "datwebcounter.azurewebsites.net"
  resource_group_name = "sitecounter"
  depends_on = [
    azurerm_linux_function_app.SC530,
  ]
}
resource "azurerm_monitor_action_group" "SC536" {
  name                = "alertGroup"
  resource_group_name = "sitecounter"
  short_name          = "alertGroup"
  email_receiver {
    email_address = "rei_it10@hotmail.com"
    name          = "emailMe_-EmailAction-"
  }
  webhook_receiver {
    name                    = "zenduty"
    service_uri             = "https://www.zenduty.com/api/integration/microsoftazure/64d80823-20f2-4372-95b8-d346d429abf3/"
    use_common_alert_schema = true
  }
  webhook_receiver {
    name                    = "slack"
    service_uri             = "https://prod-26.australiasoutheast.logic.azure.com:443/workflows/75477ecbc4a54c069f02375234acdc48/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=dH6lG204e7G0VE11yLDpOUmN-OMIVXXsNAriiFfUsFo"
    use_common_alert_schema = true
  }
  depends_on = [
    azurerm_resource_group.SC0,
  ]
}
resource "azurerm_application_insights" "SC537" {
  application_type    = "web"
  location            = "australiasoutheast"
  name                = "datwebcounter"
  resource_group_name = "sitecounter"
  sampling_percentage = 0
  workspace_id        = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/Microsoft.OperationalInsights/workspaces/workspace-sitecounter"
  depends_on = [
    azurerm_log_analytics_workspace.SC4,
  ]
}
resource "azurerm_monitor_metric_alert" "SC538" {
  name                = "requestRate"
  resource_group_name = "sitecounter"
  scopes              = ["/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/microsoft.insights/components/datwebcounter"]
  severity            = 1
  action {
    action_group_id = "/subscriptions/0230500B-262A-496C-B8AD-4EB1CB68DEDE/resourceGroups/sitecounter/providers/microsoft.insights/actionGroups/alertGroup"
  }
  criteria {
    aggregation      = "Average"
    metric_name      = "requests/rate"
    metric_namespace = "microsoft.insights/components"
    operator         = "GreaterThan"
    threshold        = 1
  }
  depends_on = [
    azurerm_resource_group.SC0,
  ]
}
resource "azurerm_monitor_metric_alert" "SC539" {
  name                = "responseTime"
  resource_group_name = "sitecounter"
  scopes              = ["/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/microsoft.insights/components/datwebcounter"]
  action {
    action_group_id = "/subscriptions/0230500B-262A-496C-B8AD-4EB1CB68DEDE/resourceGroups/sitecounter/providers/microsoft.insights/actionGroups/alertGroup"
  }
  criteria {
    aggregation      = "Average"
    metric_name      = "requests/duration"
    metric_namespace = "microsoft.insights/components"
    operator         = "GreaterThan"
    threshold        = 10
  }
  depends_on = [
    azurerm_resource_group.SC0,
  ]
}
resource "azurerm_monitor_metric_alert" "SC540" {
  name                = "returnError"
  resource_group_name = "sitecounter"
  scopes              = ["/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourceGroups/sitecounter/providers/microsoft.insights/components/datwebcounter"]
  severity            = 1
  action {
    action_group_id = "/subscriptions/0230500b-262a-496c-b8ad-4eb1cb68dede/resourcegroups/sitecounter/providers/microsoft.insights/actiongroups/alertgroup"
  }
  criteria {
    aggregation      = "Count"
    metric_name      = "requests/failed"
    metric_namespace = "microsoft.insights/components"
    operator         = "GreaterThan"
    threshold        = 0
  }
  depends_on = [
    azurerm_resource_group.SC0,
  ]
}
