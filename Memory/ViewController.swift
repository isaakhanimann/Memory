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

let cardThickness: Float = 0.005
let animationDuration = 0.2

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    var gameAnchor: Experience.PreviewBoard!
    var cards = [CardEntity]()
    let numberOfCards = 16
    var selection1: CardEntity?
    var selection2: CardEntity?
    var raycast: ARTrackedRaycast?
    var gameIsPlaced = false
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    var role: Role!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMCConnectivity()
        setupARConfiguration()
        
        loadGameBoard()
        startTracing()
        
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
            mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "hws-kb", discoveryInfo: nil, session: mcSession)
            mcAdvertiserAssistant.start()
        } else {
            // Client Creates MCNearbyServiceBrowser and Starts Browsing
            let mcBrowser = MCBrowserViewController(serviceType: "hws-kb", session: mcSession)
            mcBrowser.delegate = self
            present(mcBrowser, animated: true)
        }
        
        // Use Multipeer session to Synchronize RealityKit scene
        arView.scene.synchronizationService = try? MultipeerConnectivityService(session: mcSession)
    }
    
    func loadGameBoard() {
        print("loadGameBoard executed")
        gameAnchor = try! Experience.loadPreviewBoard()
        arView.scene.addAnchor(gameAnchor)
    }
    
    func startTracing() {
        print("startTracing called")
        raycast = arView.trackedRaycast(from: view.center, allowing: .estimatedPlane, alignment: .horizontal) { results in
            print("raycast is updating")
            // Refine the game position with raycast update
            if let result = results.first {
                self.gameAnchor.setTransformMatrix(result.worldTransform, relativeTo: nil)
            }
        }
    }
    
    func stopTracing() {
        print("raycast has stopped")
        raycast?.stopTracking()
    }
    
    func addGameBoardOooooooooooooooold() {
//        gameAnchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.2, 0.2])
//        arView.scene.anchors.append(gameAnchor)
//
//        addCardsWithModels()
//        addOcclusionBox()
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
        
        let names = ["toy_robot_vintage", "fender_stratocaster", "tv_retro", "cup_saucer_set", "pot_plant", "flower_tulip", "trowel", "teapot"]
        
        var models = [ModelEntity]()
        for name in names {
            let newModel = try! Entity.loadModel(named: name)
            models.append(newModel)
        }
        
        for index in 0..<self.numberOfCards {
            let card = cardEntityTemplate.clone(recursive: true)
            let modelIndex = index / 2
            let modelOnCard = models[modelIndex].clone(recursive: true)
            // +0.001 so the model hovers just a little bit over the card so the occlusionBox occludes it
            modelOnCard.position = [0,cardThickness/2+0.001,0]
            card.addChild(modelOnCard)
            card.components[CardComponent.self]?.kind = names[modelIndex]
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
        for card in cards {
            print(card.card.kind)
        }
        let tapLocation = recognizer.location(in: arView)
        
        if !gameIsPlaced && role == .host {
            gameIsPlaced = true
            stopTracing()
        } else {
            // Get the entity at the location we've tapped, if one exists
            if let cardEntity = arView.entity(at: tapLocation) as? CardEntity {
                
                cardEntity.requestOwnership { [self] result in
                    if result == .granted {
                        if cardEntity.card.revealed {
                            if self.selection1 == cardEntity {
                                // even though SelectionEntity is a reference type the item in the array won't be set to nil because the items in the array can't be nil because they are non optional
                                self.selection1 = nil
                            } else if self.selection2 == cardEntity {
                                self.selection2 = nil
                            }
                            cardEntity.hide()
                        } else {
                            if self.selection1 == nil {
                                cardEntity.reveal()
                                self.selection1 = cardEntity
                            } else if self.selection2 == nil {
                                cardEntity.reveal()
                                self.selection2 = cardEntity
                            } else {
                                print("The user already has two cards selected and can therefore not reveal another card")
                                return
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 0.2, execute: self.checkSelection)
                        }
                    } else {
                        print("the user doesn't have ownership of this card. Choose a different card")
                    }
                }
                
                
            }
        }
    }
    
    func checkSelection() {
        if selection1?.card.kind == self.selection2?.card.kind {
            // remove the two cards and their children
            for child in selection1!.children where child is SelectionEntity {
                // Remove child and exit loop
                child.removeFromParent()
                break
            }
            selection1?.removeFromParent()
            selection1 = nil
            
            for child in self.selection2!.children where child is SelectionEntity {
                // Remove child and exit loop
                child.removeFromParent()
                break
            }
            self.selection2?.removeFromParent()
            self.selection2 = nil
        }
    }
    
    func placeGameBoardOooooooold(on screenLocation: CGPoint) {
        // Find position under cursor
//        guard let result = arView.raycast(from: screenLocation, allowing: .existingPlaneGeometry, alignment: .horizontal).first else { return }
//        // Create ARKit ARAnchor and add to ARSession
//        let arAnchor = ARAnchor(name: "Memory Game Board", transform: result.worldTransform)
//        arView.session.add(anchor: arAnchor)
//
//        // Create a RealityKit AnchorEntity and add to the scene
//        gameAnchor = AnchorEntity(anchor: arAnchor)
//        arView.scene.addAnchor(gameAnchor)
//        addGameBoard()
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
        
        // Don’t automatically accept ownership requests because the other user can't just hide this card again.
        synchronization?.ownershipTransferMode = .manual
        
        let selection = SelectionEntity()
        selection.position.y = cardThickness + 0.001
        
        // Remove synchronization component so the client doesn't see the SelectionEntity
        selection.synchronization = nil
        // Add as child
        addChild(selection)
        
        // transform is a value type so this copies it
        var cardTransform = self.transform
        cardTransform.rotation = simd_quatf(angle: 0, axis: [1, 0, 0])
        move(to: cardTransform, relativeTo: parent, duration: animationDuration, timingFunction: .easeInOut)
    }
    
    func hide() {
        card.revealed = false
        synchronization?.ownershipTransferMode = .autoAccept
        
        // Iterate children looking for Selection Entity
        for child in children where child is SelectionEntity {
            // Remove child and exit loop
            child.removeFromParent()
            break
        }
        
        // transform is a value type so this copies it
        var cardTransform = self.transform
        cardTransform.rotation = simd_quatf(angle: .pi, axis: [1, 0, 0])
        move(to: cardTransform, relativeTo: parent, duration: animationDuration, timingFunction: .easeInOut)
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

class SelectionEntity: Entity, HasModel {
    
    required init() {
        super.init()
        let selectionMesh = MeshResource.generatePlane(width: 0.05, depth: 0.05)
        let selectionMaterial = SimpleMaterial(color: .blue, isMetallic: false)
        model = ModelComponent(mesh: selectionMesh, materials: [selectionMaterial])
    }
}
