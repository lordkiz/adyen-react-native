//
// Copyright (c) 2022 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Adyen

public struct RootConfigurationParser {

    private var configuration: [String:Any]

    public init(configuration: NSDictionary) {
        guard let configuration = configuration as? [String: Any] else {
            self.configuration = [:]
            return
        }
        self.configuration = configuration
    }

    public var environment: Environment {
        guard let environmentString = configuration[Keys.environment] as? String else {
            return .test
        }
        return Environment.parse(environmentString)
    }

    public var clientKey: String? {
        return configuration[Keys.clientKey] as? String
    }
    
    public var countryCode: String? {
        return configuration[Keys.countryCode] as? String
    }

    public var amount: Amount? {
        guard let paymentObject = configuration[Keys.amount] as? [String: Any],
              let paymentAmount = paymentObject[Keys.value] as? Int,
              let currencyCode = paymentObject[Keys.currency] as? String
        else {
            return nil
        }

        return Amount(value: paymentAmount, currencyCode: currencyCode)
    }

    public var payment: Payment? {
        guard let amount = self.amount,
              let countryCode = configuration[Keys.countryCode] as? String
        else {
            return nil
        }

        return Payment(amount: amount, countryCode: countryCode)
    }

    public var shopperLocale: Locale? {
        guard let shopperLocaleString = configuration[Keys.shopperLocale] as? String else {
            return nil
        }

        return Locale(identifier: shopperLocaleString)
    }

}
