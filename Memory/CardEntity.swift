//
//  CardEntity.swift
//  Memory
//
//  Created by Isaak Hanimann on 16.07.20.
//  Copyright © 2020 Isaak Hanimann. All rights reserved.
//

import RealityKit

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
        move(to: cardTransform, relativeTo: parent, duration: Constants.animationDuration, timingFunction: .easeInOut)
    }
    
    func hide() {
        card.revealed = false
        
        // transform is a value type so this copies it
        var cardTransform = self.transform
        cardTransform.rotation = simd_quatf(angle: .pi, axis: [1, 0, 0])
        move(to: cardTransform, relativeTo: parent, duration: Constants.animationDuration, timingFunction: .easeInOut)
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
