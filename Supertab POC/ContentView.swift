//
//  ContentView.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 12.10.22.
//

import SwiftUI
import Combine

struct ContentView: View {
    let client = TapperClient()
    @State var clientConfig: TapperClient.ClientConfig?
    @State var activeTab: TapperClient.TabResponse?
    var body: some View {
        NavigationView {
            List {
                VStack(alignment: .leading) {
                    SupertabLogo()
                        .frame(height: 50)
                        .padding(.vertical)
                }
                .frame(maxWidth: .infinity)
                NavigationLink(destination: {
                    PayPerGameView(client: client, siteClientId: "client.d20c6b17-cb04-46df-b94d-5945767ae9bc")
                        .padding()
                        .navigationTitle("Pay per Game")
                }) {
                    Text("Pay per Game")
                }
                NavigationLink(destination: {
                    PayForAccessView(client: client, siteClientId: "client.db219fd6-3505-45c8-a44d-4740d28b0e13")
                        .padding()
                        .navigationTitle("Pay for Access")
                }) {
                    Text("Pay for Access")
                }
                Button {
                    Task {
                        do {
                            activeTab = try await client.fetchActiveTab()?.simpleTabResponse
                            print("Active tab: \(String(describing: activeTab))")
                        } catch(let error) {
                            print("Fetching active tab failed: \(error.localizedDescription)")
                        }
                    }
                } label: {
                    Text("Fetch Active Tab")
                }
                Button {
                    Task {
                        do {
                            clientConfig = try await client.fetchClientConfigFor(clientId: "client.d30c4a23-35ab-468b-b000-84b5c9e1d283")
                            print("Client config: \(String(describing: clientConfig))")
                        } catch(let error) {
                            print("Fetching client config failed: \(error.localizedDescription)")
                        }
                    }
                } label: {
                    Text("Fetch Config")
                }
                Button {
                    Task {
                        do {
                            guard let contentKey = clientConfig?.contentKeys[0].contentKey else {
                                print("Fetch client config first before checking access")
                                return
                            }
                            let accessResponse = try await client.checkAccessTo(contentKey: contentKey)
                            print("Access response: \(accessResponse)")
                        } catch(let error) {
                            print("Checking access failed: \(error.localizedDescription)")
                        }
                    }
                } label: {
                    Text("Check access")
                }
                Button {
                    Task {
                        do {
                            guard let itemOfferingId = clientConfig?.offerings[0].id else {
                                print("Fetch client config first before purchasing")
                                return
                            }
                            let purchaseReponse = try await client.purchase(itemOfferingId: itemOfferingId)
                            print("Purchase response: \(purchaseReponse)")
                            activeTab = purchaseReponse.tab
                        } catch(let error) {
                            print("Purchase failed: \(error.localizedDescription)")
                        }
                    }
                } label: {
                    Text("Purchase")
                }
                Button {
                    Task {
                        do {
                            guard let activeTab = activeTab else {
                                print("Fetch active tab and/or make a purchase before starting payment")
                                return
                            }
                            guard activeTab.status == .full else {
                                print("Fill your tab before starting payment")
                                return
                            }
                            let startPaymentResponse = try await client.startPaymentFor(tabId: activeTab.id)
                            print("Start payment response: \(startPaymentResponse)")
                        } catch(let error) {
                            print("Purchase failed: \(error.localizedDescription)")
                        }
                    }
                } label: {
                    Text("Start payment")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
