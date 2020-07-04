//
//  ViewController.swift
//  Memory
//
//  Created by Isaak Hanimann on 03.07.20.
//  Copyright © 2020 Isaak Hanimann. All rights reserved.
//

import UIKit
import RealityKit

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let anchorEntity = AnchorEntity(plane: .horizontal, minimumBounds: [0.2, 0.2])
        
        arView.scene.anchors.append(anchorEntity)
        
        addCards(to: anchorEntity)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        arView.addGestureRecognizer(tapGestureRecognizer)
        
    }
    
    func addCards(to anchorEntity: AnchorEntity) {
        var cards = [Entity]()
        let numberOfCards = 16
        
        let cardTemplate = try! Entity.loadModel(named: "plate")
        // Generate collision shapes for the card so we can interact with it
        cardTemplate.generateCollisionShapes(recursive: true)
        
        for index in 0..<numberOfCards {
            let card = cardTemplate.clone(recursive: true)
            // Give the card a name so we'll know what we're interacting with
            let firstIndex = index / 2
            let secondIndex = index % 2
            card.name = "card\(firstIndex)\(secondIndex)"
            cards.append(card)
        }
        
        cards.shuffle()
        
        for (index, card) in cards.enumerated() {
            let x = Float(index % 4) - 1.5
            let z = Float(index / 4) - 1.5
            // Set the position of the card
            card.position = [x * 0.1, 0, z * 0.1]
            // Add the card to the anchor
            anchorEntity.addChild(card)
        }
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        let tapLocation = recognizer.location(in: arView)
        // Get the entity at the location we've tapped, if one exists
        if let card = arView.entity(at: tapLocation) {
            var cardTransform = card.transform
            cardTransform.rotation = simd_quatf(angle: .pi, axis: [1,0,0])
            card.move(to: cardTransform, relativeTo: card.parent, duration: 0.3, timingFunction: .easeInOut)
        }
        
        
        
        
    }
}
