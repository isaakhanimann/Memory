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

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    var gameAnchor: AnchorEntity!
    var cards = [Entity]()
    let numberOfCards = 16
    let cardThickness: Float = 0.005

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gameAnchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.2, 0.2])
        
        arView.scene.anchors.append(gameAnchor)
        
        addCardsWithModels()
        addOcclusionBox()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        arView.addGestureRecognizer(tapGestureRecognizer)
        
    }
    
    
    func addCardsWithModels() {
        
        let cardTemplate = try! Entity.loadModel(named: "plate")
        // Generate collision shapes for the card so we can interact with it
        cardTemplate.generateCollisionShapes(recursive: true)
        cardTemplate.transform.rotation = simd_quatf(angle: .pi, axis: [1,0,0])


        let models = [try! Entity.loadModel(named: "toy_robot_vintage"),try! Entity.loadModel(named: "fender_stratocaster"),try! Entity.loadModel(named: "tv_retro"),try! Entity.loadModel(named: "cup_saucer_set"),try! Entity.loadModel(named: "pot_plant"),try! Entity.loadModel(named: "flower_tulip"),try! Entity.loadModel(named: "trowel"),try! Entity.loadModel(named: "teapot")]
        
        for index in 0..<self.numberOfCards {
            let card = cardTemplate.clone(recursive: true)
            // card00 and card01 correspond to each other
            let firstIndex = index / 2
            let secondIndex = index % 2
            let modelOnCard = models[firstIndex].clone(recursive: true)
            // +0.001 so the model hovers just a little bit over the card so the occlusionBox occludes it
            modelOnCard.position = [0,cardThickness/2+0.001,0]
            card.addChild(modelOnCard)
            // Give the card a name so we'll know what we're interacting with
            card.name = "card\(firstIndex)\(secondIndex)"
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
        if let card = arView.entity(at: tapLocation) {
            var cardTransform = card.transform
            if true {
                // Set the card to rotate back to 0 degrees
                cardTransform.rotation = simd_quatf(angle: 0, axis: [1, 0, 0])
            } else {
                cardTransform.rotation = simd_quatf(angle: .pi, axis: [1,0,0])

            }
            card.move(to: cardTransform, relativeTo: card.parent, duration: 0.3, timingFunction: .easeInOut)
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
