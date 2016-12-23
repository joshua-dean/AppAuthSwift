import GoogleAPIClientForREST
import UIKit
import GTMAppAuth
import AppAuth

class ViewController: UIViewController {
    
    private let kKeychainItemName = "SeatingChartIOS"
    private let kClientID = "974204174547-p3vuej87lqp38nkvmjgcb0askle6cqj7.apps.googleusercontent.com"
    private let kRedirectURI = "com.googleusercontent.apps.974204174547-p3vuej87lqp38nkvmjgcb0askle6cqj7:/oauthredirect"
    //private let kAuthorizerKey = "authorization"
    private let kIssuer = "https://accounts.google.com"

    var authState: OIDAuthState?
    
    
    @IBOutlet weak var textView: UITextView!
    
    // When the view loads, create necessary subviews
    // and initialize the Google Sheets API service
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func logMessage(_ message: String)
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm:ss"
        let dateString = dateFormatter.string(from: Date())
        textView.text = textView.text + "\n" + dateString + ": " + message
    }
    @IBAction func authorize(_ sender: Any)
    {
        auth()
    }

    func auth()
    {
        //need this potatoe
        let issuer = URL(string: kIssuer)!
        let redirectURI = URL(string: kRedirectURI)!

        logMessage("Fetching configuration for issuer: " + issuer.description)
        // discovers endpoints
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer, completion: {(_ configuration: OIDServiceConfiguration?, _ error: Error?) -> Void in
            if configuration == nil {
                self.logMessage("Error retrieving discovery document: " + (error?.localizedDescription)!)
                return
            }
            self.logMessage("Got configuration: " + configuration!.description)
            // builds authentication request
            let request = OIDAuthorizationRequest(configuration: configuration!, clientId: self.kClientID, scopes: [OIDScopeOpenID, OIDScopeProfile], redirectURL: redirectURI, responseType: OIDResponseTypeCode, additionalParameters: nil)
            // performs authentication request
            let appDelegate = (UIApplication.shared.delegate! as! AppDelegate)
            self.logMessage("Initiating authorization request with scope: " + request.scope!.description)

            appDelegate.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: self, callback: {(_ authState: OIDAuthState?, _ error: Error?) -> Void in
                if authState != nil {
                    self.logMessage("Got authorization tokens. Access token: " + (authState?.lastTokenResponse?.accessToken!.description)!)
                }
                else {
                    self.logMessage("Authorization error: " + (error?.localizedDescription.description)!)
                }
            })
        })
    }
}
