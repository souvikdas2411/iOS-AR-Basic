//
//  ViewController.swift
//  iOS-AR
//
//  Created by Souvik Das on 10/01/21.
//
///Reference : https://www.youtube.com/watch?v=mV7SWeMDEfg

import UIKit
import RealityKit
import Combine

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let anchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.2,0.2])
        arView.scene.addAnchor(anchor)
        
        var cards = [Entity]()
        for _ in 1...6 {
            
            //Can also add corner radius and stuff to the meshresource
            let mesh = MeshResource.generateBox(width: 0.04, height: 0.01, depth: 0.04)
            let material = SimpleMaterial(color: .red, isMetallic: true)
            let model = ModelEntity(mesh: mesh, materials: [material])
            //Creates the shape used to detect collisions between two entities that have collision components.
            model.generateCollisionShapes(recursive: true)
            cards.append(model)
            
        }
        
        for (index, card) in cards.enumerated() {
            //The modulo part is explained v well in the reference
            let x = Float(index%2)
            let z = Float(index/2)
            
            card.position = [x*0.1, 0, z*0.1]
            //Refer to the reference picture for the addChild thing
            anchor.addChild(card)
        }
        
        let boxSize: Float = 0.7
        let occlusionBoxMesh = MeshResource.generateBox (size: boxSize)
        let occlusionBox = ModelEntity(mesh: occlusionBoxMesh, materials: [OcclusionMaterial()])
        
        occlusionBox.position.y = -boxSize/2
        anchor.addChild(occlusionBox)
        
        var cancellable: AnyCancellable? = nil
        cancellable = ModelEntity.loadModelAsync(named: "toy_car")
            .append(ModelEntity.loadModelAsync(named: "toy_biplane"))
            .append(ModelEntity.loadModelAsync(named: "toy_robot_vintage"))
            .collect()
            .sink(receiveCompletion: {error in
                print("Error 1 \(error)")
                cancellable?.cancel()
            }, receiveValue: { entities in
                var objects: [ModelEntity] = []
                for entity in entities {
                    entity.setScale(SIMD3<Float>(0.002, 0.002, 0.002),
                                    relativeTo: anchor)
                    entity.generateCollisionShapes (recursive: true)
                    for _ in 1...2 {
                        objects.append(entity.clone (recursive: true))
                    }
                }
                objects.shuffle()
                for (index, object) in objects.enumerated() {
                    cards[index].addChild(object)
                    cards[index].transform.rotation = simd_quatf(angle: .pi, axis: [1,0,0])
                }
                cancellable?.cancel()
            })

    }
    @IBAction func didTap(_ sender: UITapGestureRecognizer) {
        //Checking is user tapped on ar element
        let tapLocation = sender.location(in: arView)
        if let card = arView.entity(at: tapLocation) {
            //Checking if the card is already tapped from before
            //If yes then turn the card upside down
            if card.transform.rotation.angle == .pi {
                var flipDownTransform = card.transform
                //Resetting to angle 0
                flipDownTransform.rotation = simd_quatf(angle: 0, axis: [1, 0, 0])
                card.move(to: flipDownTransform, relativeTo: card.parent, duration: 0.25, timingFunction: .easeInOut)
            }
            else{
                var flipUpTransform = card.transform
                //Turning up
                flipUpTransform.rotation = simd_quatf(angle: .pi, axis: [1, 0, 0])
                card.move(to: flipUpTransform, relativeTo: card.parent, duration: 0.25, timingFunction: .easeInOut)
            }
            
        }
        
        
    }
}
