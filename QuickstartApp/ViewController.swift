import UIKit
import AppAuth
import GTMAppAuth
import GoogleAPIClient
import GoogleAPIClientForREST

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    private let kKeychainItemName = "SeatingChartIOS"
    private let kClientID = "get your own u scrub"
    private let kRedirectURI = "get your own u scrub"
    //private let kAuthorizerKey = "authorization"
    private let kIssuer = "https://accounts.google.com"

    var authState: OIDAuthState?
    var fileList: [GTLDriveFile] = []
    var currentFile: GTLDriveFile?
    @IBOutlet weak var fileListView: UIPickerView!
    
    private let service = GTLRSheetsService()
    private let driveService = GTLServiceDrive()
    let appDelegate = (UIApplication.shared.delegate! as! AppDelegate)
    var authorization: GTMAppAuthFetcherAuthorization?
    var kExampleAuthorizerKey = "authorization"
    let userDefaults = UserDefaults.standard
    
    @IBOutlet weak var textView: UITextView!
    
    // When the view loads, create necessary subviews
    // and initialize the Google Sheets API service
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        fileListView.dataSource = self
        fileListView.delegate = self
        
        loadAuth()
        
    }
    
    //dataSources
    func numberOfComponents(in: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return fileList.count
    }
    //delegates
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        
        return fileList[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        //on selection
        if row > 0
        {
            currentFile = fileList[row]
        }
    }
    //rainbow
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel = view as! UILabel!
        if view == nil {  //if no label there yet
            pickerLabel = UILabel()
            //color the label's background
            let hue = CGFloat(row)/CGFloat(fileList.count)
            pickerLabel?.backgroundColor = UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        }
        let titleData = fileList[row].name
        let myTitle = NSAttributedString(string: titleData!, attributes: [NSFontAttributeName:UIFont(name: "Arial", size: 16.0)!,NSForegroundColorAttributeName:UIColor.black])
        pickerLabel!.attributedText = myTitle
        pickerLabel!.textAlignment = .center
        return pickerLabel!
        
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
    
    func saveAuth()
    {
        if authorization != nil && (authorization?.canAuthorize())! {
            let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: authorization!)
            userDefaults.set(encodedData, forKey: kExampleAuthorizerKey)
            userDefaults.synchronize()
        }
        else {
            userDefaults.removeObject(forKey: kExampleAuthorizerKey)
        }
    }
    
    func loadAuth()
    {
        if let _ = userDefaults.object(forKey: kExampleAuthorizerKey)
        {
            let decoded = userDefaults.object(forKey: kExampleAuthorizerKey) as! Data
            let testAuth = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! GTMAppAuthFetcherAuthorization
            authorization = testAuth
            service.authorizer = authorization
            driveService.authorizer = authorization
        }
    }
    
    @IBAction func listSheet(_ sender: Any)
    {
        if let _ = service.authorizer {
            listDocuments()
            
        }
        else
        {
            auth()
        }
    }
    @IBAction func listSheetInfo(_ sender: Any)
    {
        if(currentFile != nil)
        {
            let range = "Sheet1!A1:C3"
            let query = GTLRSheetsQuery_SpreadsheetsValuesGet.query(withSpreadsheetId: currentFile!.identifier, range: range)
            service.executeQuery(query, delegate: self, didFinish: #selector(ViewController.displaySheetInfo(ticket:finishedWithObject:error:)))
        }
    }
    
    func displaySheetInfo(ticket: GTLRServiceTicket,
                          finishedWithObject result : GTLRSheets_ValueRange,
                          error : NSError?)
    {
        if let x = result.values?.description
        {
            logMessage(x)
        }
        else
        {
            logMessage("[]")
        }
    }
    
    @IBAction func updateWithData(_ sender: Any)
    {
        if(currentFile != nil)
        {
            let data = GTLRSheets_ValueRange()
            data.range = "Sheet1!A1:C3"
            data.majorDimension = kGTLRSheets_DimensionRange_Dimension_Rows
            data.values = [["Josh", "Connor", "Steve-O"],["Lead Programmer", "Code Lackey", "Circle Clicker"],["AR10","AR4","AR11"]]
            
            let query = GTLRSheetsQuery_SpreadsheetsValuesUpdate.query(withObject: data, spreadsheetId: currentFile!.identifier, range: data.range!)
            query.valueInputOption = kGTLRSheets_BatchUpdateValuesRequest_ValueInputOption_UserEntered
            service.executeQuery(query, delegate: self, didFinish: nil)
            
        }
    }
    
    @IBAction func updateWithPotatoes(_ sender: Any)
    {
        if(currentFile != nil)
        {
            let data = GTLRSheets_ValueRange()
            data.range = "Sheet1!A1:C3"
            data.majorDimension = kGTLRSheets_DimensionRange_Dimension_Rows
            data.values = [["potatoe", "potatoe", "potatoe"],["potatoe", "potatoe", "potatoe"],["potatoe", "potatoe", "potatoe"]]
            
            let query = GTLRSheetsQuery_SpreadsheetsValuesUpdate.query(withObject: data, spreadsheetId: currentFile!.identifier, range: data.range!)
            query.valueInputOption = kGTLRSheets_BatchUpdateValuesRequest_ValueInputOption_UserEntered
            service.executeQuery(query, delegate: self, didFinish: nil)
            
        }
    }
    
    //unused
    func displayUpdateInfo(ticket: GTLRServiceTicket,
                           finishedWithObject result: GTLRSheets_UpdateValuesResponse,
                           error: NSError?) {
        Swift.print(result)
    }

    
    
    // Lists Documents
    func listDocuments() {
        logMessage("Getting sheet data...")
        let query = GTLQueryDrive.queryForFilesList()!
        query.pageSize = 1000
        query.fields = "nextPageToken, files(mimeType, id, name)"
        query.orderBy = "modifiedByMeTime desc,name"
        driveService.executeQuery(
            query,
            delegate: self,
            didFinish: #selector(ViewController.listDocuments(ticket:finishedWithObject:error:))
        )
    }
    
    // Parse results and display
    func listDocuments(ticket : GTLServiceTicket,
                                 finishedWithObject response : GTLDriveFileList,
                                 error : NSError?) {
        if let error = error {
            logMessage("Error: " + error.localizedDescription)
            return
        }
        
        
        var filesString = ""
        
        if let files = response.files, !files.isEmpty
        {
            fileList = files as! [GTLDriveFile]
            filesString += "Files:\n"
            for file in fileList
            {
                if file.mimeType == "application/vnd.google-apps.spreadsheet" && file.name.contains("[SCD]")
                {
                    filesString += "\(file.name) (\(file.identifier))\n"
                }
                else
                {
                    if let index = fileList.index(of: file) {
                        fileList.remove(at: index)
                    }
                }
 
            }
        } else
        {
            filesString = "No files found."
        }
        
        logMessage(filesString)
        currentFile = fileList[0]
        fileListView.reloadAllComponents() //update spinner
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
            let scopes = [kGTLRAuthScopeSheetsSpreadsheets, kGTLRAuthScopeDrive]
            let request = OIDAuthorizationRequest(configuration: configuration!, clientId: self.kClientID, scopes: scopes, redirectURL: redirectURI, responseType: OIDResponseTypeCode, additionalParameters: nil)
            // performs authentication request
            self.logMessage("Initiating authorization request with scope: " + request.scope!.description)

            self.appDelegate.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: self, callback: {(_ authState: OIDAuthState?, _ error: Error?) -> Void in
                if authState != nil {
                    self.logMessage("Got authorization tokens. Access token: " + (authState?.lastTokenResponse?.accessToken!.description)!)
                    self.authorization = GTMAppAuthFetcherAuthorization(authState: authState!)
                    self.service.authorizer = self.authorization
                    self.driveService.authorizer = self.authorization
                    
                    self.saveAuth()
                }
                else {
                    self.logMessage("Authorization error: " + (error?.localizedDescription.description)!)
                }
            })
        })
    }
}
