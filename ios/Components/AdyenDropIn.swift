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

    private var session: AdyenSession? {
        currentSession as? AdyenSession
    }
    
    @objc
    func hide(_ success: NSNumber, event: NSDictionary) {
        dismiss(success.boolValue)
    }

    @objc
    func open(_ configuration: NSDictionary) {
        let parser = RootConfigurationParser(configuration: configuration)
        let sessionConfigurationParser = SessionConfigurationParser(configuration)
        let clientKey: String
        do {
            clientKey = try fetchClientKey(from: parser)
        } catch {
            return sendEvent(error: error)
        }

        let apiContext = APIContext(environment: parser.environment, clientKey: clientKey)
        let amount = sessionConfigurationParser.amount
        let payment = Payment(amount: amount, currencyCode: sessionConfigurationParser.countryCode)

        let adyenContext = AdyenContext(apiContext: apiContext, payment: payment)

        let adyenConfiguration = sessionConfigurationParser.configuration(adyenContext)

        AdyenSession.initialize(with: configuration, 
                                delegate: self, 
                                presentationDelegate: self) { 
                                [weak self] result in
                                    switch result {
                                    case let .success(session):
                                        //Store the session object.
                                        self?.session = session
                                    case let .failure(error):
                                        //Handle the error. 
                                        sendEvent(error)
                                    }
        }

        let dropInConfiguration = DropInConfigurationParser(configuration: configuration).configuration(adyenContext: adyenContext)
        dropInConfiguration.card = CardConfigurationParser(configuration: configuration).configuration

        dropInConfiguration.payment = payment
        (try? ApplepayConfigurationParser(configuration: configuration).buildConfiguration(amount: payment.amount)).map {
            dropInConfiguration.applePay = $0
        }

        let dropInComponentStyle = AdyenAppearanceLoader.findStyle() ?? DropInComponent.Style()
        let component = DropInComponent(paymentMethods: session.sessionContext.paymentMethods,
                                        configuration: dropInConfiguration,
                                        style: dropInComponentStyle)
        currentComponent = component
        component.delegate = session
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

    func didSubmit(_ data: PaymentComponentData,
                   for paymentMethod: PaymentMethod,
                   from component: DropInComponent) {
        sendEvent(event: .didSubmit, body: data.jsonObject)
    }

    func didProvide(_ data: ActionComponentData, from component: DropInComponent) {
        sendEvent(event: .didProvide, body: data.jsonObject)
    }

    func didComplete(from component: DropInComponent) {
        sendEvent(event: .didComplete, body: nil)
    }

    func didFail(with error: Error, from component: DropInComponent) {
        sendEvent(error: error)
    }

}
