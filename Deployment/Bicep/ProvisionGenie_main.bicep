param workflows_ProvisionGenie_Main_name string
param workflows_ProvisionGenie_Welcome_name string
param workflows_ProvisionGenie_CreateTaskList_name string
param workflows_ProvisionGenie_CreateLibrary_name string
param workflows_ProvisionGenie_CreateList_name string
param workflows_ProvisionGenie_CreateTeam_name string
param userAssignedIdentities_ProvisionGenie_ManagedIdentity_name string
param connections_commondataservice_name string
param resourceLocation string

@secure()
param subscriptionId string
param resourceGroupName string

@secure()
param ManagedIdentity_ObjectId string

@secure()
param ManagedIdentity_ClientId string
param DataverseEnvironmentId string

resource workflows_ProvisionGenie_Main_name_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  name: workflows_ProvisionGenie_Main_name
  location: resourceLocation
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '/subscriptions/${subscriptionId}/resourcegroups/${resourceGroupName}/providers/microsoft.managedidentity/userassignedidentities/${userAssignedIdentities_ProvisionGenie_ManagedIdentity_name}': {
        principalId: ManagedIdentity_ObjectId
        clientId: ManagedIdentity_ClientId
      }
    }
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
        DataverseEnvironmentId: {
          defaultValue: DataverseEnvironmentId
          type: 'String'
        }
      }
      triggers: {
        When_a_record_is_created: {
          type: 'ApiConnectionWebhook'
          inputs: {
            body: {
              NotificationUrl: '@{listCallbackUrl()}'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'commondataservice\'][\'connectionId\']'
              }
            }
            path: '/datasets/@{encodeURIComponent(encodeURIComponent(parameters(\'DataverseEnvironmentId\')))}/tables/@{encodeURIComponent(encodeURIComponent(\'cy_teamsrequests\'))}/onnewitemswebhook'
            queries: {
              scope: 'Organization'
            }
          }
        }
      }
      actions: {
        Buckets: {
          runAfter: {
            ListColumns: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'Buckets'
                type: 'array'
              }
            ]
          }
        }
        Channels: {
          runAfter: {
            Complete_Technical_Name_in_Teams_request: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'Channels'
                type: 'array'
              }
            ]
          }
        }
        Complete_Technical_Name_in_Teams_request: {
          runAfter: {
            Generate_Team_internal_name: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            body: {
              '_ownerid_type': ''
              cy_teamtechnicalname: '@{outputs(\'Generate_Team_internal_name\')}'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'commondataservice\'][\'connectionId\']'
              }
            }
            method: 'patch'
            path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(parameters(\'DataverseEnvironmentId\')))}/tables/@{encodeURIComponent(encodeURIComponent(\'cy_teamsrequests\'))}/items/@{encodeURIComponent(encodeURIComponent(triggerBody()?[\'cy_teamsrequestid\']))}'
          }
        }
        Condition_Include_welcome_package: {
          actions: {
            'ProvisionGenie-Welcome': {
              runAfter: {}
              type: 'Workflow'
              inputs: {
                body: {
                  Owner: '@triggerBody()?[\'cy_teamowner\']'
                  TeamId: '@body(\'Parse_HTTP_body_for_Team_Id\')?[\'TeamId\']'
                }
                host: {
                  triggerName: 'manual'
                  workflow: {
                    id: resourceId('Microsoft.Logic/workflows', workflows_ProvisionGenie_Welcome_name)
                  }
                }
              }
            }
          }
          runAfter: {
            Condition_include_task_list: [
              'Succeeded'
            ]
          }
          expression: {
            and: [
              {
                equals: [
                  '@triggerBody()?[\'cy_includewelcomepackage\']'
                  '@true'
                ]
              }
            ]
          }
          type: 'If'
        }
        Condition_include_task_list: {
          actions: {
            'ProvisionGenie-CreateTaskList': {
              runAfter: {}
              type: 'Workflow'
              inputs: {
                body: {
                  siteId: '@{outputs(\'Compose_id\')}'
                }
                host: {
                  triggerName: 'manual'
                  workflow: {
                    id: resourceId('Microsoft.Logic/workflows', workflows_ProvisionGenie_CreateTaskList_name)
                  }
                }
              }
            }
          }
          runAfter: {
            Scope_Create_Lists_and_Libraries: [
              'Succeeded'
            ]
          }
          expression: {
            and: [
              {
                equals: [
                  '@triggerBody()?[\'cy_includetasklist\']'
                  '@true'
                ]
              }
            ]
          }
          type: 'If'
        }
        DriveExistsCode: {
          runAfter: {
            Channels: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'DriveExistsCode'
                type: 'integer'
              }
            ]
          }
        }
        Generate_Team_internal_name: {
          runAfter: {}
          type: 'Compose'
          inputs: '@{replace(triggerBody()?[\'cy_teamname\'],\' \',\'\')}_@{guid()}'
        }
        LibraryColumns: {
          runAfter: {
            SiteExistsCode: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'LibraryColumns'
                type: 'array'
              }
            ]
          }
        }
        ListColumns: {
          runAfter: {
            LibraryColumns: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'ListColumns'
                type: 'array'
              }
            ]
          }
        }
        Scope_Create_Lists_and_Libraries: {
          actions: {
            For_each_SharePoint_Library_record: {
              foreach: '@body(\'List_related_SharePoint_Library_records\')?[\'value\']'
              actions: {
                For_each_Library_Column_record: {
                  foreach: '@body(\'List_related_Library_Column_records\')?[\'value\']'
                  actions: {
                    Append_column_definition_to_LibraryColumns: {
                      runAfter: {}
                      type: 'AppendToArrayVariable'
                      inputs: {
                        name: 'LibraryColumns'
                        value: {
                          columnName: '@{items(\'For_each_Library_Column_record\')?[\'cy_columnname\']}'
                          columnType: '@{items(\'For_each_Library_Column_record\')?[\'_cy_columntype_label\']}'
                          columnvalues: '@if(equals(items(\'For_each_Library_Column_record\')?[\'_cy_columntype_label\'],\'Choice\'),array(split(items(\'For_each_Library_Column_record\')?[\'cy_columnvalues\'],\',\')),null)'
                        }
                      }
                    }
                  }
                  runAfter: {
                    List_related_Library_Column_records: [
                      'Succeeded'
                    ]
                  }
                  type: 'Foreach'
                  description: 'Append column information to LibraryColumns variable'
                }
                List_related_Library_Column_records: {
                  runAfter: {}
                  type: 'ApiConnection'
                  inputs: {
                    host: {
                      connection: {
                        name: '@parameters(\'$connections\')[\'commondataservice\'][\'connectionId\']'
                      }
                    }
                    method: 'get'
                    path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(parameters(\'DataverseEnvironmentId\')))}/tables/@{encodeURIComponent(encodeURIComponent(\'cy_listcolumns\'))}/items'
                    queries: {
                      '$filter': '_cy_sharepointlibrary_value eq \'@{items(\'For_each_SharePoint_Library_record\')?[\'cy_sharepointlibraryid\']}\''
                    }
                  }
                  description: 'Get the columns related to this library record'
                }
                'ProvisionGenie-CreateLibrary': {
                  runAfter: {
                    For_each_Library_Column_record: [
                      'Succeeded'
                    ]
                  }
                  type: 'Workflow'
                  inputs: {
                    body: {
                      libraryColumns: '@variables(\'LibraryColumns\')'
                      libraryName: '@items(\'For_each_SharePoint_Library_record\')?[\'cy_libraryname\']'
                      siteId: '@{outputs(\'Compose_id\')}'
                    }
                    host: {
                      triggerName: 'manual'
                      workflow: {
                        id: resourceId('Microsoft.Logic/workflows', workflows_ProvisionGenie_CreateLibrary_name)
                      }
                    }
                  }
                }
              }
              runAfter: {
                List_related_SharePoint_Library_records: [
                  'Succeeded'
                ]
              }
              type: 'Foreach'
              description: 'Get column information and call child logic app to create the library'
              runtimeConfiguration: {
                concurrency: {
                  repetitions: 1
                }
              }
            }
            For_each_SharePoint_List_record: {
              foreach: '@body(\'List_related_SharePoint_List_records\')?[\'value\']'
              actions: {
                For_each_List_Column_record: {
                  foreach: '@body(\'List_related_List_Column_records\')?[\'value\']'
                  actions: {
                    Append_column_definition_to_ListColumns: {
                      runAfter: {}
                      type: 'AppendToArrayVariable'
                      inputs: {
                        name: 'ListColumns'
                        value: {
                          columnName: '@{items(\'For_each_List_Column_record\')?[\'cy_columnname\']}'
                          columnType: '@{items(\'For_each_List_Column_record\')?[\'_cy_columntype_label\']}'
                          columnvalues: '@if(equals(items(\'For_each_List_Column_record\')?[\'_cy_columntype_label\'],\'Choice\'),array(split(items(\'For_each_List_Column_record\')?[\'cy_columnvalues\'],\',\')),null)'
                        }
                      }
                    }
                  }
                  runAfter: {
                    List_related_List_Column_records: [
                      'Succeeded'
                    ]
                  }
                  type: 'Foreach'
                  description: 'Append column information to ListColumn variable'
                }
                List_related_List_Column_records: {
                  runAfter: {}
                  type: 'ApiConnection'
                  inputs: {
                    host: {
                      connection: {
                        name: '@parameters(\'$connections\')[\'commondataservice\'][\'connectionId\']'
                      }
                    }
                    method: 'get'
                    path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(parameters(\'DataverseEnvironmentId\')))}/tables/@{encodeURIComponent(encodeURIComponent(\'cy_listcolumns\'))}/items'
                    queries: {
                      '$filter': '_cy_sharepointlist_value eq \'@{items(\'For_each_SharePoint_List_record\')?[\'cy_sharepointlistid\']}\''
                    }
                  }
                  description: 'Get the columns in this list record'
                }
                'ProvisionGenie-CreateList': {
                  runAfter: {
                    For_each_List_Column_record: [
                      'Succeeded'
                    ]
                  }
                  type: 'Workflow'
                  inputs: {
                    body: {
                      listColumns: '@variables(\'ListColumns\')'
                      listName: '@items(\'For_each_SharePoint_List_record\')?[\'cy_listname\']'
                      siteId: '@{outputs(\'Compose_id\')}'
                    }
                    host: {
                      triggerName: 'manual'
                      workflow: {
                        id: resourceId('Microsoft.Logic/workflows', workflows_ProvisionGenie_CreateList_name)
                      }
                    }
                  }
                }
              }
              runAfter: {
                List_related_SharePoint_List_records: [
                  'Succeeded'
                ]
              }
              type: 'Foreach'
              description: 'Get column information and call child logic app to create the list'
              runtimeConfiguration: {
                concurrency: {
                  repetitions: 1
                }
              }
            }
            List_related_SharePoint_Library_records: {
              runAfter: {
                For_each_SharePoint_List_record: [
                  'Succeeded'
                ]
              }
              type: 'ApiConnection'
              inputs: {
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'commondataservice\'][\'connectionId\']'
                  }
                }
                method: 'get'
                path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(parameters(\'DataverseEnvironmentId\')))}/tables/@{encodeURIComponent(encodeURIComponent(\'cy_sharepointlibraries\'))}/items'
                queries: {
                  '$filter': '_cy_teamsrequest_value eq \'@{triggerBody()?[\'cy_teamsrequestid\']}\''
                }
              }
              description: 'Get SharePoint Library records related to the Teams request'
            }
            List_related_SharePoint_List_records: {
              runAfter: {}
              type: 'ApiConnection'
              inputs: {
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'commondataservice\'][\'connectionId\']'
                  }
                }
                method: 'get'
                path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(parameters(\'DataverseEnvironmentId\')))}/tables/@{encodeURIComponent(encodeURIComponent(\'cy_sharepointlists\'))}/items'
                queries: {
                  '$filter': '_cy_teamsrequest_value eq \'@{triggerBody()?[\'cy_teamsrequestid\']}\''
                }
              }
              description: 'Get SharePoint List records related to the Teams request'
            }
          }
          runAfter: {
            Scope_Create_Team: [
              'Succeeded'
            ]
          }
          type: 'Scope'
        }
        Scope_Create_Team: {
          actions: {
            Compose_files_folder_path: {
              runAfter: {
                Until_drive_exists: [
                  'Succeeded'
                ]
              }
              type: 'Compose'
              inputs: '@replace(body(\'HTTP_to_check_if_root_drive_exists\')[\'webUrl\'],body(\'Get_Team_root_site\')[\'webUrl\'],\'\')'
            }
            For_each_related_Channel: {
              foreach: '@body(\'List_related_Team_Channel_records\')?[\'value\']'
              actions: {
                Append_to_Channels: {
                  runAfter: {}
                  type: 'AppendToArrayVariable'
                  inputs: {
                    name: 'Channels'
                    value: {
                      description: '@{items(\'For_each_related_Channel\')?[\'cy_channeldescription\']}'
                      displayName: '@{items(\'For_each_related_Channel\')?[\'cy_channelname\']}'
                      isFavoriteByDefault: '@items(\'For_each_related_Channel\')?[\'cy_autofavorite\']'
                    }
                  }
                }
              }
              runAfter: {
                List_related_Team_Channel_records: [
                  'Succeeded'
                ]
              }
              type: 'Foreach'
              description: 'Append channel information to Channels variable'
            }
            List_related_Team_Channel_records: {
              runAfter: {}
              type: 'ApiConnection'
              inputs: {
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'commondataservice\'][\'connectionId\']'
                  }
                }
                method: 'get'
                path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(parameters(\'DataverseEnvironmentId\')))}/tables/@{encodeURIComponent(encodeURIComponent(\'cy_teamchannels\'))}/items'
                queries: {
                  '$filter': '_cy_teamsrequest_value eq \'@{triggerBody()?[\'cy_teamsrequestid\']}\''
                }
              }
              description: 'Get the channels related to the trigger\'s Teams request'
            }
            Parse_HTTP_body_for_Team_Id: {
              runAfter: {
                'ProvisionGenie-CreateTeam': [
                  'Succeeded'
                ]
              }
              type: 'ParseJson'
              inputs: {
                content: '@body(\'ProvisionGenie-CreateTeam\')'
                schema: {
                  properties: {
                    TeamId: {
                      type: 'string'
                    }
                  }
                  type: 'object'
                }
              }
            }
            'ProvisionGenie-CreateTeam': {
              runAfter: {
                For_each_related_Channel: [
                  'Succeeded'
                ]
              }
              type: 'Workflow'
              inputs: {
                body: {
                  Channels: '@variables(\'Channels\')'
                  Description: '@triggerBody()?[\'cy_teamdescription\']'
                  'Display Name': '@triggerBody()?[\'cy_teamname\']'
                  'Owner UPN': '@triggerBody()?[\'cy_teamowner\']'
                  'Technical Name': '@{outputs(\'Generate_Team_internal_name\')}'
                }
                host: {
                  triggerName: 'manual'
                  workflow: {
                    id: resourceId('Microsoft.Logic/workflows', workflows_ProvisionGenie_CreateTeam_name)
                  }
                }
              }
            }
            Until_drive_exists: {
              actions: {
                Condition_DriveExistsCode_200: {
                  actions: {}
                  runAfter: {
                    Update_DriveExistsCode: [
                      'Succeeded'
                    ]
                  }
                  else: {
                    actions: {
                      Delay_2: {
                        runAfter: {}
                        type: 'Wait'
                        inputs: {
                          interval: {
                            count: 30
                            unit: 'Second'
                          }
                        }
                      }
                    }
                  }
                  expression: {
                    and: [
                      {
                        equals: [
                          '@variables(\'DriveExistsCode\')'
                          200
                        ]
                      }
                    ]
                  }
                  type: 'If'
                }
                HTTP_to_check_if_root_drive_exists: {
                  runAfter: {}
                  type: 'Http'
                  inputs: {
                    authentication: {
                      audience: 'https://graph.microsoft.com'
                      identity: resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', userAssignedIdentities_ProvisionGenie_ManagedIdentity_name)
                      type: 'ManagedServiceIdentity'
                    }
                    method: 'GET'
                    uri: 'https://graph.microsoft.com/v1.0/groups/@{body(\'Parse_HTTP_body_for_Team_Id\')?[\'TeamId\']}/drive/root'
                  }
                }
                Update_DriveExistsCode: {
                  runAfter: {
                    HTTP_to_check_if_root_drive_exists: [
                      'Succeeded'
                    ]
                  }
                  type: 'SetVariable'
                  inputs: {
                    name: 'DriveExistsCode'
                    value: '@outputs(\'HTTP_to_check_if_root_drive_exists\')[\'statusCode\']'
                  }
                }
              }
              runAfter: {
                Until_root_site_exists: [
                  'Succeeded'
                ]
              }
              expression: '@equals(variables(\'DriveExistsCode\'), 200)'
              limit: {
                count: 1000
                timeout: 'PT1H'
              }
              type: 'Until'
              description: 'Wait until the folder is created - otherwise following actions will fail'
            }
            Until_root_site_exists: {
              actions: {
                Compose_id: {
                  runAfter: {
                    Compose_webUrl: [
                      'Succeeded'
                    ]
                  }
                  type: 'Compose'
                  inputs: '@outputs(\'Get_Team_root_site\')?[\'body\'][\'id\']'
                }
                Compose_webUrl: {
                  runAfter: {
                    Get_Team_root_site: [
                      'Succeeded'
                    ]
                  }
                  type: 'Compose'
                  inputs: '@outputs(\'Get_Team_root_site\')?[\'body\'][\'webUrl\']'
                }
                Condition_SiteExistsCode_200: {
                  actions: {}
                  runAfter: {
                    Update_SiteExistsCode: [
                      'Succeeded'
                    ]
                  }
                  else: {
                    actions: {
                      Delay: {
                        runAfter: {}
                        type: 'Wait'
                        inputs: {
                          interval: {
                            count: 30
                            unit: 'Second'
                          }
                        }
                      }
                    }
                  }
                  expression: {
                    and: [
                      {
                        equals: [
                          '@variables(\'SiteExistsCode\')'
                          200
                        ]
                      }
                    ]
                  }
                  type: 'If'
                }
                Get_Team_root_site: {
                  runAfter: {}
                  type: 'Http'
                  inputs: {
                    authentication: {
                      audience: 'https://graph.microsoft.com'
                      identity: resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', userAssignedIdentities_ProvisionGenie_ManagedIdentity_name)
                      type: 'ManagedServiceIdentity'
                    }
                    method: 'GET'
                    uri: 'https://graph.microsoft.com/v1.0/groups/@{body(\'Parse_HTTP_body_for_Team_Id\')?[\'TeamId\']}/sites/root'
                  }
                }
                Update_SiteExistsCode: {
                  runAfter: {
                    Compose_id: [
                      'Succeeded'
                    ]
                  }
                  type: 'SetVariable'
                  inputs: {
                    name: 'SiteExistsCode'
                    value: '@outputs(\'Get_Team_root_site\')[\'statusCode\']'
                  }
                }
              }
              runAfter: {
                Parse_HTTP_body_for_Team_Id: [
                  'Succeeded'
                ]
              }
              expression: '@equals(variables(\'SiteExistsCode\'), 200)'
              limit: {
                count: 1000
                timeout: 'PT1H'
              }
              type: 'Until'
              description: 'Wait until the root site exists - otherwise following actions will fail'
            }
          }
          runAfter: {
            Wait_1_minute_to_add_channels: [
              'Succeeded'
            ]
          }
          type: 'Scope'
          description: 'Get channel information, create team and wait for team creation to complete'
        }
        SiteExistsCode: {
          runAfter: {
            DriveExistsCode: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'SiteExistsCode'
                type: 'integer'
              }
            ]
          }
        }
        Wait_1_minute_to_add_channels: {
          runAfter: {
            Buckets: [
              'Succeeded'
            ]
          }
          type: 'Wait'
          inputs: {
            interval: {
              count: 1
              unit: 'Minute'
            }
          }
          description: 'Wait 1 minute to provide time for the channels to be linked to the team that has been created'
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          commondataservice: {
            connectionId: resourceId('Microsoft.Web/connections', connections_commondataservice_name)
            connectionName: 'commondataservice'
            id: '/subscriptions/${subscriptionId}/providers/Microsoft.Web/locations/${resourceLocation}/managedApis/commondataservice'
          }
        }
      }
    }
  }
  dependsOn: [
    resourceId('Microsoft.Logic/workflows', workflows_ProvisionGenie_Welcome_name)
    resourceId('Microsoft.Logic/workflows', workflows_ProvisionGenie_CreateTaskList_name)
    resourceId('Microsoft.Logic/workflows', workflows_ProvisionGenie_CreateLibrary_name)
    resourceId('Microsoft.Logic/workflows', workflows_ProvisionGenie_CreateList_name)
    resourceId('Microsoft.Logic/workflows', workflows_ProvisionGenie_CreateTeam_name)
    resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', userAssignedIdentities_ProvisionGenie_ManagedIdentity_name)
    resourceId('Microsoft.Web/connections', connections_commondataservice_name)
  ]
}
