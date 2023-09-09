
import Adyen

public struct SessionConfigurationParser {
  private var dict: [String:Any]

  public init(configuration: NSDictionary) {
      guard let config = configuration as? [String: Any] else {
          self.dict = [:]
          return
      }
      if let configurationNode = config[SessionKeys.rootKey] as? [String: Any] {
        self.dict = configurationNode
      } else {
          self.dict = config
      }
  }

  public var amount: Amount? {
      guard let paymentObject = dict[SessionKeys.amount] as? [String: Any],
          let paymentAmount = paymentObject[AmountKeys.value] as? Int,
            let currencyCode = paymentObject[AmountKeys.currency] as? String
    else {
        return nil
    }

    return Amount(value: paymentAmount, currencyCode: currencyCode)
  }

  public var countryCode: String? {
    return dict[SessionKeys.countryCode] as? String
  }



  public func configuration(adyenContext: AdyenContext) throws -> AdyenSession.Configuration {
      if (dict[SessionKeys.id] == nil || dict[SessionKeys.sessionData] == nil) {
          throw NSError(domain: "session", code: 400, userInfo: [ NSLocalizedDescriptionKey: "missing session.id or session.sessionData"])
      }
      return .init(sessionIdentifier: dict[SessionKeys.id]! as! String,
                   initialSessionData: dict[SessionKeys.sessionData]! as! String,
                   context: adyenContext
                 )
  }
}
