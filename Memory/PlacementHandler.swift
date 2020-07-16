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
    var previewScene: Entity!
    var realScene: Entity!
    var raycastAnchor: AnchorEntity?
    var updateCancellable: Cancellable?
    var objectPlaced = false
    var trackingStarted = false
    var arView: ARView!
    var completionHandler: ((Entity) -> Void)!
    
    func handlePlacing(on arView: ARView, completion: @escaping (Entity) -> Void) {
        self.arView = arView
        setupPlacementButton()
        self.completionHandler = completion
        setupCoachingOverlay()
        
        
        loadPreviewBoard()
        loadRealBoard()
    }
    
    func loadPreviewBoard() {
        let mesh = MeshResource.generateBox(size: 0.2)
        let material = SimpleMaterial(color: .red, isMetallic: true)
        previewScene = ModelEntity(mesh: mesh, materials: [material])
    }
    
    func loadRealBoard() {
        let mesh = MeshResource.generateBox(size: 0.2)
        let material = SimpleMaterial(color: .blue, isMetallic: true)
        realScene = ModelEntity(mesh: mesh, materials: [material])
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
        raycastAnchor?.addChild(previewScene)
        arView.scene.addAnchor(raycastAnchor!)
    }
    
    func movePreviewScene(to raycastResult: ARRaycastResult) {
        let transform = Transform(matrix: raycastResult.worldTransform)
        previewScene.setPosition(transform.translation, relativeTo: nil)
        previewScene.setOrientation(transform.rotation, relativeTo: nil)
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
    
    
    //    func loadGameBoard() {
    //        print("loadGameBoard executed")
    //        gameAnchor = try! Experience.loadPreviewBoard()
    //        arView.scene.addAnchor(gameAnchor)
    //    }
        
    //    func addGameBoardOooooooooooooooold() {
    //        gameAnchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.2, 0.2])
    //        arView.scene.anchors.append(gameAnchor)
    //
    //        addCardsWithModels()
    //        addOcclusionBox()
    //    }
    //
    //
    //    func addCardsWithModels() {
    //
    //        let cardModelEntity = try! Entity.loadModel(named: "plate")
    //
    //        let cardEntityTemplate = CardEntity()
    //        cardEntityTemplate.model = cardModelEntity.model
    //        cardEntityTemplate.collision = cardModelEntity.collision
    //        cardEntityTemplate.card = CardComponent()
    //        // Generate collision shapes for the card so we can interact with it
    //        cardEntityTemplate.generateCollisionShapes(recursive: true)
    //        cardEntityTemplate.transform.rotation = simd_quatf(angle: .pi, axis: [1,0,0])
    //
    //        let names = ["toy_robot_vintage", "fender_stratocaster", "tv_retro", "cup_saucer_set", "pot_plant", "flower_tulip", "trowel", "teapot"]
    //
    //        var models = [ModelEntity]()
    //        for name in names {
    //            let newModel = try! Entity.loadModel(named: name)
    //            models.append(newModel)
    //        }
    //
    //        for index in 0..<self.numberOfCards {
    //            let card = cardEntityTemplate.clone(recursive: true)
    //            let modelIndex = index / 2
    //            let modelOnCard = models[modelIndex].clone(recursive: true)
    //            // +0.001 so the model hovers just a little bit over the card so the occlusionBox occludes it
    //            modelOnCard.position = [0,cardThickness/2+0.001,0]
    //            card.addChild(modelOnCard)
    //            card.components[CardComponent.self]?.kind = names[modelIndex]
    //            self.cards.append(card)
    //        }
    //
    //        self.cards.shuffle()
    //
    //        for (index, card) in self.cards.enumerated() {
    //            let x = Float(index % 4) - 1.5
    //            let z = Float(index / 4) - 1.5
    //            // Set the position of the card
    //            card.position = [x * 0.1, 0, z * 0.1]
    //            // Add the card to the anchor
    //            self.gameAnchor.addChild(card)
    //        }
    //    }
    //
    //
//
//    func addOcclusionBox() {
//        let boxSize: Float = 0.5
//        let boxMesh = MeshResource.generateBox(size: boxSize)
//        let boxMaterial = OcclusionMaterial()
//        let occlusionBox = ModelEntity(mesh: boxMesh, materials: [boxMaterial])
//        occlusionBox.position.y = -boxSize/2 - cardThickness/2
//        gameScene.addChild(occlusionBox)
//    }
}

extension Experience {
    
    private static var streams = [Combine.AnyCancellable]()
    
    public static func loadUnanchoredSceneAsync(with sceneName: String, completion: @escaping (Result<Entity, Error>) -> Void) {
        guard let realityFileURL = Bundle.main.url(forResource: "Experience", withExtension: "reality") else {
            completion(.failure(Experience.LoadRealityFileError.fileNotFound("Experience.reality")))
            return
        }
        
        var cancellable: Combine.AnyCancellable?
        let realitySceneURL = realityFileURL.appendingPathComponent(sceneName, isDirectory: false)
        let loadRequest = Entity.loadAsync(contentsOf: realitySceneURL)
        cancellable = loadRequest.sink(receiveCompletion: { loadCompletion in
            if case let .failure(error) = loadCompletion {
                print("this is the failure")
                completion(.failure(error))
            }
            streams.removeAll { $0 === cancellable }
        }, receiveValue: { entity in
            completion(.success(entity))
        })
        cancellable?.store(in: &streams)
    }
}

