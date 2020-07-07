//
//  ViewController.swift
//  Memory
//
//  Created by Isaak Hanimann on 03.07.20.
//  Copyright © 2020 Isaak Hanimann. All rights reserved.
//

import UIKit
import RealityKit
import Combine
import MultipeerConnectivity
import ARKit

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    var gameAnchor: AnchorEntity!
    var cards = [Entity]()
    let numberOfCards = 16
    let cardThickness: Float = 0.005
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    var role: Role!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setupMCConnectivity()
        setupARConfiguration()
        
        addGameBoard()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        arView.addGestureRecognizer(tapGestureRecognizer)
        
    }
    
    func setupARConfiguration() {
        arView.automaticallyConfigureSession = false
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.isCollaborationEnabled = true
        config.environmentTexturing = .automatic
        arView.session.run(config)
    }
    
    func setupMCConnectivity() {
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        print("my peerID is: \(String(describing: peerID))")
        
        role = peerID.displayName == "Isaaaaaaaaaaaaaaaaaaaaaaaaaaaak‘s iPhone" ? .host : .client
        
        if role == .host {
            // Host Creates MCNearbyServiceAdvertiser and Starts Advertising
        } else {
            // Client Creates MCNearbyServiceBrowser and Starts Browsing
        }
        
        // Use Multipeer session to Synchronize RealityKit scene
        arView.scene.synchronizationService = try? MultipeerConnectivityService(session: mcSession)
        
        
    }
    
    func addGameBoard() {
        gameAnchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.2, 0.2])
        arView.scene.anchors.append(gameAnchor)
        
        addCardsWithModels()
        addOcclusionBox()
    }
    
    
    func addCardsWithModels() {
        
        let cardModelEntity = try! Entity.loadModel(named: "plate")

        let cardEntityTemplate = CardEntity()
        cardEntityTemplate.model = cardModelEntity.model
        cardEntityTemplate.collision = cardModelEntity.collision
        cardEntityTemplate.card = CardComponent()
        // Generate collision shapes for the card so we can interact with it
        cardEntityTemplate.generateCollisionShapes(recursive: true)
        cardEntityTemplate.transform.rotation = simd_quatf(angle: .pi, axis: [1,0,0])
            
        let models = [try! Entity.loadModel(named: "toy_robot_vintage"),try! Entity.loadModel(named: "fender_stratocaster"),try! Entity.loadModel(named: "tv_retro"),try! Entity.loadModel(named: "cup_saucer_set"),try! Entity.loadModel(named: "pot_plant"),try! Entity.loadModel(named: "flower_tulip"),try! Entity.loadModel(named: "trowel"),try! Entity.loadModel(named: "teapot")]
        
        for index in 0..<self.numberOfCards {
            let card = cardEntityTemplate.clone(recursive: true)
            let modelIndex = index / 2
            let modelOnCard = models[modelIndex].clone(recursive: true)
            // +0.001 so the model hovers just a little bit over the card so the occlusionBox occludes it
            modelOnCard.position = [0,cardThickness/2+0.001,0]
            card.addChild(modelOnCard)
            card.components[CardComponent.self]?.kind = modelOnCard.name
            self.cards.append(card)
        }

        self.cards.shuffle()

        for (index, card) in self.cards.enumerated() {
            let x = Float(index % 4) - 1.5
            let z = Float(index / 4) - 1.5
            // Set the position of the card
            card.position = [x * 0.1, 0, z * 0.1]
            // Add the card to the anchor
            self.gameAnchor.addChild(card)
        }
    }
    
    
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        let tapLocation = recognizer.location(in: arView)
        // Get the entity at the location we've tapped, if one exists
        if let cardEntity = arView.entity(at: tapLocation) as? CardEntity {
            if cardEntity.card.revealed {
                cardEntity.hide()
            } else {
                cardEntity.reveal()
            }
        }
    }
    
    func addOcclusionBox() {
        let boxSize: Float = 0.5
        let boxMesh = MeshResource.generateBox(size: boxSize)
        let boxMaterial = OcclusionMaterial()
        let occlusionBox = ModelEntity(mesh: boxMesh, materials: [boxMaterial])
        occlusionBox.position.y = -boxSize/2 - cardThickness/2
        gameAnchor.addChild(occlusionBox)
    }

}

extension ViewController: MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")

        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")

        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
        default:
            print("Unknown case of state")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    
}


// Declare custom entity with the Model, Collision and Card Component
class CardEntity: Entity, HasModel, HasCollision {
    
    // for convenient access to card state
    public var card: CardComponent {
        get { return components[CardComponent.self] ?? CardComponent() }
        set { components[CardComponent.self] = newValue }
    }
    
    func reveal() {
        card.revealed = true
        
        // transform is a value type so this copies it
        var cardTransform = self.transform
        cardTransform.rotation = simd_quatf(angle: 0, axis: [1, 0, 0])
        move(to: cardTransform, relativeTo: parent, duration: 0.3, timingFunction: .easeInOut)
    }
    
    func hide() {
        card.revealed = false
        
        // transform is a value type so this copies it
        var cardTransform = self.transform
        cardTransform.rotation = simd_quatf(angle: .pi, axis: [1, 0, 0])
        move(to: cardTransform, relativeTo: parent, duration: 0.3, timingFunction: .easeInOut)
    }
}


struct CardComponent: Component, Codable {
    var revealed = false
    var kind = ""
}

enum Role {
    case host
    case client
}
