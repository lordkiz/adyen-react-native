
import Adyen

public struct SessionConfigurationParser {
  private var dict: [String:Any]

  public init(configuration: NSDictionary) {
      guard let configuration = configuration as? [String: Any] else {
          self.dict = [:]
          return
      }
      if let configurationNode = configuration[SessionKeys.rootKey] as? [String: Any] {
        self.dict = configurationNode
      }
  }

  public var amount: Amount? {
    guard let paymentObject = configuration[.amount] as? SessionKeys.amount,
          let paymentAmount = paymentObject[SessionKeys.amount.value] as? Int,
          let currencyCode = paymentObject[SessionKeys.amount.currency] as? String
    else {
        return nil
    }

    return Amount(value: paymentAmount, currencyCode: currencyCode)
  }

  public var countryCode: String? = {
    return dict[SessionKeys.countryCode] as? String
  }



  public func configuration(adyenContext: AdyenContext) -> AdyenSession.Configuration {
    return .init(sessionIdentifier: dict[SessionKeys.id] as? String ?? .none,
                 initialSessionData: dict[SessionKeys.sessionData] as? String ?? .none,
                 adyenContext: adyenContext)
  }
}