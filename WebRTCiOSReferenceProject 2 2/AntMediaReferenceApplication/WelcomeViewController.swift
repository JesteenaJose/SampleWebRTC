//
//  ViewController.swift
//  AntMediaReferenceApplication
//


import UIKit
import WebRTCiOSSDK

class WelcomeViewController: UIViewController {
    
    @IBOutlet weak var actionContainer: UIView! {
        didSet {
            self.actionContainer.alpha = 0
        }
    }
    @IBOutlet weak var roomField: UITextField!
    @IBOutlet weak var modeSelection: UISegmentedControl!
    @IBOutlet weak var connectButton: UIButton!
   
    var clientUrl: String!
    var clientRoom: String!
    var clientToken: String!
    var isConnected = false
    var tapGesture: UITapGestureRecognizer!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setGesture()
        
     
        Defaults[.server]  = "https://test.antmedia.io:5443/WebRTCAppEE/websocket"
        
        UIView.animate(withDuration: 0.5, delay: 1.0, options: .curveEaseOut, animations: {
           
            self.view.layoutIfNeeded()
        }, completion: { (completed) in
            UIView.animate(withDuration: 0.5, animations: {
                self.actionContainer.alpha = 1
                self.view.layoutIfNeeded()
            })
        })
    }
    override func viewDidLoad() {
        Defaults[.server]  = "https://test.antmedia.io:5443/WebRTCAppEE/websocket"
    }
    @IBAction func connectButton(_ sender: UIButton ) {
        if roomField.text!.count == 0 {
            AlertHelper.getInstance().show("Caution!", message: "Please fill room field")
        } else if (Defaults[.server] ?? "").count < 2 {
            AlertHelper.getInstance().show("Caution!", message: "Please set server ip")
        } else {
            self.clientUrl = Defaults[.server]!
            print(roomField.text)
            self.clientRoom = roomField.text!
     
            self.clientToken = ""
          
            
            self.showVideo()
        }
    }
    
    @IBAction func refreshTapped(_ sender: UIButton) {
        if let room = Defaults[.room] {
            self.roomField.text = room
        }
    }
    

    
    private func setGesture() {
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(WelcomeViewController.toggleContainer))
        self.tapGesture.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapGesture)
    }
    
    private func getMode() -> AntMediaClientMode {
        switch self.modeSelection.selectedSegmentIndex {
            case 0:
                return AntMediaClientMode.join
            case 1:
                return AntMediaClientMode.play
            case 2:
                return AntMediaClientMode.publish
            case 3:
                return AntMediaClientMode.conference
            default:
                return AntMediaClientMode.join
        }
    }
    
    @objc private func toggleContainer() {
        self.view.endEditing(true)
    }
    
    private func showVideo()
    {
        if self.getMode() != AntMediaClientMode.conference {
            let controller = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Video") as! VideoViewController
            controller.clientUrl = self.clientUrl
            controller.clientStreamId = self.clientRoom
            controller.clientToken = self.clientToken
            controller.clientMode = self.getMode()
            self.show(controller, sender: nil)
        }
        else {
            let controller = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Conference") as! ConferenceViewController;
            controller.clientUrl = self.clientUrl;
            controller.roomId = self.clientRoom;
            
           self.show(controller, sender: nil)
        }
         
    }
}

