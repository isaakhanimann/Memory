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
    
    // for loading the models
    var cancellable: AnyCancellable? = nil

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let anchorEntity = AnchorEntity(plane: .horizontal, minimumBounds: [0.2, 0.2])
        
        arView.scene.anchors.append(anchorEntity)
        
        addEntities(to: anchorEntity)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        arView.addGestureRecognizer(tapGestureRecognizer)
        
    }
    
    
    func addEntities(to anchorEntity: AnchorEntity) {
        var cards = [Entity]()
        let numberOfCards = 16

        let cardTemplate = try! Entity.loadModel(named: "plate")
        // Generate collision shapes for the card so we can interact with it
        cardTemplate.generateCollisionShapes(recursive: true)

        cancellable = Entity.loadModelAsync(named: "toy_robot_vintage")
            .append(Entity.loadModelAsync(named: "fender_stratocaster"))
            .append(Entity.loadModelAsync(named: "tv_retro"))
            .append(Entity.loadModelAsync(named: "cup_saucer_set"))
            .append(Entity.loadModelAsync(named: "pot_plant"))
            .append(Entity.loadModelAsync(named: "flower_tulip"))
            .append(Entity.loadModelAsync(named: "trowel"))
            .append(Entity.loadModelAsync(named: "teapot"))
            .collect().sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Unable to load a model due to error \(error)")
                }
                self.cancellable?.cancel()
            }, receiveValue: { [self] (models: [Entity]) in
                self.cancellable?.cancel()


                for index in 0..<numberOfCards {
                    let card = cardTemplate.clone(recursive: true)
                    // card00 and card01 correspond to each other
                    let firstIndex = index / 2
                    let secondIndex = index % 2
                    let modelOnCard = models[firstIndex].clone(recursive: true)
                    card.addChild(modelOnCard)
                    // Give the card a name so we'll know what we're interacting with
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
            })
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
}
