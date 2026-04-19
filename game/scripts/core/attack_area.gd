extends Area2D
class_name AttackArea

signal hit_target(target: Node, hit_data: Dictionary)

var owner_actor: Node = null
var damage: int = 10
var attack_name: StringName = &""
var knockback: Vector2 = Vector2.ZERO
var can_be_parried: bool = true
var is_grab: bool = false
var active: bool = false

var _hit_cache: Dictionary = {}

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	deactivate()


func arm(config: Dictionary) -> void:
	var requested_owner: Node = config.get("owner_actor", owner_actor)
	var requested_damage: int = int(config.get("damage", damage))
	var requested_attack_name: StringName = config.get("attack_name", attack_name)
	var requested_knockback: Vector2 = config.get("knockback", knockback)
	var requested_can_be_parried: bool = bool(config.get("can_be_parried", true))
	var requested_is_grab: bool = bool(config.get("is_grab", false))
	var same_request := active \
		and owner_actor == requested_owner \
		and damage == requested_damage \
		and attack_name == requested_attack_name \
		and knockback.is_equal_approx(requested_knockback) \
		and can_be_parried == requested_can_be_parried \
		and is_grab == requested_is_grab
	owner_actor = requested_owner
	damage = requested_damage
	attack_name = requested_attack_name
	knockback = requested_knockback
	can_be_parried = requested_can_be_parried
	is_grab = requested_is_grab
	if not same_request:
		_hit_cache.clear()
	active = true
	monitoring = true
	if collision_shape != null:
		collision_shape.disabled = false


func deactivate() -> void:
	active = false
	_hit_cache.clear()
	monitoring = false
	if collision_shape != null:
		collision_shape.disabled = true


func _on_area_entered(area: Area2D) -> void:
	if not active or not area.is_in_group("hurtbox"):
		return
	var target := area.get_parent()
	if target == null or target == owner_actor:
		return
	var target_id := target.get_instance_id()
	if _hit_cache.has(target_id):
		return
	_hit_cache[target_id] = true
	var payload := {
		"source_actor": owner_actor,
		"source_position": global_position,
		"damage": damage,
		"attack_name": attack_name,
		"knockback": knockback,
		"can_be_parried": can_be_parried,
		"is_grab": is_grab
	}
	if target.has_method("receive_hit"):
		target.receive_hit(payload)
	hit_target.emit(target, payload)
