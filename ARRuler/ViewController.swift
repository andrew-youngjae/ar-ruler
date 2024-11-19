//
//  ViewController.swift
//  ARRuler
//
//  Created by YoungJae Lee on 11/19/24.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    // AR로 display되는 물체 = Node
    // 측정 시작점과 끝점을 나타내는 dot Node
    var pointNodes = [SCNNode]()
    // 측정 값을 화면에 띄워주는 text Node
    var infoNode = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // User가 화면을 touch하는 event가 발생할때마다 호출되는 함수
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetPoint()
        
        guard let touch = touches.first else { return }
        
        // User가 touch한 2D screen 상에서의 좌표값 얻어오기
        let selectedLocation = touch.location(in: sceneView)
        
        // User가 touch한 2D screen 좌표로부터 z 방향으로 발사되는 ray를 통해 실제 세계의 3D 좌표값을 측정하는 query 로직
        guard let query = sceneView.raycastQuery(from: selectedLocation, allowing: .existingPlaneGeometry, alignment: .any) else { return }
        
        // ray query를 발사하여 측정
        let rayHitResults = sceneView.session.raycast(query)
        
        // ray query를 통해 3D 좌표값 얻어오기
        guard let targetCrd3D = rayHitResults.first else { return }
        
        addPoint(at: targetCrd3D)
    }
    
    func addPoint(at location: ARRaycastResult) {
        let pointGeometry = SCNSphere(radius: 0.02)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        
        pointGeometry.materials = [material]
        
        let pointNode = SCNNode()
        pointNode.geometry = pointGeometry
        pointNode.position = SCNVector3(location.worldTransform.columns.3.x, location.worldTransform.columns.3.y, location.worldTransform.columns.3.z)
        
        sceneView.scene.rootNode.addChildNode(pointNode)
        
        pointNodes.append(pointNode)
        
        if pointNodes.count >= 2 {
            calculate()
        }
    }
    
    func resetPoint() {
        if pointNodes.count >= 2 {
            pointNodes.forEach { $0.removeFromParentNode() }
            pointNodes = [SCNNode]()
        }
    }
    
    func calculate() {
        let startPoint = pointNodes[0]
        let endPoint = pointNodes[1]
        
        let distance = sqrtf(powf(endPoint.position.x - startPoint.position.x, 2) +
                             powf(endPoint.position.y - startPoint.position.y, 2) +
                             powf(endPoint.position.z - startPoint.position.z, 2))
        
        // cm 단위로 변경
        let distanceInCM = String(format: "%.2f", distance * 100)
        
        updateInfo(info: distanceInCM + "cm", pointPosition: startPoint.position)
    }
    
    func updateInfo(info: String, pointPosition position: SCNVector3) {
        // 정보가 업데이트 될때마다 기존의 정보 지우기
        infoNode.removeFromParentNode()
        
        // 입체감 있는 텍스트 생성
        let infoGeometry = SCNText(string: info, extrusionDepth: 1.0)
        
        infoGeometry.firstMaterial?.diffuse.contents = UIColor.red
        
        infoNode = SCNNode(geometry: infoGeometry)
        
        infoNode.position = SCNVector3(position.x + 0.05, position.y + 0.1, position.z - 0.25)
        
        // 기본 단위가 미터 단위이기 때문에 scaling을 통해 줄여줘야 함
        infoNode.scale = SCNVector3(0.005, 0.005, 0.005)
        
        sceneView.scene.rootNode.addChildNode(infoNode)
    }
}
