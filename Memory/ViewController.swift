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
    let timerLabel = UILabel()
    let restartButton = UIButton()

    var timer: Timer?
    var secondsUntilTimeout = 15
    
    var placementHandler = PlacementHandler()
    var gameBoard: Entity!
    
    var selection1: CardEntity?
    var selection2: CardEntity?
    
    enum GameState {
        case notStarted
        case started
        case won
        case lost
    }
    
    var gameState = GameState.notStarted {
        didSet {
            if oldValue == .notStarted || oldValue == .won || oldValue == .lost {
                //start timer and update label
                timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateLabel), userInfo: nil, repeats: true)
                timerLabel.isHidden = false
            }
        }
        willSet {
            if newValue == .lost {
                DispatchQueue.main.async {
                    self.timerLabel.text = "You lost"
                    self.restartButton.isHidden = false
                }
            } else if newValue == .won {
                DispatchQueue.main.async {
                    self.timerLabel.text = "You won"
                    self.restartButton.isHidden = false
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpARView()
        setupTimerLabel()
        setupRestartButtonButton()
        
        placementHandler.handlePlacing(on: arView) { [self] entity in
            self.gameBoard = entity
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
    
    func setupTimerLabel() {
        timerLabel.backgroundColor = UIColor(white: 0.8, alpha: 0.5)
        timerLabel.text = "15s"
        timerLabel.textColor = .white
        timerLabel.layer.cornerRadius = 15
        timerLabel.layer.masksToBounds = true
        timerLabel.textAlignment = .center
        timerLabel.isHidden = true
        
        arView.addSubview(timerLabel)
        //the constraints have to be set after the subview is added to the view
        setTimerLabelConstraints()
    }
    
    func setTimerLabelConstraints() {
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.topAnchor.constraint(equalTo: arView.topAnchor, constant: 50).isActive = true
        timerLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        timerLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        timerLabel.centerXAnchor.constraint(equalTo: arView.centerXAnchor).isActive = true
    }
    
    func setupRestartButtonButton() {
        restartButton.backgroundColor = .white
        restartButton.setTitleColor(.black, for: .normal)
        restartButton.setTitle("Restart", for: .normal)
        restartButton.layer.cornerRadius = 15
        restartButton.isHidden = true
        
        restartButton.addTarget(self, action: #selector(restartGame), for: .touchUpInside)
        
        arView.addSubview(restartButton)
        //the constraints have to be set after the subview is added to the view
        setRestartButtonConstraints()
    }
    
    func setRestartButtonConstraints() {
        restartButton.translatesAutoresizingMaskIntoConstraints = false
        restartButton.bottomAnchor.constraint(equalTo: arView.bottomAnchor, constant: -80).isActive = true
        restartButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        restartButton.widthAnchor.constraint(equalToConstant: 180).isActive = true
        restartButton.centerXAnchor.constraint(equalTo: arView.centerXAnchor).isActive = true
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        
        let tapLocation = recognizer.location(in: arView)
        
        // Get the entity at the location we've tapped, if one exists
        if let cardEntity = arView.entity(at: tapLocation) as? CardEntity {
            
            if cardEntity.card.revealed {
                if self.selection1 == cardEntity {
                    // even though SelectionEntity is a reference type the item in the array won't be set to nil because the items in the array can't be nil because they are non optional
                    self.selection1 = nil
                } else if self.selection2 == cardEntity {
                    self.selection2 = nil
                }
                cardEntity.hide()
            } else {
                gameState = .started
                
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
                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.animationDuration + 0.2, execute: self.checkSelection)
            }
            
            
        }
    }
    
    @objc func restartGame() {
        secondsUntilTimeout = 15
        for child in gameBoard.children {
            if let cardEntity = child as? CardEntity {
                if !cardEntity.isEnabled {
                    cardEntity.isEnabled = true
                }
            }
        }
        DispatchQueue.main.async {
            self.restartButton.isHidden = true
        }
    }
    
    func checkSelection() {
        if selection1?.card.kind == self.selection2?.card.kind {
            selection1?.isEnabled = false
            selection1 = nil
            selection2?.isEnabled = false
            selection2 = nil
            let numberOfEnabledCards = gameBoard.children.filter({entity in
                if let cardEntity = entity as? CardEntity {
                    if cardEntity.isEnabled {
                        return true
                    }
                }
                return false
            }).count
            
            if numberOfEnabledCards == 0 {
                gameState = .won
            }
        }
    }
    
    @objc func updateLabel() {
        if secondsUntilTimeout > 0 {
            secondsUntilTimeout -= 1
            DispatchQueue.main.async {
                self.timerLabel.text = String(self.secondsUntilTimeout) + "s"
            }
        } else {
            timer?.invalidate()
            gameState = .lost
        }
    }
    
}


