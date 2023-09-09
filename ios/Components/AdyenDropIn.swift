//
// Copyright (c) 2021 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Adyen
import Foundation
import PassKit
import React

@objc(AdyenDropIn)
final internal class AdyenDropIn: BaseModule {

    override func supportedEvents() -> [String]! { super.supportedEvents() }
    
    private var dropInComponent: DropInComponent? {
        currentComponent as? DropInComponent
    }
    
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

        let adyenConfiguration = try! sessionConfigurationParser.configuration(adyenContext: adyenContext)

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

        let dropInComponentStyle = AdyenAppearanceLoader.findStyle() ?? DropInComponent.Style()
        let dropInConfiguration = DropInConfigurationParser(configuration: configuration).configuration()
        dropInConfiguration.style = dropInComponentStyle
        // config for cards
        dropInConfiguration.card = CardConfigurationParser(configuration: configuration).configuration
        // config for applepay
        (try? ApplepayConfigurationParser(configuration: configuration).buildConfiguration(amount: payment.amount, countryCode: sessionConfigurationParser.countryCode!)).map {
            dropInConfiguration.applePay = $0
        }

        let component = DropInComponent(paymentMethods: currentSession!.sessionContext.paymentMethods,
                                        context: adyenContext,
                                        configuration: dropInConfiguration
                                        )
        currentComponent = component
        component.delegate = currentSession
        present(component: component)
    }

    @objc
    func handle(_ dictionary: NSDictionary) {
        let action: Action
        do {
            action = try parseAction(from: dictionary)
        } catch {
            return sendEvent(error: error)
        }

        DispatchQueue.main.async { [weak self] in
            self?.dropInComponent?.handle(action)
        }
    }

}

extension AdyenDropIn: DropInComponentDelegate {
    func didSubmit(_ data: Adyen.PaymentComponentData, from component: Adyen.PaymentComponent, in dropInComponent: Adyen.AnyDropInComponent) {
        sendEvent(event: .didSubmit, body: data.jsonObject)
    }
    
    func didFail(with error: Error, from component: Adyen.PaymentComponent, in dropInComponent: Adyen.AnyDropInComponent) {
        sendEvent(error: error)
    }
    
    func didProvide(_ data: Adyen.ActionComponentData, from component: Adyen.ActionComponent, in dropInComponent: Adyen.AnyDropInComponent) {
        sendEvent(event: .didProvide, body: data.jsonObject)
    }
    
    func didComplete(from component: Adyen.ActionComponent, in dropInComponent: Adyen.AnyDropInComponent) {
        sendEvent(event: .didComplete, body: nil)
    }
    
    func didFail(with error: Error, from component: Adyen.ActionComponent, in dropInComponent: Adyen.AnyDropInComponent) {
        sendEvent(error: error)
    }
    
    func didFail(with error: Error, from dropInComponent: Adyen.AnyDropInComponent) {
        sendEvent(error: error)
    }

}

extension AdyenDropIn: AdyenSessionDelegate {
    func didComplete(with resultCode: Adyen.SessionPaymentResultCode, component: Adyen.Component, session: Adyen.AdyenSession) {
        sendEvent(event: .didComplete, body: nil)
    }
    
    func didFail(with error: Error, from component: Adyen.Component, session: Adyen.AdyenSession) {
        sendEvent(error: error)
    }
    
}
