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
    func open(_ paymentMethodsDict: NSDictionary, configuration: NSDictionary) {
        let parser = RootConfigurationParser(configuration: configuration)
        let paymentMethods: PaymentMethods
        let clientKey: String
        do {
            paymentMethods = try parsePaymentMethods(from: paymentMethodsDict)
            clientKey = try fetchClientKey(from: parser)
        } catch {
            return sendEvent(error: error)
        }

        let apiContext: APIContext
        do {
            apiContext = try APIContext(environment: parser.environment, clientKey: clientKey)
        } catch {
            return sendEvent(error: error)
        }
        
        if (parser.payment == nil || parser.payment?.amount == nil || parser.countryCode == nil) {
            return sendEvent(error: NSError(domain: "dropin", code: 400))
        }

        let config = DropInConfigurationParser(configuration: configuration).configuration
        
        let cardConfig = CardConfigurationParser(configuration: configuration).configuration
        config.card.allowedCardTypes = cardConfig.allowedCardTypes
        config.card.billingAddress = cardConfig.billingAddress
        config.card.installmentConfiguration = cardConfig.installmentConfiguration
        config.card.koreanAuthenticationMode = cardConfig.koreanAuthenticationMode
        config.card.showsHolderNameField = cardConfig.showsHolderNameField
        config.card.showsSecurityCodeField = cardConfig.showsSecurityCodeField
        config.card.showsStorePaymentMethodField = cardConfig.showsStorePaymentMethodField
        config.card.socialSecurityNumberMode = cardConfig.socialSecurityNumberMode
        config.card.stored = cardConfig.stored

        let applePayConfig: Adyen.ApplePayComponent.Configuration
        do {
            applePayConfig = try ApplepayConfigurationParser(configuration: configuration).buildConfiguration(amount: parser.payment!.amount, countryCode: parser.countryCode!)
        } catch {
            return sendEvent(error: error)
        }
        
        config.applePay?.allowOnboarding = applePayConfig.allowOnboarding
        
        
        let adyenContext = AdyenContext(apiContext: apiContext, payment: parser.payment)

        let dropInComponentStyle = AdyenAppearanceLoader.findStyle() ?? DropInComponent.Style()
        let component = DropInComponent(paymentMethods: paymentMethods,
                                        context: adyenContext,
                                        configuration: config)
        currentComponent = component
        component.delegate = self
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
