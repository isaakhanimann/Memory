//
//  ViewController.swift
//  Memory
//
//  Created by Isaak Hanimann on 03.07.20.
//  Copyright © 2020 Isaak Hanimann. All rights reserved.
//

import UIKit
import RealityKit
import ARKit

let cardThickness: Float = 0.005
let animationDuration = 0.2

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    var placementHandler = PlacementHandler()
    var placedEntity: Entity?
    
    var cards = [CardEntity]()
    let numberOfCards = 16
    var selection1: CardEntity?
    var selection2: CardEntity?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpARView()
        
        placementHandler.handlePlacing(on: arView) { entity in
            self.placedEntity = entity
        }
                
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        arView.addGestureRecognizer(tapGestureRecognizer)
        
    }
    
    func setUpARView() {
        arView.automaticallyConfigureSession = false
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.isCollaborationEnabled = true
        config.environmentTexturing = .automatic
        arView.session.run(config)
    }
    

    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        
        let tapLocation = recognizer.location(in: arView)
        
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
    
    func checkSelection() {
        if selection1?.card.kind == self.selection2?.card.kind {
            selection1?.removeFromParent()
            selection1 = nil
            self.selection2?.removeFromParent()
            self.selection2 = nil
        }
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
        move(to: cardTransform, relativeTo: parent, duration: animationDuration, timingFunction: .easeInOut)
    }
    
    func hide() {
        card.revealed = false
        
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
