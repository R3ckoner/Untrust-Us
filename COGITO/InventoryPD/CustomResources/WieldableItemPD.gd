extends InventoryItemPD
class_name WieldableItemPD

signal charge_changed()

@export_group("Wieldable settings")
@export var wieldable_scene : PackedScene
@export var wieldable_data_icon : Texture2D
@export var no_reload : bool = false

@export var charge_max : float
@export var ammo_item_name : String
@export var charge_current : float
@export var wieldable_range : float
@export var wieldable_damage : float

@export var is_hoe: bool = false  # New flag to determine if the item is a hoe

var wieldable_data_text : String

func use(target) -> bool:
	if target == null or target.is_in_group("external_inventory"):
		print("Bad target pass. Setting target to", CogitoSceneManager._current_player_node)
		target = CogitoSceneManager._current_player_node

	player_interaction_component = target.player_interaction_component
	if player_interaction_component.carried_object != null:
		player_interaction_component.send_hint(null, "Can't equip item while carrying.")
		return false

	if is_being_wielded:
		print("Inventory item: ", player_interaction_component, " is putting away wieldable ", name)
		put_away()
		
		# If the item is a hoe, disable tilling mode when putting it away
		if is_hoe:
			player_interaction_component.enable_tilling_mode(false)
		
		return true
	else:
		print("Inventory item: ", player_interaction_component, " is taking out wieldable ", name)
		take_out()
		
		# If the item is a hoe, enable tilling mode
		if is_hoe:
			player_interaction_component.enable_tilling_mode(true)

		return true

func take_out():
	if player_interaction_component.is_changing_wieldables:
		return

	print("Taking out ", name)
	is_being_wielded = true
	update_wieldable_data(player_interaction_component)
	player_interaction_component.change_wieldable_to(self)

func put_away():
	if player_interaction_component.is_changing_wieldables:
		return

	print("Putting away ", name)
	is_being_wielded = false
	update_wieldable_data(player_interaction_component)
	player_interaction_component.change_wieldable_to(null)

func update_wieldable_data(_player_interaction_component : PlayerInteractionComponent):
	if _player_interaction_component:
		if is_being_wielded:
			if !no_reload:
				_player_interaction_component.updated_wieldable_data.emit(self, get_item_amount_in_inventory(ammo_item_name), get_ammo_item(ammo_item_name))
			else:
				_player_interaction_component.updated_wieldable_data.emit(self, 0, null)
		else:
			_player_interaction_component.updated_wieldable_data.emit(null, 0, null)

func subtract(amount):
	charge_current -= amount
	if charge_current < 0:
		charge_current = 0
		player_interaction_component.send_hint(null, name + " is out of battery.")

	if is_being_wielded:
		update_wieldable_data(player_interaction_component)

	charge_changed.emit()

func add(amount):
	charge_current += amount
	if charge_current > charge_max:
		charge_current = charge_max

	if is_being_wielded:
		update_wieldable_data(player_interaction_component)
	charge_changed.emit()

func get_ammo_item(item_name_to_check_for: String) -> InventoryItemPD:
	var ammo_item : InventoryItemPD
	if player_interaction_component.get_parent().inventory_data != null:
		var inventory_to_check = player_interaction_component.get_parent().inventory_data
		for slot in inventory_to_check.inventory_slots:
			if slot != null and slot.inventory_item.name == item_name_to_check_for:
				ammo_item = slot.inventory_item

	return ammo_item

func get_item_amount_in_inventory(item_name_to_check_for: String) -> int:
	var item_count : int = 0
	if player_interaction_component.get_parent().inventory_data != null:
		var inventory_to_check = player_interaction_component.get_parent().inventory_data
		for slot in inventory_to_check.inventory_slots:
			if slot != null and slot.inventory_item.name == item_name_to_check_for:
				item_count += slot.quantity

	return item_count

func save():
	var saved_item_data = {
		"resource" : self,
		"charge_current" : charge_current
	}
	return saved_item_data

func build_wieldable_scene():
	var scene = wieldable_scene.instantiate()
	scene.item_reference = self
	return scene
