//
// Copyright (c) 2022 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//


import Adyen
import Foundation
import PassKit
import React

@objc(AdyenApplePay)
final internal class ApplePayComponent: BaseModule {
    
    override func supportedEvents() -> [String]! { super.supportedEvents() }

    @objc
    func hide(_ success: NSNumber, event: NSDictionary) {
        dismiss(success.boolValue)
    }

    @objc
    func open(_ configuration: NSDictionary) {
        let parser = RootConfigurationParser(configuration: configuration)
        let sessionConfigurationParser = SessionConfigurationParser(configuration: configuration)
        let clientKey: String
        do {
            clientKey = try fetchClientKey(from: parser)
        } catch {
            return sendEvent(error: error)
        }
        

        let apiContext = try! APIContext(environment: parser.environment, clientKey: clientKey)
        let amount = sessionConfigurationParser.amount!
        let payment = Payment(amount: amount, countryCode: sessionConfigurationParser.countryCode!)

        let adyenContext = AdyenContext(apiContext: apiContext, payment: payment)

        let adyenConfiguration: AdyenSession.Configuration
        do {
            adyenConfiguration = try sessionConfigurationParser.configuration(adyenContext: adyenContext)
        } catch {
            return sendEvent(error: error)
        }

        AdyenSession.initialize(with: adyenConfiguration,
                                delegate: self,
                                presentationDelegate: self) {
                                [weak self] result in
                                    switch result {
                                    case let .success(session):
                                        //Store the session object.
                                        self?.currentSession = session
                                    case let .failure(error):
                                        //Handle the error.
                                        self?.sendEvent(error: error)
                                    }
        }
        
        if (currentSession == nil) {
            return
        }
        
        guard let paymentMethods = self.currentSession?.sessionContext.paymentMethods,
              let paymentMethod = paymentMethods.paymentMethod(ofType: ApplePayPaymentMethod.self) else {
            return sendEvent(error: NSError(domain: "applepay", code: 400, userInfo: [NSLocalizedDescriptionKey: "missing apple pay payment method"]))
        }
         
        
        let applePayConfiguration: Adyen.ApplePayComponent.Configuration
        do { applePayConfiguration = try ApplepayConfigurationParser(configuration: configuration).buildConfiguration(amount: payment.amount, countryCode: sessionConfigurationParser.countryCode!)
        } catch {
            return sendEvent(error: error)
        }

        let component: Adyen.ApplePayComponent
        do {
            component = try Adyen.ApplePayComponent(paymentMethod: paymentMethod, context: adyenContext, configuration: applePayConfiguration)
        } catch {
            return sendEvent(error: error)
        }
        currentComponent = component
        component.delegate = currentSession
        present(component: component)
        
    }

}

extension ApplePayComponent: PaymentComponentDelegate {

    internal func didSubmit(_ data: PaymentComponentData, from component: PaymentComponent) {
        sendEvent(event: .didSubmit, body: data.jsonObject)
    }

    internal func didFail(with error: Error, from component: PaymentComponent) {
        sendEvent(error: error)
    }

}

extension ApplePayComponent: AdyenSessionDelegate {
    func didComplete(with resultCode: Adyen.SessionPaymentResultCode, component: Adyen.Component, session: Adyen.AdyenSession) {
        sendEvent(event: .didComplete, body: nil)
    }
    
    func didFail(with error: Error, from component: Adyen.Component, session: Adyen.AdyenSession) {
        sendEvent(error: error)
    }
}
