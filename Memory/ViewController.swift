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


class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    
    var placementHandler = PlacementHandler()
    var gameBrain = GameBrain()
    var gameBoard: Entity!
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpARView()
        
        placementHandler.handlePlacing(on: arView) { [self] entity in
            self.gameBoard = entity
            self.gameBrain.startPlaying(on: self.arView, with: entity)
        }
    }
    
    func setUpARView() {
        arView.automaticallyConfigureSession = false
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.isCollaborationEnabled = true
        config.environmentTexturing = .automatic
        arView.session.run(config)
    }
    
}


