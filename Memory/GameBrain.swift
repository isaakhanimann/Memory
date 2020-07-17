//
//  GameBrain.swift
//  Memory
//
//  Created by Isaak Hanimann on 17.07.20.
//  Copyright © 2020 Isaak Hanimann. All rights reserved.
//

import RealityKit
import UIKit


class GameBrain {
    
    var arView: ARView!
    var gameBoard: Entity!
    let timerLabel = UILabel()
    let restartButton = UIButton()
    var tapGestureRecognizer: UITapGestureRecognizer!
    var timer: Timer?
    var secondsUntilTimeout = 15
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
                    self.arView.removeGestureRecognizer(self.tapGestureRecognizer)
                }
            } else if newValue == .won {
                DispatchQueue.main.async {
                    self.timerLabel.text = "You won"
                    self.restartButton.isHidden = false
                    self.arView.removeGestureRecognizer(self.tapGestureRecognizer)
                }
            }
        }
    }
    
    func startPlaying(on arView: ARView, with gameBoard: Entity) {
        self.arView = arView
        self.gameBoard = gameBoard
        setupTimerLabel()
        setupRestartButtonButton()
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        arView.addGestureRecognizer(tapGestureRecognizer)
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
                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.flipDuration + 0.2, execute: self.checkSelection)
            }
            
            
        }
    }
    
    @objc func restartGame() {
        secondsUntilTimeout = 15
        selection1 = nil
        selection2 = nil
        arView.addGestureRecognizer(tapGestureRecognizer)

        
        var cards: [CardEntity] = gameBoard.children.map({entity in
            if let cardEntity = entity as? CardEntity {
                return cardEntity
            } else {
                return nil
            }
        }).compactMap { $0 }
                
        for card in cards {
            if card.card.revealed {
                card.isEnabled = true
                card.hide()
            }
        }
        
        //Todo - cards need to be shuffled / repositioned
        cards.shuffle()
        
        for (index, card) in cards.enumerated() {
            let x = Float(index % 4) - 1.5
            let z = Float(index / 4) - 1.5
            // Set the position of the card
            let transform = Transform(rotation: simd_quatf(angle: .pi, axis: [1, 0, 0]), translation: [x * 0.1, 0, z * 0.1])
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.flipDuration) {
                card.move(to: transform, relativeTo: self.gameBoard, duration: Constants.shuffleDuration)
            }
        }
        
        DispatchQueue.main.async {
            self.restartButton.isHidden = true
            self.timerLabel.text = String(self.secondsUntilTimeout) + "s"
            self.timerLabel.isHidden = true
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
