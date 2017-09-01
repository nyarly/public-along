require 'net/http'
module AdpService
  class Worker < Base

    def update_worker_email
      # data = {
      #   "worker": {
      #     "associateOID": "G3FR7ZM9MHR45P9E",
      #     "workerID": {
      #       "idValue": "102187"
      #     },
      #     "businessCommunication": {
      #       "email": {
      #         "nameCode": {
      #           "codeValue": "Work E-mail",
      #           "shortName": "Work E-mail"
      #         },
      #         "itemID": "paulanewemailtest@example.com"
      #       }
      #     }
      #   }
      # }

      data = {
        "events": [
          {
            "eventID": "string",
            "serviceCategoryCode": {
              "codeValue": "string",
              "shortName": "string",
              "longName": "string"
            },
            "eventNameCode": {
              "codeValue": "string",
              "shortName": "string",
              "longName": "string"
            },
            "eventTitle": "string",
            "eventSubTitle": "string",
            "eventReasonCode": {
              "codeValue": "string",
              "shortName": "string",
              "longName": "string"
            },
            "eventStatusCode": {
              "codeValue": "string",
              "shortName": "string",
              "longName": "string"
            },
            "priorityCode": {
              "codeValue": "string",
              "shortName": "string",
              "longName": "string"
            },
            "recordDateTime": "2016-10-13T15:13:00.000Z",
            "creationDateTime": "2016-10-13T15:13:00.000Z",
            "effectiveDateTime": "2016-10-13T15:13:00.000Z",
            "expirationDateTime": "2016-10-13T15:13:00.000Z",
            "dueDateTime": "2016-10-13T15:13:00.000Z",
            "originator": {
              "applicationID": {
                "idValue": "string",
                "schemeCode": {
                  "codeValue": "string",
                  "shortName": "string",
                  "longName": "string"
                }
              },
              "associateOID": "string",
              "personOID": "string",
              "formattedName": "string",
              "eventID": "string",
              "eventNameCode": {
                "codeValue": "string",
                "shortName": "string",
                "longName": "string"
              },
              "deviceID": "string"
            },
            "actor": {
              "applicationID": {
                "idValue": "string",
                "schemeCode": {
                  "codeValue": "string",
                  "shortName": "string",
                  "longName": "string"
                }
              },
              "associateOID": "string",
              "personOID": "string",
              "formattedName": "string",
              "deviceID": "string",
              "geoCoordinate": {
                "latitude": 0,
                "longitude": 0
              },
              "deviceUserAgentID": "string"
            },
            "actAsParty": {
              "applicationID": {
                "idValue": "string",
                "schemeCode": {
                  "codeValue": "string",
                  "shortName": "string",
                  "longName": "string"
                }
              },
              "associateOID": "string",
              "personOID": "string",
              "formattedName": "string",
              "deviceID": "string",
              "geoCoordinate": {
                "latitude": 0,
                "longitude": 0
              },
              "deviceUserAgentID": "string",
              "organizationOID": "string"
            },
            "onBehalfOfParty": {
              "applicationID": {
                "idValue": "string",
                "schemeCode": {
                  "codeValue": "string",
                  "shortName": "string",
                  "longName": "string"
                }
              },
              "associateOID": "string",
              "personOID": "string",
              "formattedName": "string",
              "deviceID": "string",
              "geoCoordinate": {
                "latitude": 0,
                "longitude": 0
              },
              "deviceUserAgentID": "string",
              "organizationOID": "string"
            },
            "links": [
              {
                "href": "string",
                "rel": "alternate",
                "title": "string",
                "targetSchema": "string",
                "mediaType": "application/json",
                "method": "GET",
                "encType": "application/json",
                "schema": "string"
              }
            ],
            "data": {
              "eventContext": {
                "contextExpressionID": "string",
                "worker": {
                  "associateOID": "G3FR7ZM9MHR45P9E",
                  "businessCommunication": {
                    "email": {
                      "itemID": "testpaula@example.com"
                    }
                  }
                }
              },
              "transform": {
                "eventReasonCode": {
                  "codeValue": "string",
                  "shortName": "string",
                  "longName": "string"
                },
                "eventStatusCode": {
                  "codeValue": "string",
                  "shortName": "string",
                  "longName": "string"
                },
                "effectiveDateTime": "2016-10-13T15:13:00.000Z",
                "worker": {
                  "businessCommunication": {
                    "email": {
                      "nameCode": {
                        "codeValue": "string",
                        "shortName": "string",
                        "longName": "string"
                      },
                      "emailUri": "string"
                    }
                  }
                }
              },
              "output": {
                "worker": {
                  "associateOID": "G3FR7ZM9MHR45P9E",
                  "workerID": {
                    "idValue": "102187"
                  },
                  "businessCommunication": {
                    "email": {
                      "nameCode": {
                        "codeValue": "string",
                        "shortName": "string",
                        "longName": "string"
                      },
                      "emailUri": "string",
                      "itemID": "string"
                    }
                  }
                }
              }
            }
          }
        ],
        "meta": {
          "startSequence": 0,
          "completeIndicator": true,
          "totalNumber": 0,
          "resourceSetID": "string",
          "links": [
            {
              "href": "string",
              "rel": "alternate",
              "title": "string",
              "targetSchema": "string",
              "mediaType": "application/json",
              "method": "GET",
              "encType": "application/json",
              "schema": "string"
            }
          ]
        },
        "confirmMessage": {
          "confirmMessageID": {
            "idValue": "string",
            "schemeName": "string",
            "schemeAgencyName": "string"
          },
          "createDateTime": "2016-10-13T15:13:00.000Z",
          "requestReceiptDateTime": "2016-10-13T15:13:00.000Z",
          "protocolStatusCode": {
            "codeValue": "string",
            "shortName": "string",
            "longName": "string"
          },
          "protocolCode": {
            "codeValue": "string",
            "shortName": "string",
            "longName": "string"
          },
          "requestID": {
            "idValue": "string",
            "schemeName": "string",
            "schemeAgencyName": "string"
          },
          "requestStatusCode": {
            "shortName": "string",
            "longName": "string",
            "codeValue": "succeeded"
          },
          "requestMethodCode": {
            "shortName": "string",
            "longName": "string",
            "codeValue": "GET"
          },
          "sessionID": {
            "idValue": "string",
            "schemeName": "string",
            "schemeAgencyName": "string"
          },
          "requestETag": "string",
          "requestLink": {
            "href": "string",
            "rel": "alternate",
            "title": "string",
            "targetSchema": "string",
            "mediaType": "application/json",
            "method": "GET",
            "encType": "application/json",
            "schema": "string"
          },
          "processingStatusCode": {
            "shortName": "string",
            "longName": "string",
            "codeValue": "received"
          },
          "processMessages": [
            {
              "processMessageID": {
                "idValue": "string",
                "schemeName": "string",
                "schemeAgencyName": "string"
              },
              "messageTypeCode": {
                "shortName": "string",
                "longName": "string",
                "codeValue": "success"
              },
              "sourceLocationExpression": "string",
              "expressionLanguageCode": {
                "shortName": "string",
                "longName": "string",
                "codeValue": "jPath"
              },
              "links": [
                {
                  "href": "string",
                  "rel": "alternate",
                  "title": "string",
                  "targetSchema": "string",
                  "mediaType": "application/json",
                  "method": "GET",
                  "encType": "application/json",
                  "schema": "string"
                }
              ],
              "userMessage": {
                "codeValue": "string",
                "title": "string",
                "messageTxt": "string",
                "links": [
                  {
                    "href": "string",
                    "rel": "alternate",
                    "title": "string",
                    "targetSchema": "string",
                    "mediaType": "application/json",
                    "method": "GET",
                    "encType": "application/json",
                    "schema": "string"
                  }
                ]
              },
              "developerMessage": {
                "codeValue": "string",
                "title": "string",
                "messageTxt": "string",
                "links": [
                  {
                    "href": "string",
                    "rel": "alternate",
                    "title": "string",
                    "targetSchema": "string",
                    "mediaType": "application/json",
                    "method": "GET",
                    "encType": "application/json",
                    "schema": "string"
                  }
                ]
              }
            }
          ],
          "resourceMessages": [
            {
              "resourceMessageID": {
                "idValue": "string",
                "schemeName": "string",
                "schemeAgencyName": "string"
              },
              "resourceStatusCode": {
                "shortName": "string",
                "longName": "string",
                "codeValue": "succeeded"
              },
              "resourceLink": {
                "href": "string",
                "rel": "alternate",
                "title": "string",
                "targetSchema": "string",
                "mediaType": "application/json",
                "method": "GET",
                "encType": "application/json",
                "schema": "string"
              },
              "processMessages": [
                {
                  "processMessageID": {
                    "idValue": "string",
                    "schemeName": "string",
                    "schemeAgencyName": "string"
                  },
                  "messageTypeCode": {
                    "shortName": "string",
                    "longName": "string",
                    "codeValue": "success"
                  },
                  "sourceLocationExpression": "string",
                  "expressionLanguageCode": {
                    "shortName": "string",
                    "longName": "string",
                    "codeValue": "jPath"
                  },
                  "links": [
                    {
                      "href": "string",
                      "rel": "alternate",
                      "title": "string",
                      "targetSchema": "string",
                      "mediaType": "application/json",
                      "method": "GET",
                      "encType": "application/json",
                      "schema": "string"
                    }
                  ],
                  "userMessage": {
                    "codeValue": "string",
                    "title": "string",
                    "messageTxt": "string",
                    "links": [
                      {
                        "href": "string",
                        "rel": "alternate",
                        "title": "string",
                        "targetSchema": "string",
                        "mediaType": "application/json",
                        "method": "GET",
                        "encType": "application/json",
                        "schema": "string"
                      }
                    ]
                  },
                  "developerMessage": {
                    "codeValue": "string",
                    "title": "string",
                    "messageTxt": "string",
                    "links": [
                      {
                        "href": "string",
                        "rel": "alternate",
                        "title": "string",
                        "targetSchema": "string",
                        "mediaType": "application/json",
                        "method": "GET",
                        "encType": "application/json",
                        "schema": "string"
                      }
                    ]
                  },
                  "resourceStatusCode": {
                    "codeValue": "string",
                    "shortName": "string",
                    "longName": "string"
                  }
                }
              ]
            }
          ]
        }
      }

      my_data = {
        "events": [
          "worker": {
            "associateOID": "G3FR7ZM9MHR45P9E",
            "workerID": {
              "idValue": "102187"
            },
            "data": {
              "eventContext": {
                "contextExpressionID": "string",
                "worker": {
                  "associateOID": "G3FR7ZM9MHR45P9E",
                  "businessCommunication": {
                    "email": {
                      "itemID": "testpaula@example.com"
                    }
                  }
                }
              },
              "transform": {
                "eventReasonCode": {
                  "codeValue": "string",
                  "shortName": "string",
                  "longName": "string"
                },
                "eventStatusCode": {
                  "codeValue": "string",
                  "shortName": "string",
                  "longName": "string"
                },
                "effectiveDateTime": "2016-10-13T15:13:00.000Z",
                "worker": {
                  "businessCommunication": {
                    "email": {
                      "nameCode": {
                        "codeValue": "string",
                        "shortName": "string",
                        "longName": "string"
                      },
                      "emailUri": "string"
                    }
                  }
                }
              }
            }
          }
        ]
      }

      send_data = JSON.parse(my_data.to_json)

      set_http("https://#{SECRETS.adp_token_domain}/auth/oauth/v2/token?grant_type=client_credentials")
      res = @http.post(@uri.request_uri,'', {'Accept' => 'application/json', 'Authorization' => "Basic #{SECRETS.adp_creds}"})
      token = JSON.parse(res.body)["access_token"]

      url = "https://#{SECRETS.adp_api_domain}/events/hr/v1/worker.business-communication.email.change"
      my_uri = URI.parse(url)
      http = Net::HTTP.new(my_uri.host, my_uri.port)
      http.read_timeout = 200
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      pem = File.read(SECRETS.adp_pem_path)
      key = File.read(SECRETS.adp_key_path)
      http.cert = OpenSSL::X509::Certificate.new(pem)
      http.key = OpenSSL::PKey::RSA.new(key)

      request = Net::HTTP::Post.new(my_uri.request_uri, {'Content-Type' => 'application/json', 'Accept' => 'application/json', 'Authorization' => "Bearer #{@token}", 'roleCode' => 'practitioner', 'Accept-Language' => 'en-US'})
      # request.set_form_data(send_data)
      request.content_type = 'application/json'
      request.body = my_data.to_json
      # puts send_data
      res = http.request(request)

      puts res.inspect

      puts res.code
      puts res.message
      puts res.body
    end
  end
end
