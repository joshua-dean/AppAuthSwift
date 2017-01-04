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
    
    private let service = GTLRSheetsService()
    let appDelegate = (UIApplication.shared.delegate! as! AppDelegate)
    var authorization: GTMAppAuthFetcherAuthorization?
    
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
    
    @IBAction func listSheet(_ sender: Any)
    {
        if let _ = service.authorizer {
            listMajors()
        }
        else
        {
            auth()
        }
    }
    
    // Display (in the UITextView) the names and majors of students in a sample
    // spreadsheet:
    // https://docs.google.com/spreadsheets/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit
    func listMajors() {
        logMessage("Getting sheet data...")
        let spreadsheetId = "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms"
        let range = "Class Data!A2:E"
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet.query(withSpreadsheetId: spreadsheetId, range:range)

        service.executeQuery(query, delegate: self, didFinish: #selector(ViewController.displayResultWithTicket(ticket:finishedWithObject:error:)))
        
    }

    // Process the response and display output
    func displayResultWithTicket(ticket: GTLRServiceTicket,
                                 finishedWithObject result : GTLRSheets_ValueRange,
                                 error : NSError?) {
        
        if let error = error {
            logMessage("Error" + error.localizedDescription)
            return
        }
        
        var majorsString = ""
        let rows = result.values!
        
        if rows.isEmpty {
            logMessage("No data found.")
            return
        }
        
        majorsString += "Name, Major:\n"
        for row in rows {
            let name = row[0]
            let major = row[4]
            
            majorsString += "\(name), \(major)\n"
        }
        
        logMessage(majorsString)
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
            let scopes = [kGTLRAuthScopeSheetsSpreadsheets]
            let request = OIDAuthorizationRequest(configuration: configuration!, clientId: self.kClientID, scopes: scopes, redirectURL: redirectURI, responseType: OIDResponseTypeCode, additionalParameters: nil)
            // performs authentication request
            self.logMessage("Initiating authorization request with scope: " + request.scope!.description)

            self.appDelegate.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: self, callback: {(_ authState: OIDAuthState?, _ error: Error?) -> Void in
                if authState != nil {
                    self.logMessage("Got authorization tokens. Access token: " + (authState?.lastTokenResponse?.accessToken!.description)!)
                    self.authorization = GTMAppAuthFetcherAuthorization(authState: authState!)
                    self.service.authorizer = self.authorization
                }
                else {
                    self.logMessage("Authorization error: " + (error?.localizedDescription.description)!)
                }
            })
        })
    }
}
