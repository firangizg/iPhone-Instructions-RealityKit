//
//  ContentView.swift
//  3Dmodels
//
//  Created by Firangiz on 8/12/20.
//

import SwiftUI
import RealityKit
import ARKit
import Combine


struct ContentView : View {
    @State private var isPlacementEnabled = false
    @State private var selectedModel: Model?
    @State private var modelConfirmedForPlacement: Model?
    
    private var models: [Model] = {
        //Dynamically get the file names
        let filemanager = FileManager.default
        
        guard let path = Bundle.main.resourcePath, let files = try? filemanager.contentsOfDirectory(atPath: path) else {
            return []
        }
        
        var availableModels: [Model] = []
        for filename in files where filename.hasSuffix("rcproject") {
            let modelName = filename.replacingOccurrences(of: ".rcproject", with:"" )
            let model = Model(modelName: modelName)
            
            availableModels.append(model)
        }
        return availableModels
        }()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(modelConfirmedForPlacement:
                self.$modelConfirmedForPlacement)
            
            if self.isPlacementEnabled {
                PlacementButtonsView(isPlacementEnabled: self.$isPlacementEnabled, selectedModel: self.$selectedModel, modelConfirmedForPlacement: self.$modelConfirmedForPlacement)
            }
            else {
                ModelPickerView(isPlacementEnabled: self.$isPlacementEnabled, selectedModel: self.$selectedModel, models: self.models)
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var modelConfirmedForPlacement: Model?
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame:.zero) //ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
                      config.planeDetection = [.horizontal, .vertical]
                      config.environmentTexturing = .automatic
                      
                      
                     if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
                           config.sceneReconstruction = .mesh
                      }
            let boxAnchor = try! MobilePhone.loadScene()
            // Add the box anchor to the scene
            arView.scene.anchors.append(boxAnchor)

                      
                    arView.session.run(config)
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        if let model = self.modelConfirmedForPlacement {
            
            if let modelEntity = model.modelEntity {
                print("DEBUG: adding model to scene - \(model.modelName)")
                
                let anchorEntity = AnchorEntity(plane: .any)
                anchorEntity.addChild(modelEntity.clone(recursive: true))
                uiView.scene.addAnchor(anchorEntity)

            } else {
                print("DEBUG: Unable to load model entity for \(model.modelName)")
            }
            
            DispatchQueue.main.async {
                self.modelConfirmedForPlacement = nil
            }
        }
    }
}



struct ModelPickerView: View {
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: Model?
    
    var models: [Model]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 30) {
                ForEach(0 ..< self.models.count) {
                    index in
                    Button(action: {
                        print("DEBUG: selected model with name: \(self.models[index].modelName)")
                            
                        self.selectedModel = self.models[index]
                        
                            self.isPlacementEnabled = true
                        
                             }) {
                                Image(uiImage: self.models[index].image)
                                    .resizable()
                                    .frame(height: 80)
                                    .aspectRatio(1/1, contentMode: .fit)
                                    .background(Color.white)
                                    .cornerRadius(12)
                             }
                                 .buttonStyle(PlainButtonStyle())
                         }
                     }
                 }
        .padding(20)
        .background(Color.black.opacity(0.5))
    }
}

struct PlacementButtonsView : View {
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: Model?
    @Binding var modelConfirmedForPlacement: Model?
    
    var body: some View {
        HStack {
            // Cancel the button
            Button(action: {print("DEBUG: Model placement canceled.")
                self.resetPlacementParameters()
            }) {
                Image(systemName: "xmark")
                    .frame(width: 60, height:  60)
                    .font(.title)
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(30)
                    .padding(20)
            }
            // Confirm button
            Button(action: {print("DEBUG: Model placement confirmed.")
                
                self.modelConfirmedForPlacement = self.selectedModel
                self.resetPlacementParameters()
                
            }) {
                Image(systemName: "checkmark")
                    .frame(width: 60, height:  60)
                    .font(.title)
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(30)
                    .padding(20)
            }
        }
    }
    
    func resetPlacementParameters() {
        self.isPlacementEnabled = false
        self.selectedModel = nil
    }
    
}

#if DEBUG

struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#endif

