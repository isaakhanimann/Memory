//
//  PlacementHandler.swift
//  Memory
//
//  Created by Isaak Hanimann on 16.07.20.
//  Copyright © 2020 Isaak Hanimann. All rights reserved.
//

import UIKit
import RealityKit
import ARKit
import Combine


class PlacementHandler {
    
    let placementButton = UIButton()
    var coachingOverlay: ARCoachingOverlayView!
    var previewBoard: Entity!
    var realScene: Entity!
    var raycastAnchor: AnchorEntity?
    var updateCancellable: Cancellable?
    var objectPlaced = false
    var trackingStarted = false
    var arView: ARView!
    var completionHandler: ((Entity) -> Void)!
    let numberOfCards = 16

    
    func handlePlacing(on arView: ARView, completion: @escaping (Entity) -> Void) {
        self.arView = arView
        setupPlacementButton()
        self.completionHandler = completion
        setupCoachingOverlay()
        
        previewBoard = getPreviewEntity()
        realScene = getRealEntity()
    }
    
    func setupPlacementButton() {
        placementButton.backgroundColor = .white
        placementButton.setTitleColor(.black, for: .normal)
        placementButton.setTitle("Place Game Board", for: .normal)
        placementButton.layer.cornerRadius = 15
        
        placementButton.addTarget(self, action: #selector(placingButtonPressed), for: .touchUpInside)
        
        arView.addSubview(placementButton)
        //the constraints have to be set after the subview is added to the view
        setPlacementButtonConstraints()
    }
    
    func setPlacementButtonConstraints() {
        placementButton.translatesAutoresizingMaskIntoConstraints = false
        placementButton.bottomAnchor.constraint(equalTo: arView.bottomAnchor, constant: -80).isActive = true
        placementButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        placementButton.widthAnchor.constraint(equalToConstant: 180).isActive = true
        placementButton.centerXAnchor.constraint(equalTo: arView.centerXAnchor).isActive = true
    }
    
    @objc func placingButtonPressed() {
        if !trackingStarted {
            updateCancellable = arView.scene.subscribe(
                to: SceneEvents.Update.self, updateOverlay
            )
            trackingStarted = true
        }
        
        if objectPlaced && !coachingOverlay.isActive {
            if let result = smartRaycast() {
                addRealScene(onto: result)
                updateCancellable?.cancel()
                completionHandler(realScene)
                hideButton()
            } else {
                print("This raycast should not miss")
            }
        }
    }
    
    func setupCoachingOverlay(){
        coachingOverlay = ARCoachingOverlayView(frame: arView.frame)
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        // Add overlay to the view hierarchy
        arView.addSubview(coachingOverlay)
        // Set Auto Layout constraints
        coachingOverlay.topAnchor.constraint(equalTo: arView.topAnchor).isActive = true
        coachingOverlay.leadingAnchor.constraint(equalTo: arView.leadingAnchor).isActive = true
        coachingOverlay.trailingAnchor.constraint(equalTo: arView.trailingAnchor).isActive = true
        coachingOverlay.bottomAnchor.constraint(equalTo: arView.bottomAnchor).isActive = true
        // Specify a goal for the coaching overlay, in this case, the goal is to establish world tracking
        coachingOverlay.goal = .horizontalPlane
        // Tell the coaching overlay which ARSession it should be monitoring
        coachingOverlay.session = arView.session
        coachingOverlay.activatesAutomatically = false
    }
    
    func updateOverlay(event: SceneEvents.Update? = nil) {
        // Perform hit testing only when ARKit tracking is in a good state.
        guard let camera = arView.session.currentFrame?.camera,
            case .normal = camera.trackingState,
            let result = smartRaycast()
            else {
                coachingOverlay.setActive(true, animated: true)
                hideButton()
                return
        }
        makeFixedInPlaceButton()
        coachingOverlay.setActive(false, animated: true)
        if objectPlaced {
            movePreviewScene(to: result)
        } else {
            addPreviewScene(onto: result)
            objectPlaced = true
        }
    }
    
    
    func smartRaycast() -> ARRaycastResult? {
        let results = arView.raycast(from: arView.center, allowing: .estimatedPlane, alignment: .horizontal)
        
        // 1. Check for a result on an existing plane using geometry.
        if let result = results.first(where: { $0.target == .existingPlaneGeometry }) {
            return result
        }
        
        // 2. As a fallback, check for a result on estimated planes.
        return results.first(where: { $0.target == .estimatedPlane })
    }
    
    func addPreviewScene(onto raycastResult: ARRaycastResult) {
        raycastAnchor = AnchorEntity(world: raycastResult.worldTransform)
        raycastAnchor?.addChild(previewBoard)
        arView.scene.addAnchor(raycastAnchor!)
    }
    
    func movePreviewScene(to raycastResult: ARRaycastResult) {
        let transform = Transform(matrix: raycastResult.worldTransform)
        previewBoard.setPosition(transform.translation, relativeTo: nil)
        previewBoard.setOrientation(transform.rotation, relativeTo: nil)
    }
    
    func addRealScene(onto raycastResult: ARRaycastResult) {
        raycastAnchor?.removeFromParent()
        raycastAnchor = AnchorEntity(world: raycastResult.worldTransform)
        raycastAnchor?.addChild(realScene)
        arView.scene.addAnchor(raycastAnchor!)
    }
    
    func hideButton() {
        placementButton.isHidden = true
    }
    
    func makeFixedInPlaceButton() {
        placementButton.setTitle("Fix Board", for: .normal)
        placementButton.isHidden = false
    }
    
    var previewCards = [CardEntity]()

    func getPreviewEntity() -> Entity {
        
        let parentEntity = Entity()
        
        let cardTemplate = getCardTemplateWithOutCollisionShape()
        
        //create list of card entities
        for _ in 0..<numberOfCards {
            let card = cardTemplate.clone(recursive: true)
            previewCards.append(card)
        }
        
        //place cards relative to parent
        for (index, card) in previewCards.enumerated() {
            let x = Float(index % 4) - 1.5
            let z = Float(index / 4) - 1.5
            // Set the position of the card
            card.position = [x * 0.1, 0, z * 0.1]
            // Add the card to the anchor
            parentEntity.addChild(card)
        }
        
        return parentEntity
    }
    
    var realCards = [CardEntity]()

    func getRealEntity() -> Entity {
        
        let parentEntity = Entity()
        
        //load models
        let names = ["toy_robot_vintage", "fender_stratocaster", "tv_retro", "cup_saucer_set", "pot_plant", "flower_tulip", "trowel", "teapot"]
        var models = [ModelEntity]()
        for name in names {
            let newModel = try! Entity.loadModel(named: name)
            models.append(newModel)
        }
        
        let cardTemplate = getCardTemplateWithCollisionShape()
        
        //put models on top of cards
        for index in 0..<numberOfCards {
            let card = cardTemplate.clone(recursive: true)
            let modelIndex = index / 2
            let modelOnCard = models[modelIndex].clone(recursive: true)
            // +0.001 so the model hovers just a little bit over the card so the occlusionBox occludes it
            modelOnCard.position = [0,cardThickness/2+0.001,0]
            card.addChild(modelOnCard)
            card.components[CardComponent.self]?.kind = names[modelIndex]
            realCards.append(card)
        }
        
        realCards.shuffle()
        
        //place cards relative to game anchor
        for (index, card) in realCards.enumerated() {
            let x = Float(index % 4) - 1.5
            let z = Float(index / 4) - 1.5
            // Set the position of the card
            card.position = [x * 0.1, 0, z * 0.1]
            // Add the card to the anchor
            parentEntity.addChild(card)
        }
        
        
        //add occlusion box
        let boxSize: Float = 0.5
        let boxMesh = MeshResource.generateBox(size: boxSize)
        let boxMaterial = OcclusionMaterial()
        let occlusionBox = ModelEntity(mesh: boxMesh, materials: [boxMaterial])
        occlusionBox.position.y = -boxSize/2 - cardThickness/2
        parentEntity.addChild(occlusionBox)
        
        return parentEntity
    }
    
    func getCardTemplateWithCollisionShape() -> CardEntity {
        //create card entity
        let cardModelEntity = try! Entity.loadModel(named: "plate")
        let cardEntityTemplate = CardEntity()
        cardEntityTemplate.model = cardModelEntity.model
        cardEntityTemplate.collision = cardModelEntity.collision
        cardEntityTemplate.card = CardComponent()
        // Generate collision shapes for the card so we can interact with it
        cardEntityTemplate.generateCollisionShapes(recursive: true)
        cardEntityTemplate.transform.rotation = simd_quatf(angle: .pi, axis: [1,0,0])
        return cardEntityTemplate
    }
    
    func getCardTemplateWithOutCollisionShape() -> CardEntity {
        //create card entity
        let cardModelEntity = try! Entity.loadModel(named: "plate")
        let cardEntityTemplate = CardEntity()
        cardEntityTemplate.model = cardModelEntity.model
        cardEntityTemplate.collision = cardModelEntity.collision
        cardEntityTemplate.card = CardComponent()
        cardEntityTemplate.transform.rotation = simd_quatf(angle: .pi, axis: [1,0,0])
        return cardEntityTemplate
    }
}
