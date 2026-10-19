extends "res://scripts/yard.gd"

const HaulerModel = preload("res://scripts/hauler_model.gd")
const DIRT := Vector3(-7,0,-3)
const TRUCK := Vector3(0,0,-1)
const DUMP := Vector3(7,0,-3.2)
var source_pile: Node3D
var delivered_pile: Node3D

func _delivery_bay() -> void:
	# A replenishing dirt bank, a truck loading pad, and a separate tipping bay.
	Geo.cylinder(self,DIRT+Vector3(0,.04,0),2.05,.08,Geo.material(Color("bc946b")),-1,48)
	source_pile = HaulerModel.dirt_clumps(self,DIRT+Vector3(0,.1,0),Vector3(1.65,1.05,1.3),40)
	for p in [TRUCK,DUMP]:
		_block(p+Vector3(0,.025,0),Vector3(4.2,.06,6.2),concrete)
		var ring := Geo.ring(self,2.15,Color("f8e9b2"),40)
		ring.position = p+Vector3(0,.08,0)
	Geo.label(self,"LOAD",TRUCK+Vector3(0,.1,3),32,Color("35506a")).rotation.x = -PI/2
	Geo.label(self,"DUMP",DUMP+Vector3(0,.1,3),32,Color("35506a")).rotation.x = -PI/2
	goal_star = Geo.star(self,DUMP+Vector3(0,2.35,.6),.7,Geo.material(Color("ffdc63")))
	delivered_pile = HaulerModel.dirt_clumps(self,DUMP+Vector3(0,.09,1),Vector3(1.5,.9,1.3),36)
	delivered_pile.visible = false
	_cone(Vector3(10.4,0,-6.3))
	_cone(Vector3(4.3,0,-6.3))
	for i in 5:
		_block(Vector3(2.8+i*.7,.05,3),Vector3(.35,.04,.16),pale)

func show_deliveries(count: int) -> void:
	delivered_pile.visible = count>0
	delivered_pile.scale = Vector3.ONE*(.8+minf(count,3)*.15)
