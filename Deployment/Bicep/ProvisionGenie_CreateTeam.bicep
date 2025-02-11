param workflows_ProvisionGenie_CreateTeam_name string
param userAssignedIdentities_ProvisionGenie_ManagedIdentity_name string
param resourceLocation string

@secure()
param subscriptionId string
param resourceGroupName string

@secure()
param ManagedIdentity_ObjectId string

@secure()
param ManagedIdentity_ClientId string

resource workflows_ProvisionGenie_CreateTeam_name_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  name: workflows_ProvisionGenie_CreateTeam_name
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
      parameters: {}
      staticResults: {
        HTTP_delete_wiki_tab0: {
          status: 'Succeeded'
          outputs: {
            headers: {}
            statusCode: 'OK'
          }
        }
      }
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            method: 'POST'
            schema: {
              properties: {
                Channels: {
                  items: {
                    properties: {
                      description: {
                        type: 'string'
                      }
                      displayName: {
                        type: 'string'
                      }
                    }
                    required: [
                      'displayName'
                      'description'
                    ]
                    type: 'object'
                  }
                  type: 'array'
                }
                Description: {
                  type: 'string'
                }
                'Display Name': {
                  type: 'string'
                }
                'Owner UPN': {
                  type: 'string'
                }
                'Technical Name': {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
        }
      }
      actions: {
        Description: {
          runAfter: {
            DisplayName: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'Description'
                type: 'string'
                value: '@triggerBody()?[\'Description\']'
              }
            ]
          }
        }
        DisplayName: {
          runAfter: {
            TechnicalName: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'DisplayName'
                type: 'string'
                value: '@triggerBody()?[\'Display Name\']'
              }
            ]
          }
        }
        For_each_channel: {
          foreach: '@body(\'Parse_channel_info\')?[\'value\']'
          actions: {
            For_each_wiki_tab: {
              foreach: '@body(\'Parse_wiki_tab_info\')?[\'value\']'
              actions: {
                HTTP_delete_wiki_tab: {
                  runAfter: {}
                  type: 'Http'
                  inputs: {
                    authentication: {
                      audience: 'https://graph.microsoft.com'
                      identity: resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', userAssignedIdentities_ProvisionGenie_ManagedIdentity_name)
                      type: 'ManagedServiceIdentity'
                    }
                    method: 'DELETE'
                    uri: 'https://graph.microsoft.com/v1.0/teams/@{variables(\'NewTeamId\')}/channels/@{items(\'For_each_channel\')?[\'id\']}/tabs/@{items(\'For_each_wiki_tab\')?[\'id\']}'
                  }
                  runtimeConfiguration: {
                    staticResult: {
                      staticResultOptions: 'Disabled'
                      name: 'HTTP_delete_wiki_tab0'
                    }
                  }
                }
              }
              runAfter: {
                Parse_wiki_tab_info: [
                  'Succeeded'
                ]
              }
              type: 'Foreach'
            }
            HTTP_get_wiki_tab: {
              runAfter: {}
              type: 'Http'
              inputs: {
                authentication: {
                  audience: 'https://graph.microsoft.com'
                  identity: resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', userAssignedIdentities_ProvisionGenie_ManagedIdentity_name)
                  type: 'ManagedServiceIdentity'
                }
                method: 'GET'
                uri: 'https://graph.microsoft.com/beta/teams/@{variables(\'NewTeamId\')}/channels/@{items(\'For_each_channel\')?[\'id\']}/tabs?$filter=displayName eq \'Wiki\''
              }
            }
            Parse_wiki_tab_info: {
              runAfter: {
                HTTP_get_wiki_tab: [
                  'Succeeded'
                ]
              }
              type: 'ParseJson'
              inputs: {
                content: '@body(\'HTTP_get_wiki_tab\')'
                schema: {
                  properties: {
                    '@@odata.context': {
                      type: 'string'
                    }
                    '@@odata.count': {
                      type: 'integer'
                    }
                    value: {
                      items: {
                        properties: {
                          configuration: {
                            properties: {
                              contentUrl: {}
                              entityId: {}
                              hasContent: {
                                type: 'boolean'
                              }
                              removeUrl: {}
                              websiteUrl: {}
                              wikiDefaultTab: {
                                type: 'boolean'
                              }
                              wikiTabId: {
                                type: 'integer'
                              }
                            }
                            type: 'object'
                          }
                          displayName: {
                            type: 'string'
                          }
                          id: {
                            type: 'string'
                          }
                          messageId: {}
                          sortOrderIndex: {
                            type: 'string'
                          }
                          teamsAppId: {}
                          webUrl: {
                            type: 'string'
                          }
                        }
                        required: [
                          'id'
                          'displayName'
                          'teamsAppId'
                          'sortOrderIndex'
                          'messageId'
                          'webUrl'
                          'configuration'
                        ]
                        type: 'object'
                      }
                      type: 'array'
                    }
                  }
                  type: 'object'
                }
              }
            }
          }
          runAfter: {
            Parse_channel_info: [
              'Succeeded'
            ]
          }
          type: 'Foreach'
          description: 'Remove the wiki from each created channel'
        }
        HTTP_create_group: {
          runAfter: {
            Parse_owner_info: [
              'Succeeded'
            ]
          }
          type: 'Http'
          inputs: {
            authentication: {
              audience: 'https://graph.microsoft.com/'
              identity: resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', userAssignedIdentities_ProvisionGenie_ManagedIdentity_name)
              type: 'ManagedServiceIdentity'
            }
            body: {
              description: '@{triggerBody()?[\'Description\']}'
              displayName: '@{triggerBody()?[\'Display Name\']}'
              groupTypes: [
                'Unified'
              ]
              mailEnabled: true
              mailNickname: '@{triggerBody()?[\'Technical Name\']}'
              'members@odata.bind': [
                'https://graph.microsoft.com/v1.0/users/@{body(\'Parse_owner_info\')?[\'id\']}'
              ]
              'owners@odata.bind': [
                'https://graph.microsoft.com/v1.0/users/@{body(\'Parse_owner_info\')?[\'id\']}'
              ]
              securityEnabled: false
              visibility: 'Private'
            }
            headers: {
              'Content-type': 'application/json'
            }
            method: 'POST'
            uri: 'https://graph.microsoft.com/v1.0/groups'
          }
        }
        HTTP_get_channels: {
          runAfter: {
            Until_Team_upgrade_succeeded: [
              'Succeeded'
            ]
          }
          type: 'Http'
          inputs: {
            authentication: {
              audience: 'https://graph.microsoft.com'
              identity: resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', userAssignedIdentities_ProvisionGenie_ManagedIdentity_name)
              type: 'ManagedServiceIdentity'
            }
            method: 'GET'
            uri: 'https://graph.microsoft.com/v1.0/teams/@{variables(\'NewTeamId\')}/channels'
          }
        }
        HTTP_get_owner_info: {
          runAfter: {
            NewTeamId: [
              'Succeeded'
            ]
          }
          type: 'Http'
          inputs: {
            authentication: {
              audience: 'https://graph.microsoft.com'
              identity: resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', userAssignedIdentities_ProvisionGenie_ManagedIdentity_name)
              type: 'ManagedServiceIdentity'
            }
            method: 'GET'
            uri: 'https://graph.microsoft.com/v1.0/users/@{triggerBody()?[\'Owner UPN\']}'
          }
        }
        NewTeamId: {
          runAfter: {
            TeamCreationStatus: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'NewTeamId'
                type: 'string'
              }
            ]
          }
        }
        Parse_channel_info: {
          runAfter: {
            HTTP_get_channels: [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
          inputs: {
            content: '@body(\'HTTP_get_channels\')'
            schema: {
              properties: {
                '@@odata.context': {
                  type: 'string'
                }
                '@@odata.count': {
                  type: 'integer'
                }
                value: {
                  items: {
                    properties: {
                      description: {
                        type: 'string'
                      }
                      displayName: {
                        type: 'string'
                      }
                      email: {
                        type: 'string'
                      }
                      id: {
                        type: 'string'
                      }
                      isFavoriteByDefault: {}
                      membershipType: {
                        type: 'string'
                      }
                      webUrl: {
                        type: 'string'
                      }
                    }
                    required: [
                      'id'
                      'displayName'
                      'description'
                      'isFavoriteByDefault'
                      'email'
                      'webUrl'
                      'membershipType'
                    ]
                    type: 'object'
                  }
                  type: 'array'
                }
              }
              type: 'object'
            }
          }
        }
        Parse_group_creation_body: {
          runAfter: {
            HTTP_create_group: [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
          inputs: {
            content: '@body(\'HTTP_create_group\')'
            schema: {
              properties: {
                '@@odata.context': {
                  type: 'string'
                }
                classification: {}
                createdDateTime: {
                  type: 'string'
                }
                creationOptions: {
                  type: 'array'
                }
                deletedDateTime: {}
                description: {
                  type: 'string'
                }
                displayName: {
                  type: 'string'
                }
                expirationDateTime: {}
                groupTypes: {
                  items: {
                    type: 'string'
                  }
                  type: 'array'
                }
                id: {
                  type: 'string'
                }
                isAssignableToRole: {}
                mail: {
                  type: 'string'
                }
                mailEnabled: {
                  type: 'boolean'
                }
                mailNickname: {
                  type: 'string'
                }
                membershipRule: {}
                membershipRuleProcessingState: {}
                onPremisesDomainName: {}
                onPremisesLastSyncDateTime: {}
                onPremisesNetBiosName: {}
                onPremisesProvisioningErrors: {
                  type: 'array'
                }
                onPremisesSamAccountName: {}
                onPremisesSecurityIdentifier: {}
                onPremisesSyncEnabled: {}
                preferredDataLocation: {}
                preferredLanguage: {}
                proxyAddresses: {
                  items: {
                    type: 'string'
                  }
                  type: 'array'
                }
                renewedDateTime: {
                  type: 'string'
                }
                resourceBehaviorOptions: {
                  type: 'array'
                }
                resourceProvisioningOptions: {
                  type: 'array'
                }
                securityEnabled: {
                  type: 'boolean'
                }
                securityIdentifier: {
                  type: 'string'
                }
                theme: {}
                visibility: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
        }
        Parse_owner_info: {
          runAfter: {
            HTTP_get_owner_info: [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
          inputs: {
            content: '@body(\'HTTP_get_owner_info\')'
            schema: {
              properties: {
                '@@odata.context': {
                  type: 'string'
                }
                businessPhones: {
                  items: {
                    type: 'string'
                  }
                  type: 'array'
                }
                displayName: {
                  type: 'string'
                }
                givenName: {
                  type: 'string'
                }
                id: {
                  type: 'string'
                }
                jobTitle: {}
                mail: {
                  type: 'string'
                }
                mobilePhone: {}
                officeLocation: {}
                preferredLanguage: {
                  type: 'string'
                }
                surname: {
                  type: 'string'
                }
                userPrincipalName: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
        }
        Parse_team_creation_headers: {
          runAfter: {
            Until_Team_upgrade_accepted: [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
          inputs: {
            content: '@outputs(\'HTTP_update_group_to_team\')[\'headers\']'
            schema: {
              properties: {
                'Content-Length': {
                  type: 'string'
                }
                Date: {
                  type: 'string'
                }
                Location: {
                  type: 'string'
                }
                'Strict-Transport-Security': {
                  type: 'string'
                }
                'Transfer-Encoding': {
                  type: 'string'
                }
                'client-request-id': {
                  type: 'string'
                }
                'request-id': {
                  type: 'string'
                }
                'x-ms-ags-diagnostic': {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
        }
        Response: {
          runAfter: {
            For_each_channel: [
              'Succeeded'
            ]
          }
          type: 'Response'
          kind: 'Http'
          inputs: {
            body: {
              TeamId: '@{body(\'Parse_group_creation_body\')?[\'id\']}'
            }
            statusCode: 200
          }
        }
        Set_NewTeamId_to_created_group_id: {
          runAfter: {
            Parse_group_creation_body: [
              'Succeeded'
            ]
          }
          type: 'SetVariable'
          inputs: {
            name: 'NewTeamId'
            value: '@body(\'Parse_group_creation_body\')?[\'id\']'
          }
        }
        TeamCreationRequestCode: {
          runAfter: {
            Description: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'TeamCreationRequestCode'
                type: 'string'
              }
            ]
          }
        }
        TeamCreationStatus: {
          runAfter: {
            TeamCreationRequestCode: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'TeamCreationStatus'
                type: 'string'
              }
            ]
          }
        }
        TechnicalName: {
          runAfter: {}
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'TechnicalName'
                type: 'string'
                value: '@triggerBody()?[\'Technical Name\']'
              }
            ]
          }
        }
        Until_Team_upgrade_accepted: {
          actions: {
            Condition_2: {
              actions: {
                Delay_10_seconds_for_404: {
                  runAfter: {}
                  type: 'Wait'
                  inputs: {
                    interval: {
                      count: 10
                      unit: 'Second'
                    }
                  }
                }
              }
              runAfter: {
                Set_TeamCreationRequestCode_to_Status_code: [
                  'Succeeded'
                ]
              }
              expression: {
                and: [
                  {
                    equals: [
                      '@variables(\'TeamCreationRequestCode\')'
                      '@string(404)'
                    ]
                  }
                ]
              }
              type: 'If'
            }
            HTTP_update_group_to_team: {
              runAfter: {}
              type: 'Http'
              inputs: {
                authentication: {
                  audience: 'https://graph.microsoft.com/'
                  identity: resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', userAssignedIdentities_ProvisionGenie_ManagedIdentity_name)
                  type: 'ManagedServiceIdentity'
                }
                body: {
                  channels: '@triggerBody()?[\'Channels\']'
                  'group@odata.bind': 'https://graph.microsoft.com/v1.0/groups(\'@{variables(\'NewTeamId\')}\')'
                  'template@odata.bind': 'https://graph.microsoft.com/v1.0/teamsTemplates/standard'
                }
                headers: {
                  'content-type': 'application/json'
                }
                method: 'POST'
                uri: 'https://graph.microsoft.com/v1.0/teams'
              }
            }
            Set_TeamCreationRequestCode_to_Status_code: {
              runAfter: {
                HTTP_update_group_to_team: [
                  'Succeeded'
                  'Failed'
                ]
              }
              type: 'SetVariable'
              inputs: {
                name: 'TeamCreationRequestCode'
                value: '@{outputs(\'HTTP_update_group_to_team\')[\'statusCode\']}'
              }
            }
          }
          runAfter: {
            Set_NewTeamId_to_created_group_id: [
              'Succeeded'
            ]
          }
          expression: '@equals(variables(\'TeamCreationRequestCode\'), string(202))'
          limit: {
            count: 60
            timeout: 'PT1H'
          }
          type: 'Until'
        }
        Until_Team_upgrade_succeeded: {
          actions: {
            Condition_TeamsCreationStatus_not_succeeded: {
              actions: {
                Delay_10_seconds_for_team_upgrade: {
                  runAfter: {}
                  type: 'Wait'
                  inputs: {
                    interval: {
                      count: 10
                      unit: 'Second'
                    }
                  }
                }
              }
              runAfter: {
                Set_TeamsCreationStatus: [
                  'Succeeded'
                ]
              }
              expression: {
                and: [
                  {
                    not: {
                      equals: [
                        '@variables(\'TeamCreationStatus\')'
                        'succeeded'
                      ]
                    }
                  }
                ]
              }
              type: 'If'
            }
            HTTP_get_team_creation_status: {
              runAfter: {}
              type: 'Http'
              inputs: {
                authentication: {
                  audience: 'https://graph.microsoft.com/'
                  identity: resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', userAssignedIdentities_ProvisionGenie_ManagedIdentity_name)
                  type: 'ManagedServiceIdentity'
                }
                method: 'GET'
                uri: 'https://graph.microsoft.com/v1.0/@{body(\'Parse_team_creation_headers\')?[\'Location\']}'
              }
            }
            Parse_team_creation_status_body: {
              runAfter: {
                HTTP_get_team_creation_status: [
                  'Succeeded'
                  'Failed'
                ]
              }
              type: 'ParseJson'
              inputs: {
                content: '@body(\'HTTP_get_team_creation_status\')'
                schema: {
                  properties: {
                    '@@odata.context': {
                      type: 'string'
                    }
                    Value: {
                      type: 'string'
                    }
                    attemptsCount: {
                      type: 'integer'
                    }
                    createdDateTime: {
                      type: 'string'
                    }
                    error: {}
                    id: {
                      type: 'string'
                    }
                    lastActionDateTime: {
                      type: 'string'
                    }
                    operationType: {
                      type: 'string'
                    }
                    status: {
                      type: 'string'
                    }
                    targetResourceId: {
                      type: 'string'
                    }
                    targetResourceLocation: {
                      type: 'string'
                    }
                  }
                  type: 'object'
                }
              }
            }
            Set_TeamsCreationStatus: {
              runAfter: {
                Parse_team_creation_status_body: [
                  'Succeeded'
                ]
              }
              type: 'SetVariable'
              inputs: {
                name: 'TeamCreationStatus'
                value: '@body(\'Parse_team_creation_status_body\')?[\'status\']'
              }
            }
          }
          runAfter: {
            Parse_team_creation_headers: [
              'Succeeded'
            ]
          }
          expression: '@equals(variables(\'TeamCreationStatus\'), \'succeeded\')'
          limit: {
            count: 60
            timeout: 'PT1H'
          }
          type: 'Until'
        }
      }
      outputs: {}
    }
    parameters: {}
  }
  dependsOn: [
    resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', userAssignedIdentities_ProvisionGenie_ManagedIdentity_name)
  ]
}
